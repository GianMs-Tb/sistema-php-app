import 'package:flutter/material.dart';

/// Campo de descripción del formulario de publicación.
class PostDescriptionField extends StatelessWidget {
  final TextEditingController controller;

  const PostDescriptionField({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      minLines: 4,
      maxLines: 7,
      textInputAction: TextInputAction.newline,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: const Color(0xFF172033),
            height: 1.35,
          ),
      decoration: InputDecoration(
        labelText: 'Descripción',
        hintText: 'Escribe lo que quieres compartir...',
        prefixIcon: const Padding(
          padding: EdgeInsets.only(bottom: 78),
          child: Icon(Icons.notes_outlined),
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        alignLabelWithHint: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Color(0xFF2563EB),
            width: 1.6,
          ),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Escribe una descripción.';
        }
        return null;
      },
    );
  }
}
