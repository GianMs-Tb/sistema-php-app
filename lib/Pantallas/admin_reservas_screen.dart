import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Models/reserva_model.dart';
import '../Services/firebase_reserva_repository.dart';
import '../Widgets/glass_card.dart';
import '../Widgets/reserva_estado_chip.dart';
import '../theme/app_theme.dart';

/// Panel del administrador: aprueba o rechaza reservas de zonas comunes.
class AdminReservasScreen extends StatefulWidget {
  const AdminReservasScreen({super.key});

  @override
  State<AdminReservasScreen> createState() => _AdminReservasScreenState();
}

class _AdminReservasScreenState extends State<AdminReservasScreen> {
  final _repo = FirebaseReservaRepository();
  String _filtro = _filtroTodas;
  static const _filtroTodas = 'Todas';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      appBar: AppBar(title: const Text('Gestión de Reservas')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: _filtroTodas, label: Text('Todas')),
                ButtonSegment(
                  value: ReservaEstado.pendiente,
                  label: Text('Pendientes'),
                ),
                ButtonSegment(
                  value: ReservaEstado.aprobada,
                  label: Text('Aprobadas'),
                ),
              ],
              selected: {_filtro},
              onSelectionChanged: (s) => setState(() => _filtro = s.first),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Reserva>>(
              stream: _repo.streamTodas(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: AppColors.danger),
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var lista = snapshot.data ?? const <Reserva>[];
                lista = lista.reversed.toList();

                if (_filtro != _filtroTodas) {
                  lista = lista.where((r) => r.estado == _filtro).toList();
                }

                if (lista.isEmpty) {
                  return Center(
                    child: Text(
                      'No hay reservas en este filtro.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }

                return ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: lista.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _TarjetaAdminReserva(
                    reserva: lista[i],
                    onAprobar: () => _cambiarEstado(lista[i], ReservaEstado.aprobada),
                    onRechazar: () => _cambiarEstado(lista[i], ReservaEstado.rechazada),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cambiarEstado(Reserva r, String nuevoEstado) async {
    try {
      await _repo.actualizarEstado(r.id, nuevoEstado);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nuevoEstado == ReservaEstado.aprobada
                ? 'Reserva aprobada'
                : 'Reserva rechazada',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }
}

class _TarjetaAdminReserva extends StatelessWidget {
  const _TarjetaAdminReserva({
    required this.reserva,
    required this.onAprobar,
    required this.onRechazar,
  });

  final Reserva reserva;
  final VoidCallback onAprobar;
  final VoidCallback onRechazar;

  @override
  Widget build(BuildContext context) {
    final fechaTxt = _formatearFecha(reserva.fecha);
    final horaTxt = reserva.hora.isNotEmpty ? reserva.hora : '—';
    final pendiente = reserva.esPendiente;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  reserva.zona,
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              ReservaEstadoChip(estado: reserva.estado),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            reserva.residenteNombre.isNotEmpty
                ? reserva.residenteNombre
                : 'Residente',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '${reserva.apartamento} · ${reserva.torre}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: AppColors.mint),
              const SizedBox(width: 6),
              Text(
                fechaTxt,
                style: GoogleFonts.inter(
                  color: AppColors.mint,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.schedule, size: 16, color: AppColors.mint),
              const SizedBox(width: 6),
              Text(
                horaTxt,
                style: GoogleFonts.inter(
                  color: AppColors.mint,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (pendiente) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onAprobar,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Aprobar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRechazar,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                    ),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Rechazar'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatearFecha(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}
