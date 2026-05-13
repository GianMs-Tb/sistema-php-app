import 'package:flutter/material.dart';

import '../Models/pqrs_model.dart';
import '../Services/firebase_pqrs_repository.dart';

/// Vista del administrador para gestionar todas las PQRS del edificio.
class AdminPqrsScreen extends StatefulWidget {
  const AdminPqrsScreen({super.key});

  @override
  State<AdminPqrsScreen> createState() => _AdminPqrsScreenState();
}

class _AdminPqrsScreenState extends State<AdminPqrsScreen> {
  final _repo = FirebasePqrsRepository();
  _Filtro _filtro = _Filtro.todas;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Gestión PQRS',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<List<Pqrs>>(
        stream: _repo.streamTodas(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _Vacio(
              icono: Icons.error_outline,
              titulo: 'Error al cargar',
              subtitulo: 'Detalle: ${snapshot.error}',
            );
          }
          final cargando = snapshot.connectionState == ConnectionState.waiting;
          final todas = snapshot.data ?? const <Pqrs>[];
          final pendientes = todas.where((p) => p.esPendiente).length;
          final resueltas = todas.where((p) => p.esResuelto).length;
          final filtradas = _aplicarFiltro(todas);

          return Column(
            children: [
              _construirEstadisticas(
                total: todas.length,
                pendientes: pendientes,
                resueltas: resueltas,
              ),
              _construirFiltro(
                pendientes: pendientes,
                resueltas: resueltas,
                total: todas.length,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: cargando
                    ? const Center(child: CircularProgressIndicator())
                    : filtradas.isEmpty
                        ? const _Vacio(
                            icono: Icons.inbox_outlined,
                            titulo: 'Sin solicitudes',
                            subtitulo:
                                'No hay solicitudes que coincidan con el filtro actual.',
                          )
                        : ListView.separated(
                            padding:
                                const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemBuilder: (_, i) => _TarjetaAdminPqrs(
                              pqrs: filtradas[i],
                              onAbrir: () => _abrirDetalle(filtradas[i]),
                            ),
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemCount: filtradas.length,
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Pqrs> _aplicarFiltro(List<Pqrs> todas) {
    switch (_filtro) {
      case _Filtro.pendientes:
        return todas.where((p) => p.esPendiente).toList();
      case _Filtro.resueltas:
        return todas.where((p) => p.esResuelto).toList();
      case _Filtro.todas:
        return todas;
    }
  }

  Widget _construirEstadisticas({
    required int total,
    required int pendientes,
    required int resueltas,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              icono: Icons.inbox,
              color: const Color(0xFF2563EB),
              titulo: 'Total',
              valor: '$total',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              icono: Icons.hourglass_bottom,
              color: const Color(0xFFB45309),
              titulo: 'Pendientes',
              valor: '$pendientes',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              icono: Icons.check_circle,
              color: const Color(0xFF166534),
              titulo: 'Resueltas',
              valor: '$resueltas',
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirFiltro({
    required int pendientes,
    required int resueltas,
    required int total,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SegmentedButton<_Filtro>(
        segments: [
          ButtonSegment(
            value: _Filtro.todas,
            label: Text('Todas ($total)'),
            icon: const Icon(Icons.list_alt),
          ),
          ButtonSegment(
            value: _Filtro.pendientes,
            label: Text('Pendientes ($pendientes)'),
            icon: const Icon(Icons.hourglass_bottom),
          ),
          ButtonSegment(
            value: _Filtro.resueltas,
            label: Text('Resueltas ($resueltas)'),
            icon: const Icon(Icons.check_circle_outline),
          ),
        ],
        selected: {_filtro},
        onSelectionChanged: (s) => setState(() => _filtro = s.first),
      ),
    );
  }

  Future<void> _abrirDetalle(Pqrs pqrs) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final estilo = _estiloEstado(pqrs.estado);
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            20 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
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
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                  ),
                  const Spacer(),
                  _ChipEstado(estilo: estilo, label: pqrs.estado),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Descripción',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                pqrs.descripcion,
                style: const TextStyle(
                  color: Color(0xFF334155),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Residente',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                pqrs.residenteNombre.isEmpty
                    ? (pqrs.residenteEmail.isEmpty
                        ? pqrs.residenteUid
                        : pqrs.residenteEmail)
                    : pqrs.residenteNombre,
                style: const TextStyle(color: Color(0xFF334155)),
              ),
              if (pqrs.residenteEmail.isNotEmpty &&
                  pqrs.residenteEmail != pqrs.residenteNombre)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    pqrs.residenteEmail,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12.5,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(
                    Icons.schedule,
                    size: 14,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Creada: ${_formatearFecha(pqrs.createdAt)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (pqrs.esPendiente)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      await _marcarResuelta(pqrs);
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Marcar como Resuelta'),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      await _reabrir(pqrs);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reabrir solicitud'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _marcarResuelta(Pqrs pqrs) async {
    try {
      await _repo.marcarResuelta(pqrs.id);
      _mostrarSnack('Solicitud marcada como resuelta');
    } catch (e) {
      _mostrarSnack('Error al actualizar: $e', esError: true);
    }
  }

  Future<void> _reabrir(Pqrs pqrs) async {
    try {
      await _repo.reabrir(pqrs.id);
      _mostrarSnack('Solicitud reabierta');
    } catch (e) {
      _mostrarSnack('Error al actualizar: $e', esError: true);
    }
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

enum _Filtro { todas, pendientes, resueltas }

class _TarjetaAdminPqrs extends StatelessWidget {
  const _TarjetaAdminPqrs({required this.pqrs, required this.onAbrir});

  final Pqrs pqrs;
  final VoidCallback onAbrir;

  @override
  Widget build(BuildContext context) {
    final estilo = _estiloEstado(pqrs.estado);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onAbrir,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
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
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
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
                    Icons.person_outline,
                    size: 14,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      pqrs.residenteNombre.isNotEmpty
                          ? pqrs.residenteNombre
                          : (pqrs.residenteEmail.isNotEmpty
                              ? pqrs.residenteEmail
                              : pqrs.residenteUid),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.schedule,
                    size: 14,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatearFecha(pqrs.createdAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icono,
    required this.color,
    required this.titulo,
    required this.valor,
  });

  final IconData icono;
  final Color color;
  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icono, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 11.5,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
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
  });

  final IconData icono;
  final String titulo;
  final String subtitulo;

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
