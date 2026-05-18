import 'package:cloud_firestore/cloud_firestore.dart';

abstract class PaqueteEstado {
  static const enPorteria = 'En Portería';
  static const entregado = 'Entregado';
}

class Paquete {
  final String id;
  final String residenteUid;
  final String apartamento;
  final String torre;
  final String descripcion;
  final String estado;
  final DateTime? fechaRecepcion;
  final DateTime? fechaEntrega;

  const Paquete({
    required this.id,
    required this.residenteUid,
    required this.apartamento,
    required this.torre,
    required this.descripcion,
    required this.estado,
    this.fechaRecepcion,
    this.fechaEntrega,
  });

  bool get enPorteria => estado == PaqueteEstado.enPorteria;
  bool get entregado => estado == PaqueteEstado.entregado;

  String get unidad => '$apartamento · $torre'.trim();

  Map<String, dynamic> toMap() => {
        'residenteUid': residenteUid,
        'apartamento': apartamento,
        'torre': torre,
        'descripcion': descripcion,
        'estado': estado,
        'fechaRecepcion': fechaRecepcion == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(fechaRecepcion!),
        'fechaEntrega':
            fechaEntrega == null ? null : Timestamp.fromDate(fechaEntrega!),
      };

  factory Paquete.fromMap(String id, Map<String, dynamic> map) {
    final raw = (map['estado'] as String?)?.trim();
    final estado = raw == PaqueteEstado.entregado
        ? PaqueteEstado.entregado
        : PaqueteEstado.enPorteria;

    return Paquete(
      id: id,
      residenteUid: (map['residenteUid'] ?? '') as String,
      apartamento: (map['apartamento'] ?? '') as String,
      torre: (map['torre'] ?? '') as String,
      descripcion: (map['descripcion'] ?? '') as String,
      estado: estado,
      fechaRecepcion: _readDate(map['fechaRecepcion']),
      fechaEntrega: _readDate(map['fechaEntrega']),
    );
  }

  static DateTime? _readDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }
}
