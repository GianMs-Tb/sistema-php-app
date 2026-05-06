import 'package:flutter/material.dart';

class PostCard extends StatelessWidget {
  final String titulo;
  final String contenido;
  final String autor;
  final VoidCallback onTap;

  const PostCard({
    super.key,
    required this.titulo,
    required this.contenido,
    required this.autor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      elevation: 2,
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            Text(contenido, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 10),
            Text('Publicado por: $autor', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.blueAccent),
        onTap: onTap,
      ),
    );
  }
}