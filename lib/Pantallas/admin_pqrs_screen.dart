import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Models/pqrs_model.dart';
import '../Services/firebase_pqrs_repository.dart';
import '../Widgets/glass_card.dart';
import '../theme/app_theme.dart';

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
      backgroundColor: AppColors.navy,
      appBar: AppBar(title: const Text('Gestión PQRS')),
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
                            physics: const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics(),
                            ),
                            padding: const EdgeInsets.fromLTRB(
                              16,
                              8,
                              16,
                              140,
                            ),
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
              color: AppColors.mint,
              titulo: 'Total',
              valor: '$total',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              icono: Icons.hourglass_bottom,
              color: const Color(0xFFFBBF24),
              titulo: 'Pendientes',
              valor: '$pendientes',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              icono: Icons.check_circle,
              color: AppColors.mintDim,
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
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final estilo = _estiloEstado(pqrs.estado);
        final theme = Theme.of(ctx);
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.slate.withValues(alpha: 0.94),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: const Border(
                  top: BorderSide(color: AppColors.glassBorder),
                  left: BorderSide(color: AppColors.glassBorder),
                  right: BorderSide(color: AppColors.glassBorder),
                ),
              ),
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
                        color: AppColors.textSecondary.withValues(alpha: 0.5),
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
                          color: AppColors.mint.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.mint.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          pqrs.tipo,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.mint,
                          ),
                        ),
                      ),
                      const Spacer(),
                      _ChipEstado(estilo: estilo, label: pqrs.estado),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Descripción', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 6),
                  Text(
                    pqrs.descripcion,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  Text('Residente', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 6),
                  Text(
                    pqrs.residenteNombre.isEmpty
                        ? (pqrs.residenteEmail.isEmpty
                            ? pqrs.residenteUid
                            : pqrs.residenteEmail)
                        : pqrs.residenteNombre,
                    style: theme.textTheme.bodyLarge,
                  ),
                  if (pqrs.residenteEmail.isNotEmpty &&
                      pqrs.residenteEmail != pqrs.residenteNombre)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        pqrs.residenteEmail,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Creada: ${_formatearFecha(pqrs.createdAt)}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (pqrs.esPendiente)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
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
            ),
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
    return GlassCard(
      onTap: onAbrir,
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
                        color: AppColors.mint.withValues(alpha: 0.3),
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
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      height: 1.4,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 14,
                    color: AppColors.textSecondary,
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
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.schedule,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatearFecha(pqrs.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
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
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icono, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(valor, style: Theme.of(context).textTheme.titleLarge),
          Text(titulo, style: Theme.of(context).textTheme.bodySmall),
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4),
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
    return _EstadoEstilo(
      background: AppColors.mint.withValues(alpha: 0.15),
      foreground: AppColors.mint,
      border: AppColors.mint.withValues(alpha: 0.4),
      icono: Icons.check_circle,
    );
  }
  return _EstadoEstilo(
    background: const Color(0xFFFBBF24).withValues(alpha: 0.15),
    foreground: const Color(0xFFFBBF24),
    border: const Color(0xFFFBBF24).withValues(alpha: 0.4),
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
