import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../Models/reserva_model.dart';
import '../Services/firebase_reserva_repository.dart';
import 'reservas_screen.dart';

/// Pantalla intermedia con un grid de categorías y la lista de reservas
/// futuras del residente.
class CategoriasReservaScreen extends StatelessWidget {
  const CategoriasReservaScreen({
    super.key,
    this.nombre = 'Residente',
    this.apartamento = '',
    this.torre = '',
  });

  final String nombre;
  final String apartamento;
  final String torre;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reservar',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            const Text(
              'Selecciona una zona',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Toca una tarjeta para abrir el calendario.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 16),
            _construirGridCategorias(context),
            const SizedBox(height: 28),
            const Text(
              'Mis Reservas Programadas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            _construirListaFuturas(context),
          ],
        ),
      ),
    );
  }

  Widget _construirGridCategorias(BuildContext context) {
    final categorias = <_CategoriaZona>[
      const _CategoriaZona(
        zona: ZonasComunes.piscina,
        subtitulo: 'Sol y aguas tranquilas',
        icono: Icons.pool,
        gradiente: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
      ),
      const _CategoriaZona(
        zona: ZonasComunes.salonSocial,
        subtitulo: 'Eventos y celebraciones',
        icono: Icons.celebration,
        gradiente: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
      ),
      const _CategoriaZona(
        zona: ZonasComunes.cancha,
        subtitulo: 'Deportes y actividades',
        icono: Icons.sports_soccer,
        gradiente: [Color(0xFF10B981), Color(0xFF22C55E)],
      ),
      const _CategoriaZona(
        zona: ZonasComunes.cine,
        subtitulo: 'Sala con proyector',
        icono: Icons.movie,
        gradiente: [Color(0xFF1E3A8A), Color(0xFF6366F1)],
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.05,
      children: categorias
          .map((c) => _TarjetaCategoria(
                categoria: c,
                onTap: () => _abrirCalendario(context, c.zona),
              ))
          .toList(),
    );
  }

  Widget _construirListaFuturas(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _vacio('Inicia sesión para ver tus reservas.');
    }

    final repo = FirebaseReservaRepository();
    return StreamBuilder<List<Reserva>>(
      stream: repo.streamReservasFuturasDeResidente(user.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _vacio('Error al cargar tus reservas:\n${snapshot.error}');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final lista = snapshot.data ?? const <Reserva>[];
        if (lista.isEmpty) {
          return _vacio('Aún no tienes reservas próximas.');
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: lista.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final r = lista[index];
            return _TarjetaReservaProgramada(reserva: r);
          },
        );
      },
    );
  }

  Widget _vacio(String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_busy, color: Colors.grey),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  void _abrirCalendario(BuildContext context, String zona) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReservasScreen(
          nombre: nombre,
          apartamento: apartamento,
          torre: torre,
          zonaInicial: zona,
        ),
      ),
    );
  }
}

class _CategoriaZona {
  const _CategoriaZona({
    required this.zona,
    required this.subtitulo,
    required this.icono,
    required this.gradiente,
  });

  final String zona;
  final String subtitulo;
  final IconData icono;
  final List<Color> gradiente;
}

class _TarjetaCategoria extends StatelessWidget {
  const _TarjetaCategoria({required this.categoria, required this.onTap});

  final _CategoriaZona categoria;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: categoria.gradiente,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: categoria.gradiente.last.withValues(alpha: 0.25),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(categoria.icono, color: Colors.white, size: 26),
              ),
              const Spacer(),
              Text(
                categoria.zona,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                categoria.subtitulo,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TarjetaReservaProgramada extends StatelessWidget {
  const _TarjetaReservaProgramada({required this.reserva});

  final Reserva reserva;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE0E7FF),
          child: Icon(_iconoZona(reserva.zona), color: const Color(0xFF1E3A8A)),
        ),
        title: Text(
          reserva.zona,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(_formatearFecha(reserva.fecha)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }

  IconData _iconoZona(String zona) {
    switch (zona) {
      case ZonasComunes.piscina:
        return Icons.pool;
      case ZonasComunes.salonSocial:
        return Icons.celebration;
      case ZonasComunes.cancha:
        return Icons.sports_soccer;
      case ZonasComunes.cine:
        return Icons.movie;
      case ZonasComunes.bbq:
        return Icons.outdoor_grill;
      default:
        return Icons.event;
    }
  }

  String _formatearFecha(DateTime d) {
    const meses = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre'
    ];
    return '${d.day} de ${meses[d.month - 1]} ${d.year}';
  }
}
