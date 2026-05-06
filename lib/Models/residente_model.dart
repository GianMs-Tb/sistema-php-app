import 'package:cloud_firestore/cloud_firestore.dart';

class ResidenteModel {
  final String id;
  final String nombre;
  final String apartamento;
  final String torre;
  final double saldoPendiente;
  final DateTime fechaVencimiento;
  final int notificacionesSinLeer;

  const ResidenteModel({
    required this.id,
    required this.nombre,
    required this.apartamento,
    required this.torre,
    required this.saldoPendiente,
    required this.fechaVencimiento,
    this.notificacionesSinLeer = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'apartamento': apartamento,
      'torre': torre,
      'saldoPendiente': saldoPendiente,
      'fechaVencimiento': Timestamp.fromDate(fechaVencimiento),
      'notificacionesSinLeer': notificacionesSinLeer,
    };
  }

  factory ResidenteModel.fromMap(String id, Map<String, dynamic> map) {
    final fv = map['fechaVencimiento'];
    DateTime fecha;
    if (fv is Timestamp) {
      fecha = fv.toDate();
    } else if (fv is DateTime) {
      fecha = fv;
    } else {
      fecha = DateTime.now();
    }

    return ResidenteModel(
      id: id,
      nombre: map['nombre'] as String? ?? '',
      apartamento: map['apartamento'] as String? ?? '',
      torre: map['torre'] as String? ?? '',
      saldoPendiente: _asDouble(map['saldoPendiente']),
      fechaVencimiento: fecha,
      notificacionesSinLeer: _asInt(map['notificacionesSinLeer']),
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
  }) {
    return ResidenteModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      apartamento: apartamento ?? this.apartamento,
      torre: torre ?? this.torre,
      saldoPendiente: saldoPendiente ?? this.saldoPendiente,
      fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
      notificacionesSinLeer: notificacionesSinLeer ?? this.notificacionesSinLeer,
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
