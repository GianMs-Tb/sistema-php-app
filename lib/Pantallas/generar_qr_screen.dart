import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../Widgets/glass_card.dart';
import '../theme/app_theme.dart';

/// Genera un QR con los datos del residente y permite descargarlo o compartirlo.
class GenerarQRScreen extends StatefulWidget {
  const GenerarQRScreen({
    super.key,
    required this.nombre,
    required this.apartamento,
    required this.torre,
  });

  final String nombre;
  final String apartamento;
  final String torre;

  @override
  State<GenerarQRScreen> createState() => _GenerarQRScreenState();
}

class _GenerarQRScreenState extends State<GenerarQRScreen> {
  static const double _qrPreviewSize = 240;
  static const double _qrExportSize = 600;

  bool _trabajando = false;

  String get _qrData {
    final user = FirebaseAuth.instance.currentUser;
    final payload = <String, dynamic>{
      'tipo': 'pase_residente',
      'uid': user?.uid ?? '',
      'email': user?.email ?? '',
      'nombre': widget.nombre,
      'apartamento': widget.apartamento,
      'torre': widget.torre,
      'generadoEn': DateTime.now().toIso8601String(),
    };
    return jsonEncode(payload);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.navy,
      appBar: AppBar(title: const Text('Pase de Visita')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Text(
                widget.nombre.isEmpty ? 'Residente' : widget.nombre,
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                _detalleUnidad(),
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Center(
                child: GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: QrImageView(
                    data: _qrData,
                    version: QrVersions.auto,
                    size: _qrPreviewSize,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: AppColors.mint,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Muestra este código en portería.\nLos datos viajan firmados con tu UID.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _trabajando ? null : _descargarQR,
                      icon: const Icon(Icons.download),
                      label: const Text('Descargar'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFF1E3A8A)),
                        foregroundColor: const Color(0xFF1E3A8A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _trabajando ? null : _compartirQR,
                      icon: _trabajando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.share),
                      label: const Text('Compartir'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  String _detalleUnidad() {
    final parts = <String>[
      if (widget.apartamento.isNotEmpty) widget.apartamento,
      if (widget.torre.isNotEmpty) widget.torre,
    ];
    return parts.isEmpty ? 'Pase digital' : parts.join(' · ');
  }

  Future<Uint8List?> _renderizarQR() async {
    final painter = QrPainter(
      data: _qrData,
      version: QrVersions.auto,
      gapless: true,
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: Color(0xFF1E3A8A),
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: Color(0xFF1E293B),
      ),
    );
    final byteData = await painter.toImageData(
      _qrExportSize,
      format: ui.ImageByteFormat.png,
    );
    return byteData?.buffer.asUint8List();
  }

  Future<File> _escribirArchivo(Directory dir, Uint8List bytes) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}${Platform.pathSeparator}pase_qr_$ts.png');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<Directory> _carpetaDescargas() async {
    try {
      final dir = await getDownloadsDirectory();
      if (dir != null) return dir;
    } catch (_) {
      // Algunas plataformas (Android < 10 o iOS) no exponen Downloads.
    }
    return getApplicationDocumentsDirectory();
  }

  Future<void> _descargarQR() async {
    setState(() => _trabajando = true);
    try {
      final bytes = await _renderizarQR();
      if (bytes == null) {
        _mostrarMensaje('No se pudo generar la imagen.');
        return;
      }
      final dir = await _carpetaDescargas();
      final file = await _escribirArchivo(dir, bytes);
      _mostrarMensaje('QR guardado en:\n${file.path}');
    } catch (e) {
      _mostrarMensaje('Error al descargar: $e');
    } finally {
      if (mounted) setState(() => _trabajando = false);
    }
  }

  Future<void> _compartirQR() async {
    setState(() => _trabajando = true);
    try {
      final bytes = await _renderizarQR();
      if (bytes == null) {
        _mostrarMensaje('No se pudo generar la imagen.');
        return;
      }
      final dir = await getTemporaryDirectory();
      final file = await _escribirArchivo(dir, bytes);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          text: 'Pase QR de ${widget.nombre} (${_detalleUnidad()})',
          subject: 'Pase de visita',
        ),
      );
    } catch (e) {
      _mostrarMensaje('Error al compartir: $e');
    } finally {
      if (mounted) setState(() => _trabajando = false);
    }
  }

  void _mostrarMensaje(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), duration: const Duration(seconds: 3)),
    );
  }
}
