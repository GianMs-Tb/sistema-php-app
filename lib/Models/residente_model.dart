import 'package:cloud_firestore/cloud_firestore.dart';

/// Estados disponibles para un documento de la colección `residentes`.
abstract class ResidenteStatus {
  static const active = 'active';
  static const inactive = 'inactive';
}

class ResidenteModel {
  final String id;
  final String nombre;
  final String apartamento;
  final String torre;
  final double saldoPendiente;
  final DateTime? fechaVencimiento;
  final int notificacionesSinLeer;

  /// Estado de la unidad: `'active'` o `'inactive'`.
  final String status;

  const ResidenteModel({
    required this.id,
    required this.nombre,
    required this.apartamento,
    required this.torre,
    this.saldoPendiente = 0,
    this.fechaVencimiento,
    this.notificacionesSinLeer = 0,
    this.status = ResidenteStatus.active,
  });

  bool get esActivo => status == ResidenteStatus.active;
  bool get esInactivo => status == ResidenteStatus.inactive;

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'apartamento': apartamento,
      'torre': torre,
      'saldoPendiente': saldoPendiente,
      'fechaVencimiento':
          fechaVencimiento == null ? null : Timestamp.fromDate(fechaVencimiento!),
      'notificacionesSinLeer': notificacionesSinLeer,
      'status': status,
    };
  }

  factory ResidenteModel.fromMap(String id, Map<String, dynamic> map) {
    final fv = map['fechaVencimiento'];
    DateTime? fecha;
    if (fv is Timestamp) {
      fecha = fv.toDate();
    } else if (fv is DateTime) {
      fecha = fv;
    }

    final rawStatus = (map['status'] as String?)?.trim().toLowerCase();
    final status = (rawStatus == ResidenteStatus.inactive)
        ? ResidenteStatus.inactive
        : ResidenteStatus.active;

    return ResidenteModel(
      id: id,
      nombre: map['nombre'] as String? ?? '',
      apartamento: map['apartamento'] as String? ?? '',
      torre: map['torre'] as String? ?? '',
      saldoPendiente: _asDouble(map['saldoPendiente']),
      fechaVencimiento: fecha,
      notificacionesSinLeer: _asInt(map['notificacionesSinLeer']),
      status: status,
    );
  }

  ResidenteModel copyWith({
    String? id,
    String? nombre,
    String? apartamento,
    String? torre,
    double? saldoPendiente,
    DateTime? fechaVencimiento,
    int? notificacionesSinLeer,
    String? status,
  }) {
    return ResidenteModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      apartamento: apartamento ?? this.apartamento,
      torre: torre ?? this.torre,
      saldoPendiente: saldoPendiente ?? this.saldoPendiente,
      fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
      notificacionesSinLeer: notificacionesSinLeer ?? this.notificacionesSinLeer,
      status: status ?? this.status,
    );
  }

  static double _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return 0;
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    return 0;
  }
}
