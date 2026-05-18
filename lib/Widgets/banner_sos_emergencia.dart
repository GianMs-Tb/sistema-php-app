import 'package:flutter/material.dart';

import '../Models/alerta_sos_model.dart';

/// Banner rojo fijo para alertas SOS activas (portero / administración).
class BannerSosEmergencia extends StatelessWidget {
  const BannerSosEmergencia({
    super.key,
    required this.alertas,
    required this.onMarcarAtendida,
  });

  final List<AlertaSos> alertas;
  final Future<void> Function(String id) onMarcarAtendida;

  @override
  Widget build(BuildContext context) {
    if (alertas.isEmpty) return const SizedBox.shrink();

    return Material(
      color: const Color(0xFFB91C1C),
      elevation: 6,
      shadowColor: Colors.black54,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.sos, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      '¡EMERGENCIA!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...alertas.map((a) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Apto ${a.apartamento}, Torre ${a.torre}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (a.nombreResidente.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            a.nombreResidente,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFFB91C1C),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => onMarcarAtendida(a.id),
                          child: const Text(
                            'Marcar como atendida',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
