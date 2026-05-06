// Importa Firestore para interpretar correctamente fechas tipo Timestamp.
import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de dominio que representa una publicación del feed.
///
/// Esta clase es la "forma oficial" de un post dentro de Flutter:
/// evita trabajar con mapas sueltos en la interfaz y hace más claro el CRUD.
class Post {
  // Identificador único del documento en Firestore.
  final String id;

  // Nombre visible del usuario que creó la publicación.
  final String user;

  // UID del usuario autenticado en Firebase Authentication.
  final String userId;

  // URL del avatar del usuario; puede venir vacío si no tiene foto.
  final String userAvatar;

  // Texto principal de la publicación.
  final String description;

  // Imagen histórica por URL; se mantiene para compatibilidad con datos viejos.
  final String? imageUrl;

  // Imagen principal del post codificada en Base64, como pide el ejercicio.
  final String? imageBase64;

  // Cantidad de likes acumulados en la publicación.
  final int likes;

  // Fecha de creación convertida a DateTime para mostrarla en la UI.
  final DateTime? createdAt;

  // Constructor principal con campos requeridos y opcionales.
  const Post({
    required this.id,
    required this.user,
    required this.userId,
    required this.userAvatar,
    required this.description,
    this.imageUrl,
    this.imageBase64,
    this.likes = 0,
    this.createdAt,
  });

  // Indica si el post tiene una imagen Base64 usable.
  bool get hasBase64Image => imageBase64 != null && imageBase64!.isNotEmpty;

  // Convierte el objeto Post en un mapa apto para Firestore.
  Map<String, dynamic> toMap() {
    // Retorna las claves exactamente como se guardan en la colección posts.
    return {
      'user': user,
      'userId': userId,
      'userAvatar': userAvatar,
      'description': description,
      'imageUrl': imageUrl,
      'imageBase64': imageBase64,
      'likes': likes,
      'createdAt': createdAt,
    };
  }

  // Crea un Post desde el id del documento y el mapa recibido de Firestore.
  factory Post.fromMap(String id, Map<String, dynamic> map) {
    // Devuelve una instancia tipada y tolerante a campos faltantes.
    return Post(
      id: id,
      user: (map['user'] ?? '') as String,
      userId: (map['userId'] ?? '') as String,
      userAvatar: (map['userAvatar'] ?? '') as String,
      description: (map['description'] ?? '') as String,
      imageUrl: map['imageUrl'] as String?,
      imageBase64: map['imageBase64'] as String?,
      likes: _readInt(map['likes']),
      createdAt: _readDate(map['createdAt']),
    );
  }

  // Crea una copia modificada del post sin perder los demás datos.
  Post copyWith({
    String? id,
    String? user,
    String? userId,
    String? userAvatar,
    String? description,
    String? imageUrl,
    String? imageBase64,
    int? likes,
    DateTime? createdAt,
  }) {
    // Retorna un nuevo objeto porque los modelos se manejan como inmutables.
    return Post(
      id: id ?? this.id,
      user: user ?? this.user,
      userId: userId ?? this.userId,
      userAvatar: userAvatar ?? this.userAvatar,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      imageBase64: imageBase64 ?? this.imageBase64,
      likes: likes ?? this.likes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Lee números aunque Firestore entregue int, double o null.
  static int _readInt(dynamic value) {
    // Si el valor ya es entero, se retorna directamente.
    if (value is int) return value;

    // Si el valor es numérico decimal, se convierte a entero.
    if (value is num) return value.toInt();

    // Si no hay valor válido, se usa cero como estado inicial.
    return 0;
  }

  // Lee fechas de Firestore, Dart o null sin romper la aplicación.
  static DateTime? _readDate(dynamic value) {
    // Firestore guarda serverTimestamp como Timestamp.
    if (value is Timestamp) return value.toDate();

    // Algunas pruebas locales podrían enviar DateTime directamente.
    if (value is DateTime) return value;

    // Si Firestore aún no resolvió la fecha, se permite null.
    return null;
  }
}
