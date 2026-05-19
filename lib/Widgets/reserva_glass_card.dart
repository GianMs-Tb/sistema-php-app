import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Models/reserva_model.dart';
import '../theme/app_theme.dart';

/// Tarjeta de reserva con estilo Premium Dark Glass.
class ReservaGlassCard extends StatelessWidget {
  const ReservaGlassCard({
    super.key,
    required this.reserva,
    this.onDelete,
    this.trailing,
  });

  final Reserva reserva;
  final VoidCallback? onDelete;
  final Widget? trailing;

  static const _slateGlass = Color(0xFF112240);

  @override
  Widget build(BuildContext context) {
    final fechaTxt = _formatearFecha(reserva.fecha);
    final horaTxt = reserva.hora.isNotEmpty ? reserva.hora : '—';

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          decoration: BoxDecoration(
            color: _slateGlass.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.glassBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.mint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.mint.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(
                  _iconoZona(reserva.zona),
                  color: AppColors.mint,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reserva.zona,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 16,
                          color: AppColors.mint,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            fechaTxt,
                            style: GoogleFonts.inter(
                              color: AppColors.mint,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 16,
                          color: AppColors.mint,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          horaTxt,
                          style: GoogleFonts.inter(
                            color: AppColors.mint,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                  onPressed: onDelete,
                )
              else if (trailing != null)
                trailing!,
            ],
          ),
        ),
      ),
    );
  }

  static IconData _iconoZona(String zona) {
    switch (zona) {
      case ZonasComunes.piscina:
        return Icons.pool;
      case ZonasComunes.bbq:
        return Icons.outdoor_grill;
      case ZonasComunes.salonSocial:
        return Icons.celebration;
      case ZonasComunes.cancha:
        return Icons.sports_soccer;
      case ZonasComunes.cine:
        return Icons.movie;
      default:
        return Icons.event;
    }
  }

  static String _formatearFecha(DateTime d) {
    const meses = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return '${d.day} ${meses[d.month - 1]} ${d.year}';
  }
}
