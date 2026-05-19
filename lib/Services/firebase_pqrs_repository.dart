import 'package:cloud_firestore/cloud_firestore.dart';

import '../Models/pqrs_model.dart';

/// CRUD de solicitudes PQRS (colección `pqrs`).
class FirebasePqrsRepository {
  FirebasePqrsRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('pqrs');

  /// PQRS del residente actual, ordenadas por fecha descendente.
  Stream<List<Pqrs>> streamDeResidente(String uid) {
    return _col
        .where('residenteUid', isEqualTo: uid)
        .snapshots()
        .map((snap) {
      final lista = snap.docs.map((d) => Pqrs.fromMap(d.id, d.data())).toList()
        ..sort((a, b) {
          final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });
      return lista;
    });
  }

  /// Todas las PQRS del edificio (vista admin), sin filtrar por uid.
  /// Orden en cliente para no exigir índice compuesto ni fallar si falta `createdAt`.
  Stream<List<Pqrs>> streamTodas() {
    return _col.snapshots().map((snap) {
      final lista =
          snap.docs.map((d) => Pqrs.fromMap(d.id, d.data())).toList()
            ..sort((a, b) {
              final aDate = a.createdAt ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              final bDate = b.createdAt ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              return bDate.compareTo(aDate);
            });
      return lista;
    });
  }

  Future<String> crear(Pqrs pqrs) async {
    final doc = await _col.add(pqrs.toMap());
    return doc.id;
  }

  Future<void> marcarResuelta(String id) async {
    await _col.doc(id).update({
      'estado': PqrsEstado.resuelto,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> reabrir(String id) async {
    await _col.doc(id).update({
      'estado': PqrsEstado.pendiente,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> eliminar(String id) async {
    await _col.doc(id).delete();
  }
}
