import 'package:cloud_firestore/cloud_firestore.dart';

/// Zonas comunes reservables.
abstract class ZonasComunes {
  static const piscina = 'Piscina';
  static const bbq = 'BBQ';
  static const salonSocial = 'Salón Social';

  static const todas = <String>[piscina, bbq, salonSocial];
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
  final DateTime? createdAt;

  const Reserva({
    required this.id,
    required this.residenteUid,
    required this.residenteNombre,
    required this.apartamento,
    required this.torre,
    required this.zona,
    required this.fecha,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'residenteUid': residenteUid,
        'residenteNombre': residenteNombre,
        'apartamento': apartamento,
        'torre': torre,
        'zona': zona,
        'fecha': Timestamp.fromDate(_atMidnight(fecha)),
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
