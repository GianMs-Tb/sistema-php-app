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
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'residenteUid': residenteUid,
        'residenteNombre': residenteNombre,
        'apartamento': apartamento,
        'torre': torre,
        'zona': zona,
        'fecha': Timestamp.fromDate(_atMidnight(fecha)),
        'hora': hora,
        'createdAt': createdAt == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(createdAt!),
      };

  factory Reserva.fromMap(String id, Map<String, dynamic> map) {
    return Reserva(
      id: id,
      residenteUid: (map['residenteUid'] ?? '') as String,
      residenteNombre: (map['residenteNombre'] ?? '') as String,
      apartamento: (map['apartamento'] ?? '') as String,
      torre: (map['torre'] ?? '') as String,
      zona: (map['zona'] ?? '') as String,
      fecha: _readDate(map['fecha']) ?? DateTime.now(),
      hora: (map['hora'] ?? '') as String,
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
