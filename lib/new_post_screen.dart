// lib/new_post_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// Rutas corregidas apuntando a tu propia carpeta Services (con S mayúscula)
import 'Services/firebase_post_repository.dart';
import 'Services/image_base64.dart'; 

// Pantalla para crear un post guardando la imagen en base64 dentro de Firestore.
// Pasa la identidad del usuario al construirla.
class NewPostScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String userAvatar; // puede ser un URL o vacío

  const NewPostScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.userAvatar,
  });

  @override
  State<NewPostScreen> createState() => _NewPostScreenState();
}

class _NewPostScreenState extends State<NewPostScreen> {
  final _descCtrl = TextEditingController();
  final _picker = ImagePicker();

  XFile? _picked;
  Uint8List? _previewBytes;
  bool _submitting = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final x = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality:
            95, // solo afecta en móvil; en web usamos nuestro compresor
      );
      if (x == null) return;

      final bytes = await x.readAsBytes();
      setState(() {
        _picked = x;
        _previewBytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir la galería: $e')),
      );
    }
  }

  void _removeImage() {
    setState(() {
      _picked = null;
      _previewBytes = null;
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;

    final description = _descCtrl.text.trim();
    if (description.isEmpty && _picked == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe algo o selecciona una imagen.')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      String? imageBase64;
      if (_picked != null) {
        // Comprime + convierte a base64 (web y móvil)
        imageBase64 = await xfileToBase64(
          _picked!,
          maxWidth: 1024, // ajusta si necesitas documentos más pequeños
          quality: 70,
        );
      }

      await FirebasePostRepository().createPost(
        userId: widget.userId,
        userName: widget.userName,
        userAvatar: widget.userAvatar,
        description: description,
        imageBase64: imageBase64, // <- clave: guardamos el base64
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Publicado!')),
      );
      Navigator.of(context)
          .pop(true); // devuelve true para refrescar listas si quieres
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al publicar: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatar = widget.userAvatar;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo post'),
        actions: [
          TextButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Publicar'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Cabecera con avatar y nombre
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage:
                    (avatar.isNotEmpty) ? NetworkImage(avatar) : null,
                child: (avatar.isEmpty)
                    ? Text(widget.userName.isNotEmpty
                        ? widget.userName.characters.first.toUpperCase()
                        : '?')
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.userName,
                  style: theme.textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Descripción
          TextField(
            controller: _descCtrl,
            maxLines: 5,
            minLines: 3,
            decoration: const InputDecoration(
              labelText: '¿Qué quieres compartir?',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.newline,
          ),
          const SizedBox(height: 16),

          // Imagen seleccionada (preview) + acciones
          if (_previewBytes != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1.6, // evita saltos de layout
                    child: Image.memory(
                      _previewBytes!,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: IconButton.filled(
                      style: IconButton.styleFrom(
                        // Corregido el aviso azul de Deprecation
                        backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.85),
                      ),
                      onPressed: _submitting ? null : _removeImage,
                      icon: const Icon(Icons.close),
                      tooltip: 'Quitar imagen',
                    ),
                  ),
                ],
              ),
            ),

          if (_previewBytes == null)
            OutlinedButton.icon(
              onPressed: _submitting ? null : _pickImage,
              icon: const Icon(Icons.image_outlined),
              label: const Text('Seleccionar imagen'),
            )
          else
            TextButton.icon(
              onPressed: _submitting ? null : _pickImage,
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Cambiar imagen'),
            ),

          const SizedBox(height: 24),

          // Botón principal (útil en pantallas sin AppBar)
          FilledButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: _submitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            label: const Text('Publicar'),
          ),
        ],
      ),
    );
  }
}