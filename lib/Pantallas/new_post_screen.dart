// Importa el formulario único que ahora sirve para crear y editar posts.
import 'package:flutter_application_1/Pantallas/post_form_screen.dart';

// Importa Material para mantener este widget compatible con navegación antigua.
import 'package:flutter/material.dart';

/// Pantalla puente para código antiguo que todavía navegue a NewPostScreen.
///
/// La implementación real vive en PostFormScreen para no duplicar formularios.
class NewPostScreen extends StatelessWidget {
  // UID del usuario autenticado.
  final String userId;

  // Nombre visible del usuario autenticado.
  final String userName;

  // Avatar del usuario autenticado.
  final String userAvatar;

  // Constructor compatible con la versión anterior.
  const NewPostScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.userAvatar,
  });

  // Construye el formulario real en modo creación.
  @override
  Widget build(BuildContext context) {
    // Reutiliza PostFormScreen sin pasar post para crear uno nuevo.
    return PostFormScreen(
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
    );
  }
}
