import 'package:flutter/material.dart';

class DetallePageFirebase extends StatelessWidget {
  final String titulo;
  final String contenido;
  final String autor;

  const DetallePageFirebase({
    super.key,
    required this.titulo,
    required this.contenido,
    required this.autor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Anuncio'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Por: $autor',
              style: const TextStyle(fontSize: 14, color: Colors.grey, fontStyle: FontStyle.italic),
            ),
            const Divider(height: 30, thickness: 1),
            Text(
              contenido,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}