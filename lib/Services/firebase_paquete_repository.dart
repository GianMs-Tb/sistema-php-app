import 'package:cloud_firestore/cloud_firestore.dart';

import '../Models/paquete_model.dart';

class FirebasePaqueteRepository {
  FirebasePaqueteRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('paquetes');

  /// Paquetes en portería pendientes de entrega (vista portero).
  Stream<List<Paquete>> streamPendientesEnPorteria() {
    return _col
        .where('estado', isEqualTo: PaqueteEstado.enPorteria)
        .snapshots()
        .map((snap) {
      final lista =
          snap.docs.map((d) => Paquete.fromMap(d.id, d.data())).toList()
            ..sort((a, b) {
              final da = a.fechaRecepcion ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              final db = b.fechaRecepcion ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              return db.compareTo(da);
            });
      return lista;
    });
  }

  /// Paquetes en portería del residente (por Firebase Auth uid).
  /// Un solo `where` para no exigir índice compuesto; se filtra estado en cliente.
  Stream<List<Paquete>> streamPendientesPorResidente(String uid) {
    return _col.where('residenteUid', isEqualTo: uid).snapshots().map((snap) {
      final lista = snap.docs
          .map((d) => Paquete.fromMap(d.id, d.data()))
          .where((p) => p.enPorteria)
          .toList()
        ..sort((a, b) {
          final da =
              a.fechaRecepcion ?? DateTime.fromMillisecondsSinceEpoch(0);
          final db =
              b.fechaRecepcion ?? DateTime.fromMillisecondsSinceEpoch(0);
          return db.compareTo(da);
        });
      return lista;
    });
  }

  /// Resuelve el uid de Auth buscando por email en `users` (id del doc = uid).
  Future<String?> resolverUidPorEmail(String email) async {
    final e = email.trim().toLowerCase();
    if (e.isEmpty) return null;
    final q = await _db
        .collection('users')
        .where('email', isEqualTo: e)
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    return q.docs.first.id;
  }

  Future<String> crear({
    required String residenteUid,
    required String apartamento,
    required String torre,
    required String descripcion,
  }) async {
    final doc = await _col.add({
      'residenteUid': residenteUid,
      'apartamento': apartamento.trim(),
      'torre': torre.trim(),
      'descripcion': descripcion.trim(),
      'estado': PaqueteEstado.enPorteria,
      'fechaRecepcion': FieldValue.serverTimestamp(),
      'fechaEntrega': null,
    });
    return doc.id;
  }

  Future<void> marcarEntregado(String id) async {
    await _col.doc(id).update({
      'estado': PaqueteEstado.entregado,
      'fechaEntrega': FieldValue.serverTimestamp(),
    });
  }
}
