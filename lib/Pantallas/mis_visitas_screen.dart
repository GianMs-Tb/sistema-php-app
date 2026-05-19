import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../Models/visita_model.dart';
import '../Services/firebase_visita_repository.dart';
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

    return Scaffold(
      backgroundColor: AppColors.navy,
      appBar: AppBar(title: const Text('Mis visitas')),
      body: uid == null
          ? const Center(
              child: Text(
                'Inicia sesión para gestionar visitas.',
                textAlign: TextAlign.center,
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
                      ),
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final lista = snapshot.data ?? const <Visita>[];
                if (lista.isEmpty) {
                  return _vacio();
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: lista.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final v = lista[i];
                    return _TarjetaVisita(
                      visita: v,
                      onTap: () => _abrirDetalle(context, v),
                    );
                  },
                );
              },
            ),
      floatingActionButton: uid == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _mostrarNuevaVisita(uid),
              backgroundColor: const Color(0xFF2563EB),
              icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
              label: const Text(
                'Nueva visita',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
    );
  }

  Widget _vacio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.groups_outlined,
                size: 64, color: Colors.grey.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            const Text(
              'No tienes visitas registradas',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Crea una visita para generar un código QR que el portero puede validar al ingreso.',
              style: TextStyle(
                color: Colors.grey.withValues(alpha: 0.85),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _mostrarNuevaVisita(String uid) async {
    final nombreCtrl = TextEditingController();
    DateTime fechaHora =
        DateTime.now().add(const Duration(hours: 1));

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
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Fecha y hora esperada',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(_formatoFechaHoraVisita(fechaHora)),
                    trailing: const Icon(Icons.calendar_month),
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
                        initialTime:
                            TimeOfDay(hour: fechaHora.hour, minute: fechaHora.minute),
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
      await _repo.crear(
        residenteUid: uid,
        residenteNombre: widget.residenteNombre,
        nombreVisitante: nombre,
        fechaHoraEsperada: fechaHora,
        apartamento: widget.apartamento,
        torre: widget.torre,
      );
      _snack('Visita registrada');
    } catch (e) {
      _snack('No se pudo guardar: $e', error: true);
    }
  }

  void _abrirDetalle(BuildContext context, Visita visita) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VisitaDetalleScreen(visita: visita),
      ),
    );
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.redAccent : null,
      ),
    );
  }
}

class _TarjetaVisita extends StatelessWidget {
  const _TarjetaVisita({required this.visita, required this.onTap});

  final Visita visita;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pendiente = visita.esPendiente;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      visita.nombreVisitante,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  _ChipEstado(pendiente: pendiente),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.schedule,
                      size: 16,
                      color: Colors.grey.withValues(alpha: 0.85)),
                  const SizedBox(width: 6),
                  Text(
                    _formatoFechaHoraVisita(
                      visita.fechaHoraEsperada ?? DateTime.now(),
                    ),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
              if (!pendiente && visita.fechaIngreso != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.login,
                        size: 16,
                        color: Colors.green.withValues(alpha: 0.85)),
                    const SizedBox(width: 6),
                    Text(
                      'Ingresó: ${_formatoFechaHoraVisita(visita.fechaIngreso!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ChipEstado extends StatelessWidget {
  const _ChipEstado({required this.pendiente});

  final bool pendiente;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: pendiente
            ? const Color(0xFFFFEDD5)
            : const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              pendiente ? const Color(0xFFFDBA74) : const Color(0xFF86EFAC),
        ),
      ),
      child: Text(
        pendiente ? VisitaEstado.pendiente : VisitaEstado.ingreso,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color:
              pendiente ? const Color(0xFFB45309) : const Color(0xFF166534),
        ),
      ),
    );
  }
}

/// Detalle: para visitas pendientes muestra el QR con el id del documento.
class VisitaDetalleScreen extends StatelessWidget {
  const VisitaDetalleScreen({super.key, required this.visita});

  final Visita visita;

  @override
  Widget build(BuildContext context) {
    final pendiente = visita.esPendiente;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Detalle de visita'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              visita.nombreVisitante,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Esperado: ${_formatoFechaHoraVisita(visita.fechaHoraEsperada ?? DateTime.now())}',
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 8),
            Text(
              'Destino: ${visita.unidadDestino}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 24),
            if (pendiente) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Código para portería',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'ID: ${visita.id}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    QrImageView(
                      data: visita.id,
                      version: QrVersions.auto,
                      size: 220,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Color(0xFF0F172A),
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.check_circle, color: Color(0xFF166534)),
                        SizedBox(width: 8),
                        Text(
                          'Visita completada',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF166534),
                          ),
                        ),
                      ],
                    ),
                    if (visita.fechaIngreso != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Ingresó: ${_formatoFechaHoraVisita(visita.fechaIngreso!)}',
                        style: const TextStyle(color: Color(0xFF166534)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
