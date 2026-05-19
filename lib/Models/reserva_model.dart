import 'package:cloud_firestore/cloud_firestore.dart';

/// Zonas comunes reservables.
abstract class ZonasComunes {
  static const piscina = 'Piscina';
  static const bbq = 'BBQ';
  static const salonSocial = 'Salón Social';
  static const cancha = 'Cancha';
  static const cine = 'Cine';

  /// Lista canónica usada por la UI de selección.
  static const todas = <String>[
    piscina,
    salonSocial,
    cancha,
    cine,
    bbq,
  ];
}

/// Estados de aprobación de una reserva.
abstract class ReservaEstado {
  static const pendiente = 'Pendiente';
  static const aprobada = 'Aprobada';
  static const rechazada = 'Rechazada';

  static const todos = [pendiente, aprobada, rechazada];
}

/// Una reserva guardada en Firestore (`reservas`).
class Reserva {
  final String id;
  final String residenteUid;
  final String residenteNombre;
  final String apartamento;
  final String torre;
  final String zona;
  final DateTime fecha;
  /// Hora de la reserva en formato 24h, ej. `16:00`.
  final String hora;
  final String estado;
  final DateTime? createdAt;

  const Reserva({
    required this.id,
    required this.residenteUid,
    required this.residenteNombre,
    required this.apartamento,
    required this.torre,
    required this.zona,
    required this.fecha,
    this.hora = '',
    this.estado = ReservaEstado.pendiente,
    this.createdAt,
  });

  bool get esPendiente => estado == ReservaEstado.pendiente;
  bool get esAprobada => estado == ReservaEstado.aprobada;
  bool get esRechazada => estado == ReservaEstado.rechazada;

  Map<String, dynamic> toMap() => {
        'residenteUid': residenteUid,
        'residenteNombre': residenteNombre,
        'apartamento': apartamento,
        'torre': torre,
        'zona': zona,
        'fecha': Timestamp.fromDate(_atMidnight(fecha)),
        'hora': hora,
        'estado': estado,
        'createdAt': createdAt == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(createdAt!),
      };

  factory Reserva.fromMap(String id, Map<String, dynamic> map) {
    final rawEstado = (map['estado'] ?? ReservaEstado.pendiente) as String;
    final estado = ReservaEstado.todos.contains(rawEstado)
        ? rawEstado
        : ReservaEstado.pendiente;

    return Reserva(
      id: id,
      residenteUid: (map['residenteUid'] ?? '') as String,
      residenteNombre: (map['residenteNombre'] ?? '') as String,
      apartamento: (map['apartamento'] ?? '') as String,
      torre: (map['torre'] ?? '') as String,
      zona: (map['zona'] ?? '') as String,
      fecha: _readDate(map['fecha']) ?? DateTime.now(),
      hora: (map['hora'] ?? '') as String,
      estado: estado,
      createdAt: _readDate(map['createdAt']),
    );
  }

  Reserva copyWith({
    String? id,
    String? residenteUid,
    String? residenteNombre,
    String? apartamento,
    String? torre,
    String? zona,
    DateTime? fecha,
    String? hora,
    String? estado,
    DateTime? createdAt,
  }) {
    return Reserva(
      id: id ?? this.id,
      residenteUid: residenteUid ?? this.residenteUid,
      residenteNombre: residenteNombre ?? this.residenteNombre,
      apartamento: apartamento ?? this.apartamento,
      torre: torre ?? this.torre,
      zona: zona ?? this.zona,
      fecha: fecha ?? this.fecha,
      hora: hora ?? this.hora,
      estado: estado ?? this.estado,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static DateTime _atMidnight(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
