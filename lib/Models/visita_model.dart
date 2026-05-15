import 'package:cloud_firestore/cloud_firestore.dart';

/// Estados de una visita en la colección `visitas`.
abstract class VisitaEstado {
  static const pendiente = 'Pendiente';
  static const ingreso = 'Ingresó';
}

class Visita {
  final String id;
  final String residenteUid;
  final String residenteNombre;
  final String nombreVisitante;
  final DateTime? fechaHoraEsperada;
  final String estado;
  final DateTime? fechaIngreso;
  final String apartamento;
  final String torre;

  const Visita({
    required this.id,
    required this.residenteUid,
    required this.residenteNombre,
    required this.nombreVisitante,
    this.fechaHoraEsperada,
    this.estado = VisitaEstado.pendiente,
    this.fechaIngreso,
    required this.apartamento,
    required this.torre,
  });

  bool get esPendiente => estado == VisitaEstado.pendiente;
  bool get yaIngreso => estado == VisitaEstado.ingreso;

  String get unidadDestino {
    final apt = apartamento.trim();
    final t = torre.trim();
    if (apt.isEmpty && t.isEmpty) return '—';
    if (t.isEmpty) return apt;
    if (apt.isEmpty) return t;
    return '$apt · $t';
  }

  Map<String, dynamic> toMap() => {
        'residenteUid': residenteUid,
        'residenteNombre': residenteNombre,
        'nombreVisitante': nombreVisitante,
        'fechaHoraEsperada': fechaHoraEsperada == null
            ? null
            : Timestamp.fromDate(fechaHoraEsperada!),
        'estado': estado,
        'fechaIngreso':
            fechaIngreso == null ? null : Timestamp.fromDate(fechaIngreso!),
        'apartamento': apartamento,
        'torre': torre,
      };

  factory Visita.fromMap(String id, Map<String, dynamic> map) {
    final rawEstado = (map['estado'] as String?)?.trim();
    final estado = (rawEstado == VisitaEstado.ingreso)
        ? VisitaEstado.ingreso
        : VisitaEstado.pendiente;

    return Visita(
      id: id,
      residenteUid: (map['residenteUid'] ?? '') as String,
      residenteNombre: (map['residenteNombre'] ?? '') as String,
      nombreVisitante: (map['nombreVisitante'] ?? '') as String,
      fechaHoraEsperada: _readDate(map['fechaHoraEsperada']),
      estado: estado,
      fechaIngreso: _readDate(map['fechaIngreso']),
      apartamento: (map['apartamento'] ?? '') as String,
      torre: (map['torre'] ?? '') as String,
    );
  }

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
