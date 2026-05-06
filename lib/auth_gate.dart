import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../Pantallas/inicio_screen.dart'; // Ajusta esta ruta si es necesario
// IMPORTA AQUÍ TU PANTALLA DE LOGIN:
// import '../Pantallas/login_screen.dart'; 

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Si el usuario está autenticado, va al Inicio
          if (snapshot.hasData) {
            return const InicioScreen(); 
          }
          // Si NO está autenticado, va al Login
          else {
            // DESCOMENTA LA LÍNEA DE ABAJO Y PON TU PANTALLA DE LOGIN REAL
            // return const LoginScreen();
            return const Center(child: Text("Aquí va la pantalla de Login"));
          }
        },
      ),
    );
  }
}