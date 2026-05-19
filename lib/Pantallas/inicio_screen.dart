import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../Models/app_user.dart';
import '../Models/paquete_model.dart';
import '../Models/residente.dart';
import '../Services/firebase_paquete_repository.dart';
import '../Widgets/glass_card.dart';
import '../theme/app_theme.dart';
import 'admin_reservas_screen.dart';
import 'admin_residentes_screen.dart';
import 'categorias_reserva_screen.dart';
import 'comunicados_screen.dart';
import 'generar_qr_screen.dart';
import 'mis_visitas_screen.dart';

class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key, this.isAdmin = false});

  /// Hint inicial proveniente del shell. La pantalla además relee `users/{uid}`
  /// para mostrar el botón de admin con datos frescos de Firestore.
  final bool isAdmin;

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  // Dato temporal: reemplazar por Provider/Bloc cuando conectemos Firebase.
  static final Residente _residente = Residente(
    nombre: 'Santiago',
    apartamento: 'Apto 502',
    torre: 'Torre 1',
    saldoPendiente: 150000,
    fechaVencimiento: DateTime(2026, 4, 15),
    notificacionesSinLeer: 2,
  );

  final _paquetesRepo = FirebasePaqueteRepository();

  /// Future cacheado para evitar parpadeo en cada rebuild.
  late final Future<bool> _esAdminFuture = _cargarRolAdmin();

  Future<bool> _cargarRolAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!snap.exists) return false;
      final appUser = AppUser.fromMap(user.uid, snap.data() ?? {});
      return appUser.isAdmin;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _esAdminFuture,
      initialData: widget.isAdmin,
      builder: (context, adminSnap) {
        final esAdmin = adminSnap.data ?? false;
        return Scaffold(
          backgroundColor: AppColors.navy,
          appBar: esAdmin
              ? AppBar(
                  title: const Text('Inicio'),
                  actions: [
                    IconButton(
                      tooltip: 'Panel de administración',
                      onPressed: () => _abrirAdmin(context),
                      icon: const Icon(Icons.settings),
                    ),
                  ],
                )
              : null,
          body: SingleChildScrollView(
            child: Column(
              children: [
                _construirHeader(context, mostrarBotonAdminEnHeader: !esAdmin),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                Center(
                  child: Text(
                    'Gestión Digital',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.mint,
                          letterSpacing: 0.5,
                        ),
                  ),
                ),

                // 2. Espacio perfecto entre el título y los botones
                const SizedBox(height: 10),

                if (!esAdmin) _construirSeccionPaquetesPendientes(),

                if (!esAdmin) const SizedBox(height: 10),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final gap = 15.0;
                    final w = (constraints.maxWidth - gap) / 2;
                    return Row(
                      children: [
                        SizedBox(
                          width: w,
                          child: _construirBotonGrid(
                            context,
                            Icons.sports_tennis,
                            'Reservas',
                            'Zonas comunes',
                            const Color(0xFF3B82F6),
                            () => _abrirReservas(context),
                          ),
                        ),
                        SizedBox(width: gap),
                        SizedBox(
                          width: w,
                          child: _construirBotonGrid(
                            context,
                            Icons.group_add_outlined,
                            'Mis visitas',
                            'Invitados y QR',
                            const Color(0xFF0EA5E9),
                            () => _abrirMisVisitas(context),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 15),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 1.3,
                  children: [
                    _construirBotonGrid(
                      context,
                      Icons.qr_code_scanner,
                      'Pase Visitas',
                      'Generar QR',
                      const Color(0xFF10B981),
                      () => _abrirGenerarQR(context),
                    ),
                    if (esAdmin)
                      _construirBotonGrid(
                        context,
                        Icons.event_available,
                        'Reservas Admin',
                        'Aprobar solicitudes',
                        AppColors.mint,
                        () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AdminReservasScreen(),
                          ),
                        ),
                      )
                    else
                      _construirCeldaPaquetes(context),
                    _construirBotonGrid(
                      context,
                      Icons.campaign,
                      'Comunicados',
                      'Últimas noticias',
                      const Color(0xFF8B5CF6),
                      () => _abrirComunicados(context, esAdmin),
                    ),
                  ],
                ),

                const SizedBox(height: 90),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Banner + lista de paquetes en portería para el residente actual.
  Widget _construirSeccionPaquetesPendientes() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<List<Paquete>>(
      stream: _paquetesRepo.streamPendientesPorResidente(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        final lista = snapshot.data ?? const <Paquete>[];
        if (lista.isEmpty) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF59E0B)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.inventory_2, color: Colors.orange.shade800),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      lista.length == 1
                          ? 'Tienes 1 paquete en portería'
                          : 'Tienes ${lista.length} paquetes en portería',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Colors.orange.shade900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...lista.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.circle, size: 6, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.descripcion.isEmpty ? 'Paquete' : p.descripcion,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            if (p.fechaRecepcion != null)
                              Text(
                                'Recibido: ${_formatoFechaPaquete(p.fechaRecepcion!)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _construirCeldaPaquetes(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return _construirBotonGrid(
        context,
        Icons.inventory_2,
        'Paquetes',
        'Inicia sesión',
        const Color(0xFFF59E0B),
        null,
      );
    }

    return StreamBuilder<List<Paquete>>(
      stream: _paquetesRepo.streamPendientesPorResidente(uid),
      builder: (context, snapshot) {
        final lista = snapshot.data ?? const <Paquete>[];
        final n = lista.length;
        final sub = snapshot.connectionState == ConnectionState.waiting
            ? '…'
            : (n == 0 ? 'Sin pendientes' : '$n en portería');
        return _construirBotonGrid(
          context,
          Icons.inventory_2,
          'Paquetes',
          sub,
          const Color(0xFFF59E0B),
          () => _mostrarSheetPaquetes(context, uid),
        );
      },
    );
  }

  void _mostrarSheetPaquetes(BuildContext context, String uid) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20 + MediaQuery.of(ctx).viewPadding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Tus paquetes en portería',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: MediaQuery.of(ctx).size.height * 0.38,
                child: StreamBuilder<List<Paquete>>(
                  stream: _paquetesRepo.streamPendientesPorResidente(uid),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final list = snap.data ?? const <Paquete>[];
                    if (list.isEmpty) {
                      return const Center(
                        child: Text(
                          'No tienes paquetes pendientes de recoger.',
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final p = list[i];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.inventory_2_outlined),
                          title: Text(
                            p.descripcion.isEmpty ? 'Paquete' : p.descripcion,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            p.fechaRecepcion != null
                                ? 'Recibido: ${_formatoFechaPaquete(p.fechaRecepcion!)}'
                                : 'En portería',
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _formatoFechaPaquete(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mi = d.minute.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year} $hh:$mi';
  }

  /// Header degradado moderno con saludo y botón admin opcional.
  Widget _construirHeader(
    BuildContext context, {
    bool mostrarBotonAdminEnHeader = true,
  }) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(34),
        bottomRight: Radius.circular(34),
      ),
      child: Stack(
        children: [
          Container(
            height: 230,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0F172A),
                  Color(0xFF1E3A8A),
                  Color(0xFF3B82F6),
                ],
                stops: [0.0, 0.55, 1.0],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
            right: -50,
            top: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -60,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 20, 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _saludoSegunHora(),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 13,
                                letterSpacing: 0.4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Hola, ${_residente.nombre}!',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                                letterSpacing: -0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (mostrarBotonAdminEnHeader)
                        _BotonAdminHeader(
                          future: _esAdminFuture,
                          initialIsAdmin: widget.isAdmin,
                          onTap: () => _abrirAdmin(context),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.apartment_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _residente.unidadCompleta,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _saludoSegunHora() {
    final hora = DateTime.now().hour;
    if (hora < 12) return 'BUENOS DÍAS';
    if (hora < 19) return 'BUENAS TARDES';
    return 'BUENAS NOCHES';
  }

  Widget _construirBotonGrid(
    BuildContext context,
    IconData icono,
    String titulo,
    String subtitulo,
    Color color,
    VoidCallback? accion,
  ) {
    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(15),
      onTap: accion ??
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$titulo próximamente...'),
                duration: const Duration(seconds: 1),
              ),
            );
          },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: Icon(icono, color: color, size: 28),
          ),
          const SizedBox(height: 10),
          Text(
            titulo,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitulo,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  void _abrirComunicados(BuildContext context, bool esAdmin) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ComunicadosScreen(isAdmin: esAdmin),
      ),
    );
  }

  void _abrirAdmin(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AdminResidentesScreen()),
    );
  }

  void _abrirReservas(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CategoriasReservaScreen(
          nombre: _residente.nombre,
          apartamento: _residente.apartamento,
          torre: _residente.torre,
        ),
      ),
    );
  }

  void _abrirGenerarQR(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GenerarQRScreen(
          nombre: _residente.nombre,
          apartamento: _residente.apartamento,
          torre: _residente.torre,
        ),
      ),
    );
  }

  void _abrirMisVisitas(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MisVisitasScreen(
          residenteNombre: _residente.nombre,
          apartamento: _residente.apartamento,
          torre: _residente.torre,
        ),
      ),
    );
  }
}

/// Engranaje superior derecho del header. Solo se construye cuando Firestore
/// confirma que el rol del usuario es `admin`. En cualquier otro caso devuelve
/// `SizedBox.shrink()` sin parpadeo.
class _BotonAdminHeader extends StatelessWidget {
  const _BotonAdminHeader({
    required this.future,
    required this.initialIsAdmin,
    required this.onTap,
  });

  final Future<bool> future;
  final bool initialIsAdmin;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: future,
      initialData: initialIsAdmin,
      builder: (context, snapshot) {
        final esAdmin = snapshot.data ?? false;
        if (!esAdmin) return const SizedBox.shrink();

        return Material(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Icon(
                Icons.settings,
                color: Colors.white,
                size: 26,
                semanticLabel: 'Panel de administración',
              ),
            ),
          ),
        );
      },
    );
  }
}
