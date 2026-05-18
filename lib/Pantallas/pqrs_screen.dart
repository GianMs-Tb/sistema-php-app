import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../Models/pqrs_model.dart';
import '../Services/firebase_pqrs_repository.dart';

/// Buzón de PQRS del residente. Lista sus solicitudes y permite crear
/// nuevas (`tipo` + `descripcion`) que se guardan en Firestore con
/// estado `Pendiente`.
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
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Mis solicitudes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: uid == null
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
                  if (lista.isEmpty) {
                    return _Vacio(
                      icono: Icons.inbox_outlined,
                      titulo: 'Aún no tienes solicitudes',
                      subtitulo:
                          'Pulsa "Nueva solicitud" para enviar una petición, queja, reclamo o sugerencia.',
                      onNuevaSolicitud: () => _abrirNuevaSolicitud(uid),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                    itemBuilder: (_, i) => _TarjetaPqrs(pqrs: lista[i]),
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemCount: lista.length,
                  );
                },
              ),
      ),
      floatingActionButton: uid == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _abrirNuevaSolicitud(uid),
              backgroundColor: const Color(0xFF2563EB),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Nueva solicitud',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
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
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),
              ValueListenableBuilder<String>(
                valueListenable: tipoCtrl,
                builder: (_, tipo, __) {
                  return DropdownButtonFormField<String>(
                    value: tipo,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
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
                  border: OutlineInputBorder(),
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
        backgroundColor: esError ? Colors.redAccent : null,
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
    final fechaTxt = _formatearFecha(pqrs.createdAt);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
                  color: const Color(0xFFE0E7FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  pqrs.tipo,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E3A8A),
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
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.schedule,
                size: 14,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 4),
              Text(
                fechaTxt,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
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
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 60, color: const Color(0xFF94A3B8)),
            const SizedBox(height: 14),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitulo,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B), height: 1.4),
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
    return const _EstadoEstilo(
      background: Color(0xFFDCFCE7),
      foreground: Color(0xFF166534),
      border: Color(0xFF86EFAC),
      icono: Icons.check_circle,
    );
  }
  return const _EstadoEstilo(
    background: Color(0xFFFFEDD5),
    foreground: Color(0xFFB45309),
    border: Color(0xFFFDBA74),
    icono: Icons.hourglass_bottom,
  );
}

String _formatearFecha(DateTime? fecha) {
  if (fecha == null) return '—';
  final dd = fecha.day.toString().padLeft(2, '0');
  final mm = fecha.month.toString().padLeft(2, '0');
  final hh = fecha.hour.toString().padLeft(2, '0');
  final min = fecha.minute.toString().padLeft(2, '0');
  return '$dd/$mm/${fecha.year} $hh:$min';
}
