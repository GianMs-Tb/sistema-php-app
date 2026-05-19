import 'package:cloud_firestore/cloud_firestore.dart';

import '../Models/reserva_model.dart';

/// CRUD de reservas en la colección `reservas`.
class FirebaseReservaRepository {
  FirebaseReservaRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('reservas');

  /// Todas las reservas del residente, ordenadas por fecha ascendente.
  Stream<List<Reserva>> streamReservasDeResidente(String uid) {
    return _col
        .where('residenteUid', isEqualTo: uid)
        .snapshots()
        .map((snap) {
      final lista = snap.docs
          .map((d) => Reserva.fromMap(d.id, d.data()))
          .toList()
        ..sort((a, b) => a.fecha.compareTo(b.fecha));
      return lista;
    });
  }

  /// Reservas futuras (incluyendo el día actual) del residente, en orden ascendente.
  Stream<List<Reserva>> streamReservasFuturasDeResidente(String uid) {
    final hoy = DateTime.now();
    final inicio = DateTime(hoy.year, hoy.month, hoy.day);
    return _col
        .where('residenteUid', isEqualTo: uid)
        .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
        .orderBy('fecha')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Reserva.fromMap(d.id, d.data())).toList());
  }

  /// Reservas globales (admin) ordenadas por fecha.
  Stream<List<Reserva>> streamTodas() {
    return _col.orderBy('fecha').snapshots().map((snap) {
      return snap.docs.map((d) => Reserva.fromMap(d.id, d.data())).toList();
    });
  }

  Future<String> crear(Reserva reserva) async {
    final doc = await _col.add(reserva.toMap());
    return doc.id;
  }

  Future<void> actualizar(Reserva reserva) async {
    await _col.doc(reserva.id).update(reserva.toMap());
  }

  Future<void> eliminar(String id) async {
    await _col.doc(id).delete();
  }

  Future<void> actualizarEstado(String id, String estado) async {
    await _col.doc(id).update({'estado': estado});
  }

  /// `true` si esa zona ya tiene una reserva **aprobada** en esa fecha.
  Future<bool> existeReservaEn({
    required DateTime fecha,
    required String zona,
  }) async {
    final inicio = DateTime(fecha.year, fecha.month, fecha.day);
    final fin = inicio.add(const Duration(days: 1));
    final snap = await _col
        .where('zona', isEqualTo: zona)
        .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
        .where('fecha', isLessThan: Timestamp.fromDate(fin))
        .get();
    return snap.docs.any((d) {
      final estado = d.data()['estado'] as String? ?? ReservaEstado.pendiente;
      return estado == ReservaEstado.aprobada;
    });
  }
}
