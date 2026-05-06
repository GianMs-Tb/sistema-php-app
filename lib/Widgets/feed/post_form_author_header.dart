import 'package:flutter/material.dart';

/// Cabecera del formulario con datos del autor autenticado.
class PostFormAuthorHeader extends StatelessWidget {
  final String userName;
  final String userAvatar;

  const PostFormAuthorHeader({
    super.key,
    required this.userName,
    required this.userAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFE0F2FE),
            backgroundImage:
                userAvatar.isNotEmpty ? NetworkImage(userAvatar) : null,
            child: userAvatar.isEmpty
                ? Text(
                    userName.isNotEmpty ? userName.characters.first : '?',
                    style: const TextStyle(
                      color: Color(0xFF0369A1),
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF172033),
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Text(
                  'Autor de la publicación',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF64748B),
                      ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.verified_outlined,
            color: Color(0xFF14B8A6),
          ),
        ],
      ),
    );
  }
}
