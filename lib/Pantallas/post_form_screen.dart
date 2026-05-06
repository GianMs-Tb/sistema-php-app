// Importa herramientas para convertir texto Base64 a bytes.
import 'dart:convert';

// Importa Uint8List para mostrar imagenes en memoria.
import 'dart:typed_data';

// Importa el modelo Post usado cuando se edita una publicacion.
import 'package:flutter_application_1/Models/post.dart';

// Importa el repositorio que crea y actualiza posts en Firestore.
import 'package:flutter_application_1/Services/firebase_post_repository.dart';

// Importa el servicio que comprime y convierte imagenes a Base64.
import 'package:flutter_application_1/Services/image_base64.dart';

// Importa el AppBar visual del formulario.
import 'package:flutter_application_1/Widgets/feed/post_form_app_bar.dart';

// Importa el cuerpo visual completo del formulario.
import 'package:flutter_application_1/Widgets/feed/post_form_body.dart';

// Importa Material para construir la pantalla.
import 'package:flutter/material.dart';

// Importa image_picker para seleccionar imagenes desde la galeria.
import 'package:image_picker/image_picker.dart';

// Pantalla reutilizable para crear o editar publicaciones.
class PostFormScreen extends StatefulWidget {
  // Publicacion opcional: null significa crear, con valor significa editar.
  final Post? post;

  // UID del usuario autenticado.
  final String userId;

  // Nombre visible del usuario autenticado.
  final String userName;

  // Avatar del usuario autenticado.
  final String userAvatar;

  // Constructor con datos requeridos del usuario y post opcional.
  const PostFormScreen({
    // Key opcional para identificar el widget.
    super.key,

    // Post que se edita, si existe.
    this.post,

    // UID requerido para asociar el post al usuario.
    required this.userId,

    // Nombre requerido para mostrar autor.
    required this.userName,

    // Avatar requerido, puede ser cadena vacia.
    required this.userAvatar,
  });

  // Retorna true cuando el formulario esta editando un post existente.
  bool get isEditing => post != null;

  // Crea el estado mutable del formulario.
  @override
  State<PostFormScreen> createState() => _PostFormScreenState();
}

// Estado privado de PostFormScreen.
class _PostFormScreenState extends State<PostFormScreen> {
  // Llave que permite validar los campos del formulario.
  final _formKey = GlobalKey<FormState>();

  // Controlador del campo de descripcion.
  final _descriptionController = TextEditingController();

  // Instancia para abrir galeria y seleccionar imagen.
  final _picker = ImagePicker();

  // Repositorio encargado de guardar cambios en Firestore.
  final _repository = FirebasePostRepository();

  // Imagen seleccionada en esta sesion del formulario.
  XFile? _pickedImage;

  // Bytes usados para previsualizar la imagen seleccionada o existente.
  Uint8List? _previewBytes;

  // Base64 actual del post cuando se esta editando.
  String? _currentImageBase64;

  // Indica si se esta guardando para bloquear doble envio.
  bool _saving = false;

  // Inicializa el estado del formulario.
  @override
  void initState() {
    // Ejecuta la inicializacion base de StatefulWidget.
    super.initState();

    // Si se edita, carga la descripcion existente; si no, deja vacio.
    _descriptionController.text = widget.post?.description ?? '';

    // Conserva la imagen Base64 existente si el post ya tenia imagen.
    _currentImageBase64 = widget.post?.imageBase64;

    // Convierte la imagen Base64 existente a bytes para previsualizarla.
    _previewBytes = _decodeBase64(_currentImageBase64);
  }

  // Libera recursos cuando la pantalla sale de memoria.
  @override
  void dispose() {
    // Libera el controlador de texto.
    _descriptionController.dispose();

    // Ejecuta el dispose base del framework.
    super.dispose();
  }

  // Abre la galeria para seleccionar una imagen.
  Future<void> _pickImage() async {
    // Captura errores de permisos o selector de imagen.
    try {
      // Abre la galeria del dispositivo.
      final image = await _picker.pickImage(
        // Define que la fuente sera la galeria.
        source: ImageSource.gallery,

        // Solicita compresion inicial del plugin.
        imageQuality: 90,
      );

      // Si el usuario cancela, no se cambia el estado.
      if (image == null) return;

      // Lee los bytes para mostrar previsualizacion.
      final bytes = await image.readAsBytes();

      // Actualiza el estado con la nueva imagen.
      setState(() {
        // Guarda el archivo seleccionado.
        _pickedImage = image;

        // Guarda los bytes para preview.
        _previewBytes = bytes;

        // Limpia el Base64 anterior porque ahora hay imagen nueva.
        _currentImageBase64 = null;
      });
    } catch (error) {
      // Muestra error si no se pudo seleccionar imagen.
      _showMessage('No se pudo seleccionar la imagen: $error');
    }
  }

  // Quita la imagen actual del formulario.
  void _removeImage() {
    // Actualiza el estado para eliminar imagen nueva y existente.
    setState(() {
      // Elimina referencia al archivo seleccionado.
      _pickedImage = null;

      // Elimina bytes de previsualizacion.
      _previewBytes = null;

      // Elimina Base64 existente para guardar el post sin imagen.
      _currentImageBase64 = null;
    });
  }

