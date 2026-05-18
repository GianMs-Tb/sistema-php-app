import 'package:cloud_firestore/cloud_firestore.dart';

abstract class AlertaSosEstado {
  static const activa = 'Activa';
  static const atendida = 'Atendida';
}

class AlertaSos {
  final String id;
  final String residenteUid;
  final String nombreResidente;
  final String apartamento;
  final String torre;
  final String estado;
  final DateTime? fechaCreacion;

  const AlertaSos({
    required this.id,
    required this.residenteUid,
    required this.nombreResidente,
    required this.apartamento,
    required this.torre,
    required this.estado,
    this.fechaCreacion,
  });

  bool get esActiva => estado == AlertaSosEstado.activa;

  String get lineaEmergencia =>
      'Apto $apartamento, Torre $torre'.replaceAll('  ', ' ').trim();

  Map<String, dynamic> toMap() => {
        'residenteUid': residenteUid,
        'nombreResidente': nombreResidente,
        'apartamento': apartamento,
        'torre': torre,
        'estado': estado,
        'fechaCreacion': fechaCreacion == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(fechaCreacion!),
      };

  factory AlertaSos.fromMap(String id, Map<String, dynamic> map) {
    final raw = (map['estado'] as String?)?.trim();
    final estado = raw == AlertaSosEstado.atendida
        ? AlertaSosEstado.atendida
        : AlertaSosEstado.activa;

    return AlertaSos(
      id: id,
      residenteUid: (map['residenteUid'] ?? '') as String,
      nombreResidente: (map['nombreResidente'] ?? '') as String,
      apartamento: (map['apartamento'] ?? '') as String,
      torre: (map['torre'] ?? '') as String,
      estado: estado,
      fechaCreacion: _readDate(map['fechaCreacion']),
    );
  }

  static DateTime? _readDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }
}
