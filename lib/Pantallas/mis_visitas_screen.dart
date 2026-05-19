import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Models/visita_model.dart';
import '../Services/firebase_visita_repository.dart';
import '../Widgets/glass_card.dart';
import '../Widgets/visita_qr_sheet.dart';
import '../theme/app_theme.dart';

String _formatoFechaHoraVisita(DateTime d) {
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  final hh = d.hour.toString().padLeft(2, '0');
  final mi = d.minute.toString().padLeft(2, '0');
  return '$dd/$mm/${d.year} $hh:$mi';
}

/// Lista de visitas del residente y creación de nuevas solicitudes.
class MisVisitasScreen extends StatefulWidget {
  const MisVisitasScreen({
    super.key,
    required this.residenteNombre,
    required this.apartamento,
    required this.torre,
  });

  final String residenteNombre;
  final String apartamento;
  final String torre;

  @override
  State<MisVisitasScreen> createState() => _MisVisitasScreenState();
}

class _MisVisitasScreenState extends State<MisVisitasScreen> {
  final _repo = FirebaseVisitaRepository();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.navy,
      appBar: AppBar(title: const Text('Mis visitas')),
      body: uid == null
          ? Center(
              child: Text(
                'Inicia sesión para gestionar visitas.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            )
          : StreamBuilder<List<Visita>>(
              stream: _repo.streamVisitasDeResidente(uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Error: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.danger),
                      ),
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final lista = snapshot.data ?? const <Visita>[];
                if (lista.isEmpty) {
                  return _vacio(theme);
                }
                return ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: lista.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final v = lista[i];
                    return _TarjetaVisita(
                      visita: v,
                      onVerQr: () => mostrarQrVisita(context, visitaId: v.id),
                    );
                  },
                );
              },
            ),
      floatingActionButton: uid == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _mostrarNuevaVisita(uid),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Nueva visita'),
            ),
    );
  }

  Widget _vacio(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.groups_outlined,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'No tienes visitas registradas',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Crea una visita y comparte el código QR con tu visitante para el ingreso en portería.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _mostrarNuevaVisita(String uid) async {
    final nombreCtrl = TextEditingController();
    DateTime fechaHora = DateTime.now().add(const Duration(hours: 1));

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          return AlertDialog(
            title: const Text('Nueva visita'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nombreCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del visitante',
                    ),
                    textCapitalization: TextCapitalization.words,
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Fecha y hora esperada',
                      style: Theme.of(ctx).textTheme.titleSmall,
                    ),
                    subtitle: Text(_formatoFechaHoraVisita(fechaHora)),
                    trailing: const Icon(Icons.calendar_month, color: AppColors.mint),
                    onTap: () async {
                      final ahora = DateTime.now();
                      final inicioDia =
                          DateTime(ahora.year, ahora.month, ahora.day);
                      final init = fechaHora.isBefore(inicioDia)
                          ? inicioDia
                          : fechaHora;
                      final d = await showDatePicker(
                        context: ctx,
                        initialDate: init,
                        firstDate: inicioDia,
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (d == null || !ctx.mounted) return;
                      final t = await showTimePicker(
                        context: ctx,
                        initialTime: TimeOfDay(
                          hour: fechaHora.hour,
                          minute: fechaHora.minute,
                        ),
                      );
                      if (t == null || !ctx.mounted) return;
                      setLocal(() {
                        fechaHora = DateTime(
                          d.year,
                          d.month,
                          d.day,
                          t.hour,
                          t.minute,
                        );
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );

    if (ok != true || !mounted) {
      nombreCtrl.dispose();
      return;
    }

    final nombre = nombreCtrl.text.trim();
    nombreCtrl.dispose();
    if (nombre.isEmpty) {
      _snack('Indica el nombre del visitante.', error: true);
      return;
    }

    try {
      final visitaId = await _repo.crear(
        residenteUid: uid,
        residenteNombre: widget.residenteNombre,
        nombreVisitante: nombre,
        fechaHoraEsperada: fechaHora,
        apartamento: widget.apartamento,
        torre: widget.torre,
      );
      _snack('Visita registrada');
      if (mounted) {
        mostrarQrVisita(context, visitaId: visitaId);
      }
    } catch (e) {
      _snack('No se pudo guardar: $e', error: true);
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppColors.danger : null,
      ),
    );
  }
}

class _TarjetaVisita extends StatelessWidget {
  const _TarjetaVisita({
    required this.visita,
    required this.onVerQr,
  });

  final Visita visita;
  final VoidCallback onVerQr;

  @override
  Widget build(BuildContext context) {
    final pendiente = visita.esPendiente;
    final theme = Theme.of(context);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  visita.nombreVisitante,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              _ChipEstadoVisita(pendiente: pendiente),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.schedule, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                _formatoFechaHoraVisita(
                  visita.fechaHoraEsperada ?? DateTime.now(),
                ),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          if (!pendiente && visita.fechaIngreso != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.login, size: 16, color: AppColors.mintDim),
                const SizedBox(width: 6),
                Text(
                  'Ingresó: ${_formatoFechaHoraVisita(visita.fechaIngreso!)}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.mintDim,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          if (pendiente) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onVerQr,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.mint,
                  side: const BorderSide(color: AppColors.mint),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                icon: const Icon(Icons.qr_code_2),
                label: Text(
                  'Ver Código de Acceso',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChipEstadoVisita extends StatelessWidget {
  const _ChipEstadoVisita({required this.pendiente});

  final bool pendiente;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: pendiente
            ? const Color(0x33FBBF24)
            : AppColors.mint.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: pendiente ? const Color(0xFFFBBF24) : AppColors.mint,
        ),
      ),
      child: Text(
        pendiente ? VisitaEstado.pendiente : VisitaEstado.ingreso,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: pendiente ? const Color(0xFFFBBF24) : AppColors.mint,
        ),
      ),
    );
  }
}
