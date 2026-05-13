import 'package:cloud_firestore/cloud_firestore.dart';

/// Documento de la colección `comunicados` (feed del inicio).
class Comunicado {
  final String id;
  final String titulo;
  final String descripcion;
  final String autor;
  final String autorUid;
  final DateTime? createdAt;

  const Comunicado({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.autor,
    required this.autorUid,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'titulo': titulo,
        'descripcion': descripcion,
        'autor': autor,
        'autorUid': autorUid,
        'createdAt': createdAt == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(createdAt!),
      };

  factory Comunicado.fromMap(String id, Map<String, dynamic> map) {
    return Comunicado(
      id: id,
      titulo: (map['titulo'] ?? '') as String,
      descripcion: (map['descripcion'] ?? '') as String,
      autor: (map['autor'] ?? '') as String,
      autorUid: (map['autorUid'] ?? '') as String,
      createdAt: _readDate(map['createdAt']),
    );
  }

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
