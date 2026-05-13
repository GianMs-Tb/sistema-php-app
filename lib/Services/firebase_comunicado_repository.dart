import 'package:cloud_firestore/cloud_firestore.dart';

import '../Models/comunicado_model.dart';

/// CRUD del feed de comunicados (`comunicados`).
class FirebaseComunicadoRepository {
  FirebaseComunicadoRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('comunicados');

  /// Stream de comunicados ordenados por `createdAt` descendente.
  Stream<List<Comunicado>> stream({int limit = 30}) {
    return _col
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Comunicado.fromMap(d.id, d.data())).toList());
  }

  Future<String> crear(Comunicado c) async {
    final doc = await _col.add(c.toMap());
    return doc.id;
  }

  Future<void> eliminar(String id) async {
    await _col.doc(id).delete();
  }
}
