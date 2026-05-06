// Importa Uint8List para recibir bytes de la imagen seleccionada.
import 'dart:typed_data';

// Importa el campo de texto de descripcion del post.
import 'package:flutter_application_1/Widgets/feed/post_description_field.dart';

// Importa la cabecera que muestra el autor del post.
import 'package:flutter_application_1/Widgets/feed/post_form_author_header.dart';

// Importa el boton para seleccionar o cambiar imagen.
import 'package:flutter_application_1/Widgets/feed/post_image_picker_button.dart';

// Importa la previsualizacion de imagen seleccionada.
import 'package:flutter_application_1/Widgets/feed/post_image_preview.dart';

// Importa el boton principal de publicar o guardar.
import 'package:flutter_application_1/Widgets/feed/post_submit_button.dart';

// Importa Material para construir la interfaz.
import 'package:flutter/material.dart';

// Cuerpo visual completo del formulario de publicaciones.
class PostFormBody extends StatelessWidget {
  // Llave usada para validar todos los campos del formulario.
  final GlobalKey<FormState> formKey;

  // Controlador del texto escrito en la descripcion.
  final TextEditingController descriptionController;

  // Nombre del usuario autenticado que aparece como autor.
  final String userName;

  // URL del avatar del usuario autenticado.
  final String userAvatar;

  // Bytes de la imagen seleccionada o existente.
  final Uint8List? previewBytes;

  // Indica si el formulario esta en modo editar.
  final bool isEditing;

  // Indica si el formulario esta guardando datos.
  final bool loading;

  // Accion para abrir la galeria.
  final VoidCallback onPickImage;

  // Accion para quitar la imagen actual.
  final VoidCallback onRemoveImage;

  // Accion para crear o guardar cambios.
  final VoidCallback onSave;

  // Constructor que recibe todos los datos y acciones desde la pantalla.
  const PostFormBody({
    // Key opcional para identificar el widget.
    super.key,

    // Recibe la llave de validacion del formulario.
    required this.formKey,

    // Recibe el controlador de descripcion.
    required this.descriptionController,

    // Recibe el nombre del autor.
    required this.userName,

    // Recibe el avatar del autor.
    required this.userAvatar,

    // Recibe los bytes de imagen para preview.
    required this.previewBytes,

    // Recibe si esta en modo editar.
    required this.isEditing,

    // Recibe si esta cargando.
    required this.loading,

    // Recibe la accion de seleccionar imagen.
    required this.onPickImage,

    // Recibe la accion de quitar imagen.
    required this.onRemoveImage,

    // Recibe la accion de guardar.
    required this.onSave,
  });

  // Construye el cuerpo visual del formulario.
  @override
  Widget build(BuildContext context) {
    // SafeArea evita que el contenido choque con barras del sistema.
    return SafeArea(
      // Form permite validar los campos usando formKey.
      child: Form(
        // Asocia la llave de validacion al formulario.
        key: formKey,

        // ListView permite desplazamiento si la pantalla es pequena.
        child: ListView(
          // Padding separa el formulario de los bordes.
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),

          // Lista vertical de componentes del formulario.
          children: [
            // Banner superior que explica si se crea o edita.
            _FormHero(isEditing: isEditing),

            // Espacio entre banner y tarjeta principal.
            const SizedBox(height: 14),

            // Tarjeta principal que agrupa autor, texto e imagen.
            _ComposerCard(
              // Widgets internos de la tarjeta.
              children: [
                // Muestra el autor autenticado.
                PostFormAuthorHeader(
                  // Nombre del autor.
                  userName: userName,

                  // Avatar del autor.
                  userAvatar: userAvatar,
                ),

                // Espacio entre autor y descripcion.
                const SizedBox(height: 18),

                // Campo para escribir la descripcion.
                PostDescriptionField(controller: descriptionController),

                // Espacio entre descripcion e imagen.
                const SizedBox(height: 18),

                // Si no hay imagen, muestra placeholder.
                if (previewBytes == null)
                  // Placeholder clicable para agregar imagen.
                  _ImagePlaceholder(onPickImage: loading ? null : onPickImage)
                // Si hay imagen, muestra previsualizacion.
                else
                  // Preview con boton para quitar imagen.
                  PostImagePreview(
                    // Bytes de la imagen.
                    bytes: previewBytes!,

                    // Deshabilita quitar imagen mientras guarda.
                    onRemove: loading ? null : onRemoveImage,
                  ),

                // Espacio entre imagen y boton de imagen.
                const SizedBox(height: 14),

                // Boton para seleccionar o cambiar imagen.
                PostImagePickerButton(
                  // Indica si ya hay imagen.
                  hasImage: previewBytes != null,

                  // Bloquea el boton si esta guardando.
                  loading: loading,

                  // Accion para abrir galeria.
                  onPressed: onPickImage,
                ),
              ],
            ),

            // Espacio entre tarjeta y boton principal.
            const SizedBox(height: 18),

            // Boton principal para publicar o guardar cambios.
            PostSubmitButton(
              // Cambia el texto si esta editando.
              isEditing: isEditing,

              // Muestra carga si esta guardando.
              loading: loading,

              // Accion de guardar.
              onPressed: onSave,
            ),
          ],
        ),
      ),
    );
  }
}

