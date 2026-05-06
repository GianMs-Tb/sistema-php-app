import 'package:flutter/material.dart';

/// Botón principal del formulario para publicar o guardar cambios.
class PostSubmitButton extends StatelessWidget {
  final bool isEditing;
  final bool loading;
  final VoidCallback onPressed;

  const PostSubmitButton({
    super.key,
    required this.isEditing,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      icon: loading
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(isEditing ? Icons.save_outlined : Icons.send_outlined),
      label: Text(isEditing ? 'Guardar cambios' : 'Publicar post'),
    );
  }
}
