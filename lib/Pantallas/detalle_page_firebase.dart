// Importa el modelo Post para recibir objetos tipados desde Firestore.
import 'package:flutter_application_1/Models/post.dart';

// Importa el formulario usado para crear o editar publicaciones.
import 'package:flutter_application_1/Pantallas/post_form_screen.dart';

// Importa el servicio de autenticacion para cerrar sesion.
import 'package:flutter_application_1/Services/auth_service.dart';

// Importa el repositorio que contiene las operaciones CRUD de posts.
import 'package:flutter_application_1/Services/firebase_post_repository.dart';

// Importa el AppBar personalizado del feed.
import 'package:flutter_application_1/Widgets/feed/feed_app_bar.dart';

// Importa el encabezado visual del feed.
import 'package:flutter_application_1/Widgets/feed/feed_header.dart';

// Importa el widget que escucha y renderiza el stream de publicaciones.
import 'package:flutter_application_1/Widgets/feed/feed_post_stream.dart';

// Importa FirebaseAuth para conocer el usuario actual.
import 'package:firebase_auth/firebase_auth.dart';

// Importa Material para construir la pantalla.
import 'package:flutter/material.dart';

// Pantalla principal donde se lista el feed y se ejecuta el CRUD.
class DetallePage extends StatefulWidget {
  // Constructor constante para navegacion por rutas.
  const DetallePage({super.key});

  // Crea el estado de la pantalla.
  @override
  State<DetallePage> createState() => _DetallePageState();
}

// Estado privado de la pantalla de feed.
class _DetallePageState extends State<DetallePage> {
  // Repositorio que conecta la pantalla con Firestore.
  final FirebasePostRepository _repository = FirebasePostRepository();

  // Abre el formulario en modo crear o editar segun reciba un post.
  Future<void> _openForm({Post? post}) async {
    // Lee el usuario autenticado actual.
    final user = FirebaseAuth.instance.currentUser;

    // Si no hay usuario, no se permite publicar.
    if (user == null) {
      // Muestra un mensaje claro al usuario.
      _showMessage('Debes iniciar sesion para publicar.');

      // Detiene la ejecucion del metodo.
      return;
    }

    // Navega al formulario y espera a que el usuario vuelva.
    await Navigator.push(
      // Contexto de navegacion actual.
      context,

      // MaterialPageRoute crea una transicion nativa de Material.
      MaterialPageRoute(
        // Builder crea la pantalla destino.
        builder: (_) => PostFormScreen(
          // Si post es null, el formulario crea; si no, edita.
          post: post,

          // UID del usuario que publica o edita.
          userId: user.uid,

          // Nombre visible del usuario actual.
          userName: _displayName(user),

          // Foto del usuario, si existe.
          userAvatar: user.photoURL ?? '',
        ),
      ),
    );
  }

  // Registra un like en una publicacion.
  Future<void> _likePost(String postId) async {
    // Captura errores para no romper la interfaz.
    try {
      // Pide al repositorio incrementar el contador.
      await _repository.likePost(postId);
    } catch (error) {
      // Informa si Firestore no pudo registrar el like.
      _showMessage('No se pudo registrar el like: $error');
    }
  }

  // Pide confirmacion antes de eliminar una publicacion.
  Future<void> _confirmDelete(Post post) async {
    // Abre un dialogo de confirmacion.
    final confirmed = await showDialog<bool>(
      // Contexto necesario para mostrar el dialogo.
      context: context,

      // Builder que construye el contenido del dialogo.
      builder: (dialogContext) => AlertDialog(
        // Titulo del dialogo.
        title: const Text('Eliminar publicacion'),

        // Mensaje de advertencia.
        content: const Text('Deseas eliminar esta publicacion?'),

        // Botones de accion del dialogo.
        actions: [
          // Boton para cancelar.
          TextButton(
            // Cierra el dialogo devolviendo false.
            onPressed: () => Navigator.pop(dialogContext, false),

            // Texto visible del boton.
            child: const Text('Cancelar'),
          ),

          // Boton principal para confirmar eliminacion.
          FilledButton.icon(
            // Cierra el dialogo devolviendo true.
            onPressed: () => Navigator.pop(dialogContext, true),

            // Icono de eliminar.
            icon: const Icon(Icons.delete_outline),

            // Texto visible del boton.
            label: const Text('Eliminar'),
          ),
        ],
      ),
    );

    // Si el usuario confirmo, elimina el post.
    if (confirmed == true) await _deletePost(post.id);
  }