// Banner informativo superior del formulario.
class _FormHero extends StatelessWidget {
  // Indica si el formulario esta editando.
  final bool isEditing;

  // Constructor que recibe el modo del formulario.
  const _FormHero({required this.isEditing});

  // Construye el banner visual.
  @override
  Widget build(BuildContext context) {
    // Container permite fondo, bordes y sombra.
    return Container(
      // Espacio interno del banner.
      padding: const EdgeInsets.all(18),

      // Decoracion visual del banner.
      decoration: BoxDecoration(
        // Bordes redondeados.
        borderRadius: BorderRadius.circular(22),

        // Gradiente principal del banner.
        gradient: const LinearGradient(
          // Colores del gradiente.
          colors: [
            // Azul principal.
            Color(0xFF2563EB),

            // Verde secundario.
            Color(0xFF14B8A6),
          ],

          // Inicio del gradiente.
          begin: Alignment.topLeft,

          // Fin del gradiente.
          end: Alignment.bottomRight,
        ),

        // Sombra para levantar el banner del fondo.
        boxShadow: const [
          // Sombra azul suave.
          BoxShadow(
            // Color con transparencia.
            color: Color(0x332563EB),

            // Difuminado de sombra.
            blurRadius: 18,

            // Desplazamiento vertical.
            offset: Offset(0, 8),
          ),
        ],
      ),

      // Row organiza icono y texto horizontalmente.
      child: Row(
        // Elementos internos del banner.
        children: [
          // Caja visual para el icono.
          Container(
            // Ancho del contenedor.
            width: 48,

            // Alto del contenedor.
            height: 48,

            // Decoracion del contenedor del icono.
            decoration: BoxDecoration(
              // Fondo blanco semitransparente.
              color: Colors.white.withOpacity(0.18),

              // Bordes redondeados del icono.
              borderRadius: BorderRadius.circular(14),

              // Borde sutil sobre el gradiente.
              border: Border.all(color: Colors.white24),
            ),

            // Icono segun crear o editar.
            child: Icon(
              // Si edita muestra icono de edicion; si crea, icono de imagen.
              isEditing ? Icons.edit_note : Icons.add_photo_alternate_outlined,

              // Color blanco para contraste.
              color: Colors.white,
            ),
          ),

          // Espacio entre icono y texto.
          const SizedBox(width: 14),

          // Expanded permite que el texto use el espacio disponible.
          Expanded(
            // Column organiza titulo y subtitulo.
            child: Column(
              // Alinea textos a la izquierda.
              crossAxisAlignment: CrossAxisAlignment.start,

              // Hijos de la columna.
              children: [
                // Titulo del banner.
                Text(
                  // Texto cambia segun crear o editar.
                  isEditing ? 'Actualiza tu publicacion' : 'Crea una publicacion',

                  // Estilo del titulo.
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        // Texto blanco.
                        color: Colors.white,

                        // Peso fuerte para jerarquia.
                        fontWeight: FontWeight.w800,
                      ),
                ),

                // Espacio entre titulo y subtitulo.
                const SizedBox(height: 4),

                // Subtitulo del banner.
                Text(
                  // Mensaje segun el modo.
                  isEditing
                      ? 'Ajusta el texto o cambia la imagen.'
                      : 'Comparte una idea con imagen en Base64.',

                  // Estilo del subtitulo.
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        // Blanco con transparencia para menor jerarquia.
                        color: Colors.white.withOpacity(0.86),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Tarjeta principal del editor.
class _ComposerCard extends StatelessWidget {
  // Widgets que se mostraran dentro de la tarjeta.
  final List<Widget> children;

  // Constructor que recibe los hijos de la tarjeta.
  const _ComposerCard({required this.children});

  // Construye la tarjeta visual.
  @override
  Widget build(BuildContext context) {
    // Container permite aplicar borde, sombra y fondo.
    return Container(
      // Espacio interno de la tarjeta.
      padding: const EdgeInsets.all(16),

      // Decoracion de la tarjeta.
      decoration: BoxDecoration(
        // Fondo blanco para contraste con el fondo azul suave.
        color: Colors.white,

        // Bordes redondeados.
        borderRadius: BorderRadius.circular(22),

        // Borde gris claro.
        border: Border.all(color: const Color(0xFFE2E8F0)),

        // Sombra muy suave.
        boxShadow: const [
          // Sombra gris transparente.
          BoxShadow(
            // Color de sombra.
            color: Color(0x120F172A),

            // Difuminado.
            blurRadius: 18,

            // Desplazamiento vertical.
            offset: Offset(0, 8),
          ),
        ],
      ),

      // Column organiza los hijos de arriba hacia abajo.
      child: Column(
        // Estira hijos al ancho disponible.
        crossAxisAlignment: CrossAxisAlignment.stretch,

        // Renderiza los widgets recibidos.
        children: children,
      ),
    );
  }
}

// Placeholder que aparece cuando no hay imagen seleccionada.
class _ImagePlaceholder extends StatelessWidget {
  // Accion que abre la galeria.
  final VoidCallback? onPickImage;

  // Constructor que recibe la accion opcional.
  const _ImagePlaceholder({required this.onPickImage});

  // Construye el placeholder clicable.
  @override
  Widget build(BuildContext context) {
    // InkWell permite detectar toques con efecto Material.
    return InkWell(
      // Bordes del efecto de toque.
      borderRadius: BorderRadius.circular(18),

      // Accion al tocar el placeholder.
      onTap: onPickImage,

      // Container define tamano y estilo del placeholder.
      child: Container(
        // Alto fijo del area de imagen.
        height: 190,

        // Decoracion del area vacia.
        decoration: BoxDecoration(
          // Fondo gris muy claro.
          color: const Color(0xFFF8FAFC),

          // Bordes redondeados.
          borderRadius: BorderRadius.circular(18),

          // Borde para delimitar el area.
          border: Border.all(
            // Color gris azulado.
            color: const Color(0xFFCBD5E1),

            // Grosor del borde.
            width: 1.2,
          ),
        ),

        // Column centra icono y textos.
        child: Column(
          // Centra verticalmente.
          mainAxisAlignment: MainAxisAlignment.center,

          // Hijos del placeholder.
          children: [
            // Caja decorativa del icono.
            Container(
              // Ancho de la caja.
              width: 58,

              // Alto de la caja.
              height: 58,

              // Decoracion de la caja.
              decoration: BoxDecoration(
                // Azul muy claro.
                color: const Color(0xFFEFF6FF),

                // Bordes redondeados.
                borderRadius: BorderRadius.circular(18),
              ),

              // Icono de agregar imagen.
              child: const Icon(
                // Icono representativo de imagen.
                Icons.add_photo_alternate_outlined,

                // Color azul principal.
                color: Color(0xFF2563EB),

                // Tamano del icono.
                size: 32,
              ),
            ),

            // Espacio entre icono y titulo.
            const SizedBox(height: 12),

            // Texto principal del placeholder.
            Text(
              // Mensaje de accion.
              'Agrega una imagen',

              // Estilo del texto.
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    // Color oscuro.
                    color: const Color(0xFF172033),

                    // Peso fuerte.
                    fontWeight: FontWeight.w800,
                  ),
            ),

            // Espacio entre titulo y descripcion.
            const SizedBox(height: 4),

            // Texto secundario del placeholder.
            Text(
              // Explica que se guardara en Base64.
              'Se comprimira y guardara como Base64.',

              // Estilo del texto secundario.
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    // Gris para menor jerarquia.
                    color: const Color(0xFF64748B),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
