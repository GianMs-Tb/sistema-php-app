import 'package:flutter_application_1/Models/post.dart';
import 'package:flutter_application_1/Widgets/feed/post_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Lista visual de publicaciones del feed.
class PostList extends StatelessWidget {
  final List<Post> posts;
  final User? currentUser;
  final ValueChanged<String> onLike;
  final ValueChanged<Post> onEdit;
  final ValueChanged<Post> onDelete;

  const PostList({
    super.key,
    required this.posts,
    required this.currentUser,
    required this.onLike,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        final isOwner = currentUser?.uid == post.userId;

        return PostCard(
          post: post,
          isOwner: isOwner,
          onLike: () => onLike(post.id),
          onEdit: isOwner ? () => onEdit(post) : null,
          onDelete: isOwner ? () => onDelete(post) : null,
        );
      },
    );
  }
}
