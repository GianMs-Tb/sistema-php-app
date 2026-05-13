import 'package:cloud_firestore/cloud_firestore.dart';

/// Tipos de solicitud aceptados en la colección `pqrs`.
abstract class PqrsTipo {
  static const peticion = 'Petición';
  static const queja = 'Queja';
  static const reclamo = 'Reclamo';
  static const sugerencia = 'Sugerencia';

  static const todos = <String>[peticion, queja, reclamo, sugerencia];
}

/// Estados de una solicitud PQRS.
abstract class PqrsEstado {
  static const pendiente = 'Pendiente';
  static const resuelto = 'Resuelto';
}

/// Una entrada de la colección `pqrs`.
class Pqrs {
  final String id;
  final String residenteUid;
  final String residenteNombre;
  final String residenteEmail;
  final String tipo;
  final String descripcion;
  final String estado;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Pqrs({
    required this.id,
    required this.residenteUid,
    required this.residenteNombre,
    required this.residenteEmail,
    required this.tipo,
    required this.descripcion,
    this.estado = PqrsEstado.pendiente,
    this.createdAt,
    this.updatedAt,
  });

  bool get esPendiente => estado == PqrsEstado.pendiente;
  bool get esResuelto => estado == PqrsEstado.resuelto;

  Map<String, dynamic> toMap() => {
        'residenteUid': residenteUid,
        'residenteNombre': residenteNombre,
        'residenteEmail': residenteEmail,
        'tipo': tipo,
        'descripcion': descripcion,
        'estado': estado,
        'createdAt': createdAt == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(createdAt!),
        'updatedAt': updatedAt == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(updatedAt!),
      };

  factory Pqrs.fromMap(String id, Map<String, dynamic> map) {
    final rawTipo = (map['tipo'] as String?)?.trim();
    final tipo = (rawTipo != null && PqrsTipo.todos.contains(rawTipo))
        ? rawTipo
        : PqrsTipo.peticion;

    final rawEstado = (map['estado'] as String?)?.trim();
    final estado = (rawEstado == PqrsEstado.resuelto)
        ? PqrsEstado.resuelto
        : PqrsEstado.pendiente;

    return Pqrs(
      id: id,
      residenteUid: (map['residenteUid'] ?? '') as String,
      residenteNombre: (map['residenteNombre'] ?? '') as String,
      residenteEmail: (map['residenteEmail'] ?? '') as String,
      tipo: tipo,
      descripcion: (map['descripcion'] ?? '') as String,
      estado: estado,
      createdAt: _readDate(map['createdAt']),
      updatedAt: _readDate(map['updatedAt']),
    );
  }

  Pqrs copyWith({
    String? id,
    String? residenteUid,
    String? residenteNombre,
    String? residenteEmail,
    String? tipo,
    String? descripcion,
    String? estado,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Pqrs(
      id: id ?? this.id,
      residenteUid: residenteUid ?? this.residenteUid,
      residenteNombre: residenteNombre ?? this.residenteNombre,
      residenteEmail: residenteEmail ?? this.residenteEmail,
      tipo: tipo ?? this.tipo,
      descripcion: descripcion ?? this.descripcion,
      estado: estado ?? this.estado,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
