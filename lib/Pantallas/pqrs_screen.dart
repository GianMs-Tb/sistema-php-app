import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../Models/pqrs_model.dart';
import '../Services/firebase_pqrs_repository.dart';
import '../Widgets/glass_card.dart';
import '../theme/app_theme.dart';

/// Buzón de PQRS del residente.
class PqrsScreen extends StatefulWidget {
  const PqrsScreen({super.key});

  @override
  State<PqrsScreen> createState() => _PqrsScreenState();
}

class _PqrsScreenState extends State<PqrsScreen> {
  final _repo = FirebasePqrsRepository();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    return Scaffold(
      backgroundColor: AppColors.navy,
      appBar: AppBar(title: const Text('Mis solicitudes')),
      body: uid == null
          ? const _Vacio(
              icono: Icons.lock_outline,
              titulo: 'Sesión no detectada',
              subtitulo: 'Inicia sesión para enviar y consultar tus PQRS.',
            )
          : StreamBuilder<List<Pqrs>>(
              stream: _repo.streamDeResidente(uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const _Vacio(
                    icono: Icons.error_outline,
                    titulo: 'Error al cargar',
                    subtitulo:
                        'No pudimos obtener tus solicitudes. Intenta de nuevo.',
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final lista = snapshot.data ?? const <Pqrs>[];

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    if (lista.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _Vacio(
                          icono: Icons.inbox_outlined,
                          titulo: 'Aún no tienes solicitudes',
                          subtitulo:
                              'Pulsa "Nueva solicitud" para enviar una petición, queja, reclamo o sugerencia.',
                          onNuevaSolicitud: () => _abrirNuevaSolicitud(uid),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
                        sliver: SliverList.separated(
                          itemCount: lista.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) =>
                              _TarjetaPqrs(pqrs: lista[i]),
                        ),
                      ),
                  ],
                );
              },
            ),
      floatingActionButton: uid == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: 100),
              child: FloatingActionButton.extended(
                onPressed: () => _abrirNuevaSolicitud(uid),
                icon: const Icon(Icons.add),
                label: const Text('Nueva solicitud'),
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Future<void> _abrirNuevaSolicitud(String uid) async {
    final tipoCtrl = ValueNotifier<String>(PqrsTipo.peticion);
    final descCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva solicitud'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tipo de solicitud',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              ValueListenableBuilder<String>(
                valueListenable: tipoCtrl,
                builder: (_, tipo, __) {
                  return DropdownButtonFormField<String>(
                    value: tipo,
                    isExpanded: true,
                    items: PqrsTipo.todos
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(t),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) tipoCtrl.value = v;
                    },
                  );
                },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: descCtrl,
                minLines: 4,
                maxLines: 8,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  alignLabelWithHint: true,
                ),
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
            child: const Text('Enviar'),
          ),
        ],
      ),
    );

    if (ok == true) {
      final descripcion = descCtrl.text.trim();
      if (descripcion.isEmpty) {
        _mostrarSnack('La descripción es obligatoria.', esError: true);
      } else {
        final user = FirebaseAuth.instance.currentUser;
        try {
          await _repo.crear(
            Pqrs(
              id: '',
              residenteUid: uid,
              residenteNombre:
                  (user?.displayName?.trim().isNotEmpty == true)
                      ? user!.displayName!
                      : (user?.email ?? ''),
              residenteEmail: user?.email ?? '',
              tipo: tipoCtrl.value,
              descripcion: descripcion,
              estado: PqrsEstado.pendiente,
            ),
          );
          _mostrarSnack('Solicitud enviada');
        } catch (e) {
          _mostrarSnack('Error al enviar: $e', esError: true);
        }
      }
    }

    descCtrl.dispose();
    tipoCtrl.dispose();
  }

  void _mostrarSnack(String texto, {bool esError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: esError ? AppColors.danger : null,
      ),
    );
  }
}

class _TarjetaPqrs extends StatelessWidget {
  const _TarjetaPqrs({required this.pqrs});

  final Pqrs pqrs;

  @override
  Widget build(BuildContext context) {
    final estilo = _estiloEstado(pqrs.estado);
    final fechaTxt = _formatoFecha(pqrs.createdAt);
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.mint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.mint.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  pqrs.tipo,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mint,
                  ),
                ),
              ),
              const Spacer(),
              _ChipEstado(estilo: estilo, label: pqrs.estado),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            pqrs.descripcion,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.schedule, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                fechaTxt,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChipEstado extends StatelessWidget {
  const _ChipEstado({required this.estilo, required this.label});

  final _EstadoEstilo estilo;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: estilo.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: estilo.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(estilo.icono, size: 13, color: estilo.foreground),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: estilo.foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _Vacio extends StatelessWidget {
  const _Vacio({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    this.onNuevaSolicitud,
  });

  final IconData icono;
  final String titulo;
  final String subtitulo;
  final VoidCallback? onNuevaSolicitud;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 60, color: AppColors.textSecondary),
            const SizedBox(height: 14),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              subtitulo,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (onNuevaSolicitud != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onNuevaSolicitud,
                icon: const Icon(Icons.add),
                label: const Text('Nueva solicitud'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EstadoEstilo {
  const _EstadoEstilo({
    required this.background,
    required this.foreground,
    required this.border,
    required this.icono,
  });

  final Color background;
  final Color foreground;
  final Color border;
  final IconData icono;
}

_EstadoEstilo _estiloEstado(String estado) {
  if (estado == PqrsEstado.resuelto) {
    return _EstadoEstilo(
      background: AppColors.mint.withValues(alpha: 0.15),
      foreground: AppColors.mint,
      border: AppColors.mint.withValues(alpha: 0.4),
      icono: Icons.check_circle,
    );
  }
  return const _EstadoEstilo(
    background: Color(0x33F59E0B),
    foreground: Color(0xFFFBBF24),
    border: Color(0x66F59E0B),
    icono: Icons.hourglass_bottom,
  );
}

String _formatoFecha(DateTime? fecha) {
  if (fecha == null) return '—';
  final dd = fecha.day.toString().padLeft(2, '0');
  final mm = fecha.month.toString().padLeft(2, '0');
  final hh = fecha.hour.toString().padLeft(2, '0');
  final min = fecha.minute.toString().padLeft(2, '0');
  return '$dd/$mm/${fecha.year} $hh:$min';
}
