import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../Models/app_user.dart';
import '../Models/comunicado_model.dart';
import '../Models/residente.dart';
import '../Services/firebase_comunicado_repository.dart';
import 'admin_residentes_screen.dart';
import 'categorias_reserva_screen.dart';
import 'generar_qr_screen.dart';

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

  final _comunicadosRepo = FirebaseComunicadoRepository();

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
    return SingleChildScrollView(
      child: Column(
        children: [
          _construirHeader(context),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'Gestión Digital',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),

                // 2. Espacio perfecto entre el título y los botones
                const SizedBox(height: 10),

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
                      Icons.sports_tennis,
                      'Reservas',
                      'Zonas comunes',
                      const Color(0xFF3B82F6),
                      () => _abrirReservas(context),
                    ),
                    _construirBotonGrid(
                      context,
                      Icons.qr_code_scanner,
                      'Pase Visitas',
                      'Generar QR',
                      const Color(0xFF10B981),
                      () => _abrirGenerarQR(context),
                    ),
                    _construirBotonGrid(
                      context,
                      Icons.inventory_2,
                      'Paquetes',
                      '3 Pendientes',
                      const Color(0xFFF59E0B),
                      null,
                    ),
                    _construirBotonGrid(
                      context,
                      Icons.campaign,
                      'Comunicados',
                      'Últimas noticias',
                      const Color(0xFF8B5CF6),
                      null,
                    ),
                  ],
                ),

                // 3. Separación ideal entre los botones y la sección de comunicados
                const SizedBox(height: 32),
                _construirSeccionComunicados(),

                // 4. El colchón final para la barra de cristal
                const SizedBox(height: 90),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Header degradado moderno con saludo y botón admin opcional.
  Widget _construirHeader(BuildContext context) {
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: accion ??
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$titulo próximamente...'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icono, color: color, size: 28),
                ),
                const Spacer(),
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitulo,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Feed de comunicados leído de Firestore (colección `comunicados`).
  /// Para admin agrega un botón "Publicar" inline en la cabecera.
  Widget _construirSeccionComunicados() {
    return FutureBuilder<bool>(
      future: _esAdminFuture,
      initialData: widget.isAdmin,
      builder: (context, adminSnap) {
        final esAdmin = adminSnap.data ?? false;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Comunicados',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                if (esAdmin)
                  FilledButton.tonalIcon(
                    onPressed: () => _mostrarDialogoNuevoComunicado(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Publicar'),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: const Color(0xFF1E3A8A),
                      backgroundColor: const Color(0xFFE0E7FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<Comunicado>>(
              stream: _comunicadosRepo.stream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _MensajeFeed(
                    icono: Icons.error_outline,
                    texto: 'Error al cargar comunicados.',
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final lista = snapshot.data ?? const <Comunicado>[];
                if (lista.isEmpty) {
                  return _MensajeFeed(
                    icono: Icons.campaign_outlined,
                    texto: esAdmin
                        ? 'Aún no hay comunicados.\nPulsa "Publicar" para crear el primero.'
                        : 'Aún no hay comunicados.',
                  );
                }
                return Column(
                  children: lista
                      .map((c) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _TarjetaComunicado(comunicado: c),
                          ))
                      .toList(),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _mostrarDialogoNuevoComunicado(BuildContext context) async {
    final tituloCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo comunicado'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tituloCtrl,
                decoration: const InputDecoration(labelText: 'Título'),
                textCapitalization: TextCapitalization.sentences,
                autofocus: true,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  alignLabelWithHint: true,
                ),
                textCapitalization: TextCapitalization.sentences,
                minLines: 3,
                maxLines: 6,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Publicar'),
          ),
        ],
      ),
    );

    if (ok == true) {
      final titulo = tituloCtrl.text.trim();
      final desc = descCtrl.text.trim();
      if (titulo.isEmpty || desc.isEmpty) {
        _mostrarSnack('Título y descripción son obligatorios.', esError: true);
      } else {
        final user = FirebaseAuth.instance.currentUser;
        final autor = (user?.displayName?.trim().isNotEmpty == true)
            ? user!.displayName!
            : (user?.email ?? 'Administración');
        try {
          await _comunicadosRepo.crear(
            Comunicado(
              id: '',
              titulo: titulo,
              descripcion: desc,
              autor: autor,
              autorUid: user?.uid ?? '',
            ),
          );
          _mostrarSnack('Comunicado publicado');
        } catch (e) {
          _mostrarSnack('Error al publicar: $e', esError: true);
        }
      }
    }

    tituloCtrl.dispose();
    descCtrl.dispose();
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

/// Tarjeta tipo "feed" para un comunicado.
class _TarjetaComunicado extends StatelessWidget {
  const _TarjetaComunicado({required this.comunicado});

  final Comunicado comunicado;

  @override
  Widget build(BuildContext context) {
    final fechaTxt = _formatearFecha(comunicado.createdAt);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: const Border(
          left: BorderSide(color: Color(0xFF3B82F6), width: 5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFFE0E7FF),
                child: Icon(Icons.campaign, color: Color(0xFF3B82F6)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  comunicado.titulo.isEmpty
                      ? 'Sin título'
                      : comunicado.titulo,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            comunicado.descripcion,
            style: const TextStyle(
              fontSize: 13.5,
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
                  comunicado.autor.isEmpty
                      ? 'Administración'
                      : comunicado.autor,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                fechaTxt,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return '—';
    final dd = fecha.day.toString().padLeft(2, '0');
    final mm = fecha.month.toString().padLeft(2, '0');
    final hh = fecha.hour.toString().padLeft(2, '0');
    final min = fecha.minute.toString().padLeft(2, '0');
    return '$dd/$mm/${fecha.year} $hh:$min';
  }
}

/// Estado vacío / error compacto del feed.
class _MensajeFeed extends StatelessWidget {
  const _MensajeFeed({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(icono, size: 36, color: const Color(0xFF94A3B8)),
          const SizedBox(height: 8),
          Text(
            texto,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
        ],
      ),
    );
  }
}
