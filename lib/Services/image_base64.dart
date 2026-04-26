// lib/services/image_base64.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

/// Convierte un XFile a base64 reduciendo tamaño para no pasar el 1MiB de Firestore.
/// - maxWidth: 1024 px (ajústalo)
/// - quality: 70 (0-100)
Future<String> xfileToBase64(
  XFile xfile, {
  int maxWidth = 1024,
  int quality = 70,
}) async {
  final bytes = await xfile.readAsBytes();

  // Intentamos decodificar como imagen
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    // Si no se pudo decodificar (caso raro), sube tal cual
    return base64Encode(bytes);
  }

  // Redimensiona si es más grande que maxWidth
  final resized = decoded.width > maxWidth
      ? img.copyResize(decoded, width: maxWidth)
      : decoded;

  // Exporta a JPG con compresión
  final jpgBytes = Uint8List.fromList(img.encodeJpg(resized, quality: quality));

  return base64Encode(jpgBytes);
}