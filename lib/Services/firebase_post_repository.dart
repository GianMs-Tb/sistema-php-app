// Importa el modelo Post para transformar documentos en objetos Dart.
import 'package:flutter_application_1/Models/post.dart';

// Importa Cloud Firestore para leer y escribir en la base de datos.
import 'package:cloud_firestore/cloud_firestore.dart';

// Repositorio encargado del CRUD de publicaciones en Firebase.
class FirebasePostRepository {
  // Crea una referencia privada a la instancia global de Firestore.
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Define un acceso corto a la coleccion posts con tipo Map<String, dynamic>.
  CollectionReference<Map<String, dynamic>> get _posts =>
      // Selecciona la coleccion donde se almacenan todas las publicaciones.
      _db.collection('posts');

  // Retorna las publicaciones en tiempo real como una lista de objetos Post.
  Stream<List<Post>> streamPosts({int limit = 50}) {
    // Construye una consulta sobre la coleccion posts.
    return _posts
        // Ordena primero los posts mas recientes.
        .orderBy('createdAt', descending: true)
        // Limita la cantidad de documentos para no cargar demasiados datos.
        .limit(limit)
        // Escucha cambios en tiempo real desde Firestore.
        .snapshots()
        // Convierte cada snapshot de Firestore en una lista de Post.
        .map(
          // Recorre todos los documentos recibidos.
          (snapshot) => snapshot.docs
              // Convierte cada documento en una instancia del modelo Post.
              .map((doc) => Post.fromMap(doc.id, doc.data()))
              // Materializa el resultado como lista.
              .toList(),
        );
  }

  // Crea una nueva publicacion en Firestore.
  Future<void> createPost({
    // UID del usuario autenticado que crea el post.
    required String userId,

    // Nombre visible del usuario que crea el post.
    required String userName,

    // Avatar del usuario que crea el post.
    required String userAvatar,

    // Texto escrito por el usuario.
    required String description,

    // Imagen codificada en Base64; puede ser null si no se selecciona imagen.
    String? imageBase64,
  }) async {
    // Agrega un documento nuevo en la coleccion posts.
    await _posts.add({
      // Guarda el UID para identificar al dueno del post.
      'userId': userId,

      // Guarda el nombre visible para mostrarlo en la tarjeta.
      'user': userName,

      // Guarda el avatar para mostrarlo en la tarjeta.
      'userAvatar': userAvatar,

      // Guarda la descripcion principal.
      'description': description,

      // Guarda la imagen en formato Base64 segun el requisito del ejercicio.
      'imageBase64': imageBase64,

      // Mantiene compatibilidad con versiones anteriores que usaban URL.
      'imageUrl': null,

      // Inicializa los likes en cero.
      'likes': 0,

      // Usa la hora del servidor para evitar depender del reloj del celular.
      'createdAt': FieldValue.serverTimestamp(),

      // Guarda tambien la fecha de ultima actualizacion.
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Actualiza una publicacion existente.
  Future<void> updatePost({
    // Id del documento que se va a modificar.
    required String postId,

    // Nueva descripcion del post.
    required String description,

    // Nueva imagen Base64 o null si se quito la imagen.
    String? imageBase64,
  }) async {
    // Ubica el documento por id y actualiza solo los campos editables.
    await _posts.doc(postId).update({
      // Reemplaza la descripcion anterior.
      'description': description,

      // Reemplaza o elimina logicamente la imagen Base64.
      'imageBase64': imageBase64,

      // Actualiza la fecha de modificacion desde el servidor.
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Elimina una publicacion por su id.
  Future<void> deletePost(String postId) {
    // Borra el documento de la coleccion posts.
    return _posts.doc(postId).delete();
  }

  // Incrementa los likes de una publicacion.
  Future<void> likePost(String postId) {
    // Usa incremento atomico para evitar conflictos entre usuarios.
    return _posts.doc(postId).update({
      // Suma uno al contador actual de likes.
      'likes': FieldValue.increment(1),
    });
  }
}
