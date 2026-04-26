class Post {
  final String id;
  final String user;
  final String userId;
  final String userAvatar;
  final String description;
  final String? imageUrl; // por compatibilidad
  final String? imageBase64; // <<-- NUEVO
  final int likes;
  final DateTime? createdAt;

  Post({
    required this.id,
    required this.user,
    required this.userId,
    required this.userAvatar,
    required this.description,
    this.imageUrl,
    this.imageBase64, // <<--
    this.likes = 0,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'user': user,
        'userId': userId,
        'userAvatar': userAvatar,
        'description': description,
        'imageUrl': imageUrl,
        'imageBase64': imageBase64, // <<--
        'likes': likes,
        'createdAt': createdAt,
      };

  factory Post.fromMap(String id, Map<String, dynamic> m) {
    return Post(
      id: id,
      user: m['user'] ?? '',
      userId: m['userId'] ?? '',
      userAvatar: m['userAvatar'] ?? '',
      description: m['description'] ?? '',
      imageUrl: m['imageUrl'] as String?,
      imageBase64: m['imageBase64'] as String?, // <<--
      likes: (m['likes'] ?? 0) as int,
      createdAt: (m['createdAt'] == null)
          ? null
          : (m['createdAt'] as dynamic).toDate(),
    );
  }
}
