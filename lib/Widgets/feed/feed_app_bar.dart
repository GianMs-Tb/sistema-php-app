import 'package:flutter/material.dart';

/// Barra superior del feed.
class FeedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onGoHome;
  final VoidCallback onSignOut;

  const FeedAppBar({
    super.key,
    required this.onGoHome,
    required this.onSignOut,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Feeds'),
      backgroundColor: const Color.fromARGB(255, 163, 198, 243),
      foregroundColor: const Color(0xFF172033),
      actions: [
        IconButton.filledTonal(
          tooltip: 'Volver a presentación',
          icon: const Icon(Icons.badge_outlined),
          onPressed: onGoHome,
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Cerrar sesión',
          icon: const Icon(Icons.logout),
          onPressed: onSignOut,
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
