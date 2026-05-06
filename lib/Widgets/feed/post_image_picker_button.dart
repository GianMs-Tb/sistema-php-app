import 'package:flutter/material.dart';

/// Botón para seleccionar o cambiar imagen en el formulario.
class PostImagePickerButton extends StatelessWidget {
  final bool hasImage;
  final bool loading;
  final VoidCallback onPressed;

  const PostImagePickerButton({
    super.key,
    required this.hasImage,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: loading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF2563EB),
        side: const BorderSide(color: Color(0xFFBFDBFE)),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      icon: Icon(hasImage ? Icons.swap_horiz : Icons.image_outlined),
      label: Text(hasImage ? 'Cambiar imagen' : 'Seleccionar imagen'),
    );
  }
}
