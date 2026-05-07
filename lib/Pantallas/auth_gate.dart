// Importa la compuerta de rol consultando Firestore (`users`).
import 'package:cloud_firestore/cloud_firestore.dart';

// Importa el shell principal PH (tabs Inicio / Reservas / Pagos / Perfil).
import 'package:flutter_application_1/Models/app_user.dart';
import 'package:flutter_application_1/Pantallas/menu_principal_screen.dart';

// Importa el servicio que encapsula Firebase Authentication.
import 'package:flutter_application_1/Services/auth_service.dart';

// Importa la tarjeta visual que contiene login y registro.
import 'package:flutter_application_1/Widgets/auth/auth_card.dart';

// Importa el tipo User que representa un usuario autenticado en Firebase.
import 'package:firebase_auth/firebase_auth.dart';

// Importa Material para construir pantallas y widgets.
import 'package:flutter/material.dart';

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

        return MenuNavegacionPrincipal(isAdmin: appUser.isAdmin);
      },
    );
  }
}

// Pantalla contenedora del formulario de autenticacion.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

// Estado privado de AuthScreen.
class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;

  void _toggleMode() {
    setState(() => _isLogin = !_isLogin);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AuthCard(
                isLogin: _isLogin,
                onToggleMode: _toggleMode,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
