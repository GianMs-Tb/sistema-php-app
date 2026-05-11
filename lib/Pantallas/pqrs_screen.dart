import 'package:flutter/material.dart';

/// Buzón de PQRS (peticiones, quejas, reclamos y sugerencias).
///
/// Pantalla placeholder lista para conectarse a Firestore en una iteración
/// posterior; por ahora lista categorías y muestra un CTA de "nueva solicitud".
class PqrsScreen extends StatelessWidget {
  const PqrsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Buzón PQRS',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            _construirEncabezado(),
            const SizedBox(height: 20),
            _construirCategoria(
              icono: Icons.help_outline,
              color: const Color(0xFF3B82F6),
              titulo: 'Petición',
              descripcion: 'Solicita información o servicios.',
            ),
            const SizedBox(height: 12),
            _construirCategoria(
              icono: Icons.report_outlined,
              color: const Color(0xFFEF4444),
              titulo: 'Queja',
              descripcion: 'Reporta una situación inconforme.',
            ),
            const SizedBox(height: 12),
            _construirCategoria(
              icono: Icons.warning_amber_outlined,
              color: const Color(0xFFF59E0B),
              titulo: 'Reclamo',
              descripcion: 'Solicita revisión de un cobro o trámite.',
            ),
            const SizedBox(height: 12),
            _construirCategoria(
              icono: Icons.lightbulb_outline,
              color: const Color(0xFF10B981),
              titulo: 'Sugerencia',
              descripcion: 'Comparte una idea para mejorar el conjunto.',
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Próximamente: formulario de nueva solicitud.'),
                  ),
                );
              },
              icon: const Icon(Icons.add_comment),
              label: const Text('Nueva solicitud'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirEncabezado() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.support_agent, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿En qué podemos ayudarte?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Selecciona una categoría para abrir un caso.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirCategoria({
    required IconData icono,
    required Color color,
    required String titulo,
    required String descripcion,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icono, color: color),
        ),
        title: Text(
          titulo,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        subtitle: Text(descripcion),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {},
      ),
    );
  }
}
