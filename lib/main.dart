import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/Pantallas/auth_gate.dart';
import 'package:flutter_application_1/Pantallas/detalle_page_firebase.dart';
import 'package:flutter_application_1/Pantallas/inicio_presentacion_screen.dart';
import 'package:flutter_application_1/firebase_options.dart';
import 'package:flutter_application_1/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SistemaPHApp());
}

/// Raíz de la app: tema unificado, Firebase inicializado y rutas (auth, feed, presentación).
class SistemaPHApp extends StatelessWidget {
  const SistemaPHApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema Integral PH',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      initialRoute: '/',
      routes: {
        '/': (_) => const AuthGate(),
        '/home': (_) => const Inicio(),
        '/feed': (_) => const DetallePage(),
        '/detalle': (_) => const DetallePage(),
      },
    );
  }
}
