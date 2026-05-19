// Importa la compuerta de rol consultando Firestore (`users`).
import 'package:cloud_firestore/cloud_firestore.dart';

// Importa el shell principal PH (tabs Inicio / PQRS / Perfil).
import 'package:flutter_application_1/Models/app_user.dart';
import 'package:flutter_application_1/Pantallas/menu_principal_screen.dart';
import 'package:flutter_application_1/Pantallas/portero_inicio_screen.dart';

// Importa el servicio que encapsula Firebase Authentication.
import 'package:flutter_application_1/Services/auth_service.dart';

// Importa la tarjeta visual que contiene login y registro.
import 'package:flutter_application_1/Widgets/auth/auth_card.dart';

// Importa el tipo User que representa un usuario autenticado en Firebase.
import 'package:firebase_auth/firebase_auth.dart';

// Importa Material para construir pantallas y widgets.
import 'package:flutter/material.dart';
import 'package:flutter_application_1/theme/app_theme.dart';

/// Tras el login, escucha `users/{uid}` y pasa [isAdmin] al menú principal.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  static final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authState,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData) {
          return const AuthScreen();
        }

        return FirestoreRoleGate(user: snapshot.data!);
      },
    );
  }
}

/// Asegura documento en `users` si falta y expone el rol al shell de la app.
class FirestoreRoleGate extends StatefulWidget {
  const FirestoreRoleGate({super.key, required this.user});

  final User user;

  @override
  State<FirestoreRoleGate> createState() => _FirestoreRoleGateState();
}

class _FirestoreRoleGateState extends State<FirestoreRoleGate> {
  bool _ensuredDoc = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .snapshots(),
      builder: (context, docSnap) {
        if (docSnap.connectionState == ConnectionState.waiting &&
            !docSnap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final doc = docSnap.data;
        if (doc != null && !doc.exists && !_ensuredDoc) {
          _ensuredDoc = true;
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await AuthGate._authService.ensureUserDocumentIfMissing(
              widget.user,
            );
          });
        }

        final raw =
            (doc != null && doc.exists) ? doc.data() : null;
        final appUser = AppUser.fromMap(widget.user.uid, raw ?? {});

        if (appUser.isPortero) {
          return const PorteroInicioScreen();
        }

        return MenuNavegacionPrincipal(isAdmin: appUser.isAdmin);
      },
    );
  }
}

/// Pantalla de autenticación premium con fondo degradado animado.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  bool _isLogin = true;
  late final AnimationController _gradientCtrl;

  @override
  void initState() {
    super.initState();
    _gradientCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _gradientCtrl.dispose();
    super.dispose();
  }

  void _toggleMode() => setState(() => _isLogin = !_isLogin);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _gradientCtrl,
        builder: (context, _) {
          final t = _gradientCtrl.value;
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-1 + t * 0.4, -1),
                end: Alignment(1 - t * 0.3, 1),
                colors: [
                  const Color(0xFF0A192F),
                  Color.lerp(
                    const Color(0xFF112240),
                    const Color(0xFF1A365D),
                    t,
                  )!,
                  const Color(0xFF0A192F),
                ],
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Silueta de edificio (overlay decorativo)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.15),
                          Colors.black.withValues(alpha: 0.55),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -40,
                  top: 80,
                  child: Icon(
                    Icons.domain,
                    size: 280,
                    color: AppColors.mint.withValues(alpha: 0.06),
                  ),
                ),
                Positioned(
                  left: -30,
                  bottom: 60,
                  child: Icon(
                    Icons.apartment,
                    size: 200,
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
                SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 32,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: AuthCard(
                          isLogin: _isLogin,
                          onToggleMode: _toggleMode,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
