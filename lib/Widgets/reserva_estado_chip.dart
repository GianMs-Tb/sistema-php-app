import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Models/reserva_model.dart';

/// Chip visual del estado de una reserva.
class ReservaEstadoChip extends StatelessWidget {
  const ReservaEstadoChip({super.key, required this.estado});

  final String estado;

  @override
  Widget build(BuildContext context) {
    final estilo = _estilo(estado);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: estilo.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: estilo.border),
      ),
      child: Text(
        estado,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: estilo.foreground,
        ),
      ),
    );
  }

  _ChipEstilo _estilo(String estado) {
    switch (estado) {
      case ReservaEstado.aprobada:
        return const _ChipEstilo(
          background: Color(0x3310B981),
          foreground: Color(0xFF34D399),
          border: Color(0xFF34D399),
        );
      case ReservaEstado.rechazada:
        return const _ChipEstilo(
          background: Color(0x33EF4444),
          foreground: Color(0xFFF87171),
          border: Color(0xFFF87171),
        );
      case ReservaEstado.pendiente:
      default:
        return const _ChipEstilo(
          background: Color(0x33FBBF24),
          foreground: Color(0xFFFBBF24),
          border: Color(0xFFFBBF24),
        );
    }
  }
}

class _ChipEstilo {
  const _ChipEstilo({
    required this.background,
    required this.foreground,
    required this.border,
  });

  final Color background;
  final Color foreground;
  final Color border;
}
