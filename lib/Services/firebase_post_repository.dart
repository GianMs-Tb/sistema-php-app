import 'package:cloud_firestore/cloud_firestore.dart';

class FirebasePostRepository {
  final _db = FirebaseFirestore.instance;

  // Stream of posts ordered by createdAt desc
  Stream<QuerySnapshot<Map<String, dynamic>>> streamPosts({int limit = 50}) {
    return _db
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  Future<void> createPost({
    required String userId,
    required String userName,
    required String userAvatar,
    required String description,
    String? imageBase64, // <<-- NUEVO
  }) async {
    await _db.collection('posts').add({
      'userId': userId,
      'user': userName,
      'userAvatar': userAvatar,
      'description': description,
      'imageBase64': imageBase64, // <<--
      'imageUrl': null, // por claridad
      'likes': 0,
      'createdAt': FieldValue.serverTimestamp()
    });
  }

  Future<void> likePost(String postId) async {
    final ref = _db.collection('posts').doc(postId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final current = (snap.data()?['likes'] ?? 0) as int;
      tx.update(ref, {'likes': current + 1});
    });
  }
}