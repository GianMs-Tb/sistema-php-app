// Importa base64Encode para convertir bytes en texto Base64.
import 'dart:convert';

// Importa Uint8List para manejar bytes de imagen en memoria.
import 'dart:typed_data';

// Importa el paquete image para decodificar, redimensionar y comprimir.
import 'package:image/image.dart' as img;

// Importa XFile, que es el tipo entregado por image_picker.
import 'package:image_picker/image_picker.dart';

// Convierte un XFile a Base64 cuidando el limite de tamano de Firestore.
Future<String> xfileToBase64(
  // Archivo seleccionado desde galeria o camara.
  XFile xfile, {
  // Ancho maximo recomendado para reducir peso sin perder demasiada calidad.
  int maxWidth = 900,

  // Calidad JPG inicial para comprimir la imagen.
  int quality = 68,

  // Tamano maximo aproximado del texto Base64 para no acercarse a 1 MiB.
  int maxBase64Length = 850000,
}) async {
  // Lee el archivo como bytes originales.
  final originalBytes = await xfile.readAsBytes();

  // Intenta decodificar los bytes como imagen.
  final decodedImage = img.decodeImage(originalBytes);

  // Si no se puede decodificar, retorna Base64 directo como respaldo.
  if (decodedImage == null) {
    // Convierte los bytes originales a texto Base64.
    return base64Encode(originalBytes);
  }

  // Calcula el ancho inicial respetando maxWidth.
  var targetWidth = decodedImage.width > maxWidth ? maxWidth : decodedImage.width;

  // Define la calidad inicial de compresion.
  var targetQuality = quality;

  // Guarda el ultimo resultado comprimido.
  Uint8List encodedBytes = Uint8List.fromList(originalBytes);

  // Realiza varios intentos para reducir la imagen si sigue pesada.
  for (var attempt = 0; attempt < 6; attempt++) {
    // Redimensiona la imagen si supera el ancho objetivo.
    final resizedImage = decodedImage.width > targetWidth
        // Crea una copia redimensionada.
        ? img.copyResize(decodedImage, width: targetWidth)
        // Usa la imagen original si ya es suficientemente pequena.
        : decodedImage;

    // Codifica la imagen como JPG con la calidad actual.
    encodedBytes = Uint8List.fromList(
      // encodeJpg comprime la imagen para reducir peso.
      img.encodeJpg(resizedImage, quality: targetQuality),
    );

    // Convierte los bytes comprimidos a Base64.
    final base64Value = base64Encode(encodedBytes);

    // Si el Base64 ya esta dentro del limite recomendado, lo retorna.
    if (base64Value.length <= maxBase64Length) {
      // Retorna la imagen comprimida en formato Base64.
      return base64Value;
    }

    // Reduce el ancho para el siguiente intento.
    targetWidth = (targetWidth * 0.82).round();

    // Reduce la calidad sin bajar de un minimo razonable.
    targetQuality = (targetQuality - 8).clamp(38, 95).toInt();
  }

  // Retorna el ultimo intento si no se logro bajar mas.
  return base64Encode(encodedBytes);
}
