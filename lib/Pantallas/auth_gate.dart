// Importa el shell principal PH (tabs Inicio / Reservas / Pagos / Perfil).
import 'package:flutter_application_1/Pantallas/menu_principal_screen.dart';

// Importa el servicio que encapsula Firebase Authentication.
import 'package:flutter_application_1/Services/auth_service.dart';

// Importa la tarjeta visual que contiene login y registro.
import 'package:flutter_application_1/Widgets/auth/auth_card.dart';

// Importa el tipo User que representa un usuario autenticado en Firebase.
import 'package:firebase_auth/firebase_auth.dart';

// Importa Material para construir pantallas y widgets.
import 'package:flutter/material.dart';

// Widget que decide si el usuario entra a login o a la app autenticada.
class AuthGate extends StatelessWidget {
  // Constructor constante porque este widget no maneja estado mutable.
  const AuthGate({super.key});

  // Servicio compartido para escuchar cambios de autenticacion.
  static final AuthService _authService = AuthService();

  // Construye la compuerta de autenticacion.
  @override
  Widget build(BuildContext context) {
    // StreamBuilder reconstruye la UI cuando Firebase cambia la sesion.
    return StreamBuilder<User?>(
      // Stream que emite User si hay sesion o null si no la hay.
      stream: _authService.authState,

      // Builder que decide que pantalla mostrar segun el snapshot.
      builder: (context, snapshot) {
        // Mientras Firebase revisa la sesion local, muestra indicador de carga.
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Scaffold da una pantalla completa para centrar el loader.
          return const Scaffold(
            // Center ubica el CircularProgressIndicator en el centro.
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Si snapshot tiene usuario, significa que la sesion esta activa.
        return snapshot.hasData
            // Usuario autenticado: app principal con navegación inferior.
            ? const MenuNavegacionPrincipal()
            // Usuario no autenticado: muestra login o registro.
            : const AuthScreen();
      },
    );
  }
}

// Pantalla contenedora del formulario de autenticacion.
class AuthScreen extends StatefulWidget {
  // Constructor constante para navegar hacia esta pantalla.
  const AuthScreen({super.key});

  // Crea el estado donde se alterna entre login y registro.
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

// Estado privado de AuthScreen.
class _AuthScreenState extends State<AuthScreen> {
  // Controla si se ve el formulario de login o el de registro.
  bool _isLogin = true;

  // Alterna entre modo login y modo registro.
  void _toggleMode() {
    // setState notifica a Flutter que debe reconstruir la pantalla.
    setState(() => _isLogin = !_isLogin);
  }

  // Construye la pantalla visual de autenticacion.
  @override
  Widget build(BuildContext context) {
    // Scaffold crea la estructura base de pantalla.
    return Scaffold(
      // SafeArea evita que el contenido choque con notch o barras del sistema.
      body: SafeArea(
        // Center centra la tarjeta en pantallas grandes.
        child: Center(
          // SingleChildScrollView evita overflow cuando aparece el teclado.
          child: SingleChildScrollView(
            // Padding separa la tarjeta de los bordes de pantalla.
            padding: const EdgeInsets.all(24),

            // ConstrainedBox limita el ancho para que el formulario no se estire.
            child: ConstrainedBox(
              // Ancho maximo apropiado para formularios.
              constraints: const BoxConstraints(maxWidth: 420),

              // AuthCard contiene la UI de login/registro.
              child: AuthCard(
                // Envia a la tarjeta el modo actual.
                isLogin: _isLogin,

                // Envia la accion para alternar formularios.
                onToggleMode: _toggleMode,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
