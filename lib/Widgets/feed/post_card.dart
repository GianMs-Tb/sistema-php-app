import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_application_1/Models/post.dart';
import 'package:flutter/material.dart';

/// Widget visual que representa una publicación del feed.
class PostCard extends StatelessWidget {
  final Post post;
  final bool isOwner;
  final VoidCallback? onLike;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const PostCard({
    super.key,
    required this.post,
    required this.isOwner,
    this.onLike,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final imageBytes = _bytesFromBase64(post.imageBase64);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PostHeader(
            post: post,
            isOwner: isOwner,
            timeAgo: _timeAgo(post.createdAt),
            onEdit: onEdit,
            onDelete: onDelete,
          ),
          if (imageBytes != null) _PostImage(bytes: imageBytes),
          if (imageBytes == null &&
              post.imageUrl != null &&
              post.imageUrl!.isNotEmpty)
            _PostNetworkImage(url: post.imageUrl!),
          if (post.description.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
              child: Text(
                post.description,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF1E293B),
                  height: 1.35,
                ),
              ),
            ),
          _PostActions(
            likes: post.likes,
            isOwner: isOwner,
            onLike: onLike,
          ),
        ],
      ),
    );
  }

  Uint8List? _bytesFromBase64(String? value) {
    if (value == null || value.isEmpty) return null;

    try {
      return base64Decode(value);
    } catch (_) {
      return null;
    }
  }

  String _timeAgo(DateTime? date) {
    if (date == null) return 'Publicado ahora';

    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Publicado ahora';
    if (diff.inHours < 1) return 'Hace ${diff.inMinutes} min';
    if (diff.inDays < 1) return 'Hace ${diff.inHours} h';
    return 'Hace ${diff.inDays} d';
  }
}

/// Cabecera de la publicación con autor, fecha y menú.
class _PostHeader extends StatelessWidget {
  final Post post;
  final bool isOwner;
  final String timeAgo;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _PostHeader({
    required this.post,
    required this.isOwner,
    required this.timeAgo,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 10, 10),
      child: Row(
        children: [
          _PostAvatar(post: post),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.user,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF172033),
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeAgo,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF64748B),
                      ),
                ),
              ],
            ),
          ),
          if (isOwner)
            PopupMenuButton<_PostAction>(
              icon: const Icon(Icons.more_horiz),
              onSelected: (action) {
                if (action == _PostAction.edit) onEdit?.call();
                if (action == _PostAction.delete) onDelete?.call();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: _PostAction.edit,
                  child: ListTile(
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Editar'),
                  ),
                ),
                PopupMenuItem(
                  value: _PostAction.delete,
                  child: ListTile(
                    leading: Icon(Icons.delete_outline),
                    title: Text('Eliminar'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Avatar del autor con fallback por inicial.
class _PostAvatar extends StatelessWidget {
  final Post post;

  const _PostAvatar({required this.post});

  @override
  Widget build(BuildContext context) {
    if (post.userAvatar.isNotEmpty) {
      return CircleAvatar(
        radius: 23,
        backgroundImage: NetworkImage(post.userAvatar),
      );
    }

    final initial = post.user.isNotEmpty ? post.user.characters.first : '?';

    return CircleAvatar(
      radius: 23,
      backgroundColor: const Color(0xFFE0F2FE),
      child: Text(
        initial.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF0369A1),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// Acciones inferiores de la publicación.
class _PostActions extends StatelessWidget {
  final int likes;
  final bool isOwner;
  final VoidCallback? onLike;

  const _PostActions({
    required this.likes,
    required this.isOwner,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 14, 12),
      child: Row(
        children: [
          IconButton.filledTonal(
            tooltip: 'Me gusta',
            icon: const Icon(Icons.favorite_border),
            onPressed: onLike,
          ),
          const SizedBox(width: 6),
          Text(
            '$likes',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const Spacer(),
          if (isOwner)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEDD5),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Tu publicación',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: const Color(0xFFC2410C),
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}

enum _PostAction {
  edit,
  delete,
}

/// Imagen de publicación proveniente de Base64.
class _PostImage extends StatelessWidget {
  final Uint8List bytes;

  const _PostImage({required this.bytes});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AspectRatio(
          aspectRatio: 1,
          child: Image.memory(
            bytes,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => const _ImageFallback(),
          ),
        ),
      ),
    );
  }
}

/// Imagen de respaldo por URL para datos antiguos.
class _PostNetworkImage extends StatelessWidget {
  final String url;

  const _PostNetworkImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AspectRatio(
          aspectRatio: 1,
          child: Image.network(
            url,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Center(child: CircularProgressIndicator());
            },
            errorBuilder: (_, __, ___) => const _ImageFallback(),
          ),
        ),
      ),
    );
  }
}

/// Placeholder cuando una imagen no puede renderizarse.
class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE2E8F0),
      child: const Center(
        child: Icon(
          Icons.broken_image_outlined,
          size: 42,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }
}