  // Guarda el post nuevo o los cambios del post existente.
  Future<void> _savePost() async {
    // Si ya se esta guardando o el formulario no valida, no continua.
    if (_saving || !_formKey.currentState!.validate()) return;

    // Activa estado de carga.
    setState(() => _saving = true);

    // Captura errores de conversion, red o Firestore.
    try {
      // Decide que imagen Base64 se debe guardar.
      final imageBase64 = await _resolveImageBase64();

      // Si esta editando, actualiza; si no, crea.
      widget.isEditing
          // Actualiza el documento existente.
          ? await _updatePost(imageBase64)
          // Crea un documento nuevo.
          : await _createPost(imageBase64);

      // Evita usar context si la pantalla ya no existe.
      if (!mounted) return;

      // Muestra mensaje de exito segun el modo.
      _showMessage(
        // Texto para modo editar.
        widget.isEditing
            ? 'Publicacion actualizada.'
            // Texto para modo crear.
            : 'Publicacion creada.',
      );

      // Vuelve al feed.
      Navigator.pop(context);
    } catch (error) {
      // Muestra error si algo falla al guardar.
      _showMessage('No se pudo guardar la publicacion: $error');
    } finally {
      // Si el widget sigue vivo, apaga el estado de carga.
      if (mounted) setState(() => _saving = false);
    }
  }

  // Crea un post nuevo en Firestore.
  Future<void> _createPost(String? imageBase64) {
    // Llama al repositorio con los datos del usuario y formulario.
    return _repository.createPost(
      // UID del usuario autenticado.
      userId: widget.userId,

      // Nombre visible del autor.
      userName: widget.userName,

      // Avatar del autor.
      userAvatar: widget.userAvatar,

      // Descripcion limpia sin espacios sobrantes.
      description: _descriptionController.text.trim(),

      // Imagen Base64 ya comprimida o null.
      imageBase64: imageBase64,
    );
  }

  // Actualiza un post existente en Firestore.
  Future<void> _updatePost(String? imageBase64) {
    // Llama al repositorio para modificar el documento existente.
    return _repository.updatePost(
      // Id del documento que se esta editando.
      postId: widget.post!.id,

      // Nueva descripcion limpia.
      description: _descriptionController.text.trim(),

      // Nueva imagen Base64 o null.
      imageBase64: imageBase64,
    );
  }

  // Decide si usar imagen nueva, imagen existente o null.
  Future<String?> _resolveImageBase64() {
    // Si no se selecciono una imagen nueva, conserva la actual.
    if (_pickedImage == null) {
      // Retorna el Base64 existente o null si no hay imagen.
      return Future.value(_currentImageBase64);
    }

    // Si hay imagen nueva, la comprime y convierte a Base64.
    return xfileToBase64(
      // Archivo seleccionado por image_picker.
      _pickedImage!,

      // Ancho maximo para reducir peso del documento.
      maxWidth: 900,

      // Calidad JPG para equilibrar peso y apariencia.
      quality: 68,
    );
  }

  // Decodifica Base64 a bytes para previsualizar una imagen existente.
  Uint8List? _decodeBase64(String? value) {
    // Si no hay valor, no hay imagen para mostrar.
    if (value == null || value.isEmpty) return null;

    // Captura errores si el Base64 esta corrupto.
    try {
      // Convierte texto Base64 a arreglo de bytes.
      return base64Decode(value);
    } catch (_) {
      // Si falla la conversion, oculta la imagen.
      return null;
    }
  }

  // Muestra mensajes breves al usuario.
  void _showMessage(String message) {
    // Evita usar context si el widget ya no esta montado.
    if (!mounted) return;

    // Muestra el mensaje en un SnackBar.
    ScaffoldMessenger.of(context).showSnackBar(
      // Contenido textual del SnackBar.
      SnackBar(content: Text(message)),
    );
  }

  // Construye la pantalla del formulario.
  @override
  Widget build(BuildContext context) {
    // Scaffold define appBar y body del formulario.
    return Scaffold(
      // AppBar personalizado para crear o editar.
      appBar: PostFormAppBar(
        // Indica si el titulo y boton deben decir editar/guardar.
        isEditing: widget.isEditing,

        // Indica si se debe mostrar estado de carga.
        loading: _saving,

        // Accion que guarda el formulario.
        onSave: _savePost,
      ),

      // Fondo visual del formulario.
      body: DecoratedBox(
        // Decoracion de fondo con gradiente suave.
        decoration: const BoxDecoration(
          // Gradiente vertical para mantener coherencia con el feed.
          gradient: LinearGradient(
            // Colores del fondo.
            colors: [
              // Fondo principal claro.
              Color(0xFFF4F7FB),

              // Azul claro intermedio.
              Color(0xFFEFF6FF),

              // Fondo final casi blanco.
              Color(0xFFF8FAFC),
            ],

            // Punto inicial del gradiente.
            begin: Alignment.topCenter,

            // Punto final del gradiente.
            end: Alignment.bottomCenter,
          ),
        ),

        // Cuerpo visual separado en widgets reutilizables.
        child: PostFormBody(
          // Llave para validar el formulario.
          formKey: _formKey,

          // Controlador del campo descripcion.
          descriptionController: _descriptionController,

          // Nombre del autor.
          userName: widget.userName,

          // Avatar del autor.
          userAvatar: widget.userAvatar,

          // Bytes de la imagen para previsualizacion.
          previewBytes: _previewBytes,

          // Indica si esta creando o editando.
          isEditing: widget.isEditing,

          // Indica si se esta guardando.
          loading: _saving,

          // Accion para abrir la galeria.
          onPickImage: _pickImage,

          // Accion para quitar imagen.
          onRemoveImage: _removeImage,

          // Accion para guardar.
          onSave: _savePost,
        ),
      ),
    );
  }
}
