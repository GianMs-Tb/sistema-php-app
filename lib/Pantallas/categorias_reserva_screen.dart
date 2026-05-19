import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Models/reserva_model.dart';
import '../Services/firebase_reserva_repository.dart';
import '../Widgets/glass_card.dart';
import '../Widgets/reserva_glass_card.dart';
import '../theme/app_theme.dart';
import 'reservas_screen.dart';

/// Grid de zonas y lista de reservas futuras con estilo Premium Dark Glass.
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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.navy,
      appBar: AppBar(title: const Text('Reservar')),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Text('Selecciona una zona', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Toca una tarjeta para abrir el calendario.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _construirGridCategorias(context),
            const SizedBox(height: 28),
            Text(
              'Mis Reservas Programadas',
              style: theme.textTheme.titleLarge,
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
      ),
      const _CategoriaZona(
        zona: ZonasComunes.salonSocial,
        subtitulo: 'Eventos y celebraciones',
        icono: Icons.celebration,
      ),
      const _CategoriaZona(
        zona: ZonasComunes.cancha,
        subtitulo: 'Deportes y actividades',
        icono: Icons.sports_soccer,
      ),
      const _CategoriaZona(
        zona: ZonasComunes.cine,
        subtitulo: 'Sala con proyector',
        icono: Icons.movie,
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
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            return ReservaGlassCard(
              reserva: lista[index],
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            );
          },
        );
      },
    );
  }

  Widget _vacio(String texto) {
    return GlassCard(
      child: Row(
        children: [
          const Icon(Icons.event_busy, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: GoogleFonts.inter(color: AppColors.textSecondary),
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
  });

  final String zona;
  final String subtitulo;
  final IconData icono;
}

class _TarjetaCategoria extends StatelessWidget {
  const _TarjetaCategoria({required this.categoria, required this.onTap});

  final _CategoriaZona categoria;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      fillColor: AppColors.slate.withValues(alpha: 0.55),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.mint.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.mint.withValues(alpha: 0.35)),
            ),
            child: Icon(categoria.icono, color: AppColors.mint, size: 26),
          ),
          const Spacer(),
          Text(
            categoria.zona,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            categoria.subtitulo,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
