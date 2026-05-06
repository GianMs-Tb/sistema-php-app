import 'package:flutter/material.dart';

/// Barra superior del formulario de publicación.
class PostFormAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isEditing;
  final bool loading;
  final VoidCallback onSave;

  const PostFormAppBar({
    super.key,
    required this.isEditing,
    required this.loading,
    required this.onSave,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(isEditing ? 'Editar post' : 'Nuevo post'),
      backgroundColor: const Color.fromARGB(255, 163, 198, 243),
      foregroundColor: const Color(0xFF172033),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: FilledButton.icon(
            onPressed: loading ? null : onSave,
            icon: loading
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(isEditing ? Icons.save_outlined : Icons.send_outlined),
            label: Text(isEditing ? 'Guardar' : 'Publicar'),
          ),
        ),
      ],
    );
  }
}