  // Ejecuta la eliminacion real en Firestore.
  Future<void> _deletePost(String postId) async {
    // Captura errores de red, permisos o Firestore.
    try {
      // Pide al repositorio borrar el documento.
      await _repository.deletePost(postId);

      // Confirma visualmente que se elimino.
      _showMessage('Publicacion eliminada.');
    } catch (error) {
      // Muestra el error si no se pudo eliminar.
      _showMessage('No se pudo eliminar: $error');
    }
  }

  // Cierra sesion y regresa a la ruta raiz.
  Future<void> _signOut() async {
    // Cierra la sesion en FirebaseAuth.
    await AuthService().signOut();

    // Verifica que la pantalla siga montada antes de navegar.
    if (mounted) {
      // Limpia la pila de navegacion y vuelve al AuthGate.
      Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
    }
  }

  // Calcula el nombre visible del usuario.
  String _displayName(User user) {
    // Usa displayName cuando existe y no esta vacio.
    return user.displayName?.trim().isNotEmpty == true
        // Retorna el nombre configurado en FirebaseAuth.
        ? user.displayName!
        // Si no hay nombre, usa el correo o un fallback.
        : user.email ?? 'Usuario';
  }

  // Muestra mensajes breves en la parte inferior.
  void _showMessage(String message) {
    // Evita usar context si la pantalla ya fue destruida.
    if (!mounted) return;

    // Muestra un SnackBar con el mensaje recibido.
    ScaffoldMessenger.of(context).showSnackBar(
      // Contenido textual del SnackBar.
      SnackBar(content: Text(message)),
    );
  }

  // Construye la pantalla visual del feed.
  @override
  Widget build(BuildContext context) {
    // Obtiene el usuario para saludarlo y validar propiedad de posts.
    final user = FirebaseAuth.instance.currentUser;

    // Scaffold define AppBar, body y boton flotante.
    return Scaffold(
      // AppBar personalizado con volver a presentacion y cerrar sesion.
      appBar: FeedAppBar(
        // Navega a la tarjeta de presentacion.
        onGoHome: () => Navigator.pushReplacementNamed(context, '/home'),

        // Ejecuta cierre de sesion.
        onSignOut: _signOut,
      ),

      // Fondo visual con gradiente suave.
      body: DecoratedBox(
        // Decoracion del fondo de toda la pantalla.
        decoration: const BoxDecoration(
          // Gradiente vertical para evitar fondo plano blanco.
          gradient: LinearGradient(
            // Colores suaves del fondo.
            colors: [
              // Azul muy claro inicial.
              Color(0xFFF4F7FB),

              // Azul claro intermedio.
              Color(0xFFEFF6FF),

              // Gris casi blanco final.
              Color(0xFFF8FAFC),
            ],

            // Inicio del gradiente.
            begin: Alignment.topCenter,

            // Fin del gradiente.
            end: Alignment.bottomCenter,
          ),
        ),

        // Columna principal del feed.
        child: Column(
          // Widgets verticales del feed.
          children: [
            // Encabezado con saludo del usuario.
            FeedHeader(
              // Si no hay usuario, usa un texto generico.
              displayName: user == null ? 'Usuario' : _displayName(user),
            ),

            // Expanded permite que la lista ocupe el espacio restante.
            Expanded(
              // Widget que escucha Firestore y dibuja estados/lista.
              child: FeedPostStream(
                // Stream de posts entregado por el repositorio.
                postsStream: _repository.streamPosts(),

                // Usuario actual para saber si un post es propio.
                currentUser: user,

                // Callback para dar like.
                onLike: _likePost,

                // Callback para editar.
                onEdit: (post) => _openForm(post: post),

                // Callback para eliminar.
                onDelete: _confirmDelete,
              ),
            ),
          ],
        ),
      ),

      // Boton flotante para crear una nueva publicacion.
      floatingActionButton: FloatingActionButton.extended(
        // Abre el formulario sin post, por eso entra en modo crear.
        onPressed: () => _openForm(),

        // Icono de agregar.
        icon: const Icon(Icons.add),

        // Texto del boton.
        label: const Text('Nuevo post'),
      ),
    );
  }
}
