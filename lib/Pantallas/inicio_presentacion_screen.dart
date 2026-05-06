// Importa el servicio usado para cerrar sesion.
import 'package:flutter_application_1/Services/auth_service.dart';

// Importa la tarjeta visual de presentacion del usuario.
import 'package:flutter_application_1/Widgets/home/presentation_card.dart';

// Importa FirebaseAuth para leer el usuario autenticado actual.
import 'package:firebase_auth/firebase_auth.dart';

// Importa Material para construir la pantalla.
import 'package:flutter/material.dart';

// Pantalla de presentacion mostrada justo despues del login.
class Inicio extends StatelessWidget {
  // Constructor constante porque la pantalla no guarda estado mutable.
  const Inicio({super.key});

  // Construye la interfaz de presentacion.
  @override
  Widget build(BuildContext context) {
    // Obtiene el usuario autenticado desde FirebaseAuth.
    final user = FirebaseAuth.instance.currentUser;

    // Calcula el nombre visible: usa displayName o parte inicial del correo.
    final displayName = user?.displayName?.trim().isNotEmpty == true
        // Si displayName existe, se usa como nombre principal.
        ? user!.displayName!
        // Si no existe, se usa el correo antes del simbolo @.
        : user?.email?.split('@').first ?? 'Usuario';

    // Obtiene el correo del usuario o un texto alternativo.
    final email = user?.email ?? 'Sin correo registrado';

    // Obtiene la URL de la foto si Firebase la tiene.
    final photoUrl = user?.photoURL ?? '';

    // Scaffold define la estructura principal de la pantalla.
    return Scaffold(
      // AppBar muestra titulo y accion para cerrar sesion.
      appBar: AppBar(
        // Titulo visible de la pantalla.
        title: const Text('Presentacion'),

        // Lista de acciones del AppBar.
        actions: [
          // Boton para cerrar sesion.
          IconButton(
            // Tooltip ayuda a accesibilidad y explica el icono.
            tooltip: 'Cerrar sesion',

            // Icono de salida.
            icon: const Icon(Icons.logout),

            // Al presionar, llama el servicio de autenticacion.
            onPressed: () async => AuthService().signOut(),
          ),
        ],
      ),

      // Cuerpo centrado para mostrar la tarjeta.
      body: Center(
        // Permite desplazamiento en pantallas pequenas.
        child: SingleChildScrollView(
          // Agrega espacio alrededor de la tarjeta.
          padding: const EdgeInsets.all(24),

          // Limita el ancho para que se vea bien en tablets o web.
          child: ConstrainedBox(
            // Ancho maximo de la tarjeta.
            constraints: const BoxConstraints(maxWidth: 520),

            // Tarjeta visual con datos del usuario y boton al feed.
            child: PresentationCard(
              // Nombre visible que se mostrara en la tarjeta.
              displayName: displayName,

              // Correo visible del usuario.
              email: email,

              // URL de foto o cadena vacia.
              photoUrl: photoUrl,

              // Navega a la lista de publicaciones.
              onOpenFeed: () => Navigator.pushNamed(context, '/feed'),
            ),
          ),
        ),
      ),
    );
  }
}
