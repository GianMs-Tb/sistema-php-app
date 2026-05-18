import 'package:cloud_firestore/cloud_firestore.dart';

import '../Models/alerta_sos_model.dart';

class FirebaseAlertaSosRepository {
  FirebaseAlertaSosRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('alertas_sos');

  Stream<List<AlertaSos>> streamActivas() {
    return _col
        .where('estado', isEqualTo: AlertaSosEstado.activa)
        .snapshots()
        .map((snap) {
      final lista =
          snap.docs.map((d) => AlertaSos.fromMap(d.id, d.data())).toList()
            ..sort((a, b) {
              final da = a.fechaCreacion ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              final db = b.fechaCreacion ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              return db.compareTo(da);
            });
      return lista;
    });
  }

  Future<String> crearActiva({
    required String residenteUid,
    required String nombreResidente,
    required String apartamento,
    required String torre,
  }) async {
    final doc = await _col.add({
      'residenteUid': residenteUid,
      'nombreResidente': nombreResidente.trim(),
      'apartamento': apartamento.trim(),
      'torre': torre.trim(),
      'estado': AlertaSosEstado.activa,
      'fechaCreacion': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> marcarAtendida(String id) async {
    await _col.doc(id).update({'estado': AlertaSosEstado.atendida});
  }
}
