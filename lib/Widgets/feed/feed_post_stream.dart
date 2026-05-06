import 'package:flutter_application_1/Models/post.dart';
import 'package:flutter_application_1/Widgets/feed/feed_message.dart';
import 'package:flutter_application_1/Widgets/feed/post_list.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Escucha y representa el stream de publicaciones del feed.
class FeedPostStream extends StatelessWidget {
  final Stream<List<Post>> postsStream;
  final User? currentUser;
  final ValueChanged<String> onLike;
  final ValueChanged<Post> onEdit;
  final ValueChanged<Post> onDelete;

  const FeedPostStream({
    super.key,
    required this.postsStream,
    required this.currentUser,
    required this.onLike,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Post>>(
      stream: postsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return FeedMessage(
            icon: Icons.error_outline,
            title: 'No se pudo cargar el feed',
            message: '${snapshot.error}',
          );
        }

        final posts = snapshot.data ?? [];
        if (posts.isEmpty) {
          return const FeedMessage(
            icon: Icons.dynamic_feed_outlined,
            title: 'Aún no hay publicaciones',
            message: 'Crea el primer post para iniciar el feed.',
          );
        }

        return PostList(
          posts: posts,
          currentUser: currentUser,
          onLike: onLike,
          onEdit: onEdit,
          onDelete: onDelete,
        );
      },
    );
  }
}
