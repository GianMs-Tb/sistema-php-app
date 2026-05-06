import 'package:cloud_firestore/cloud_firestore.dart';

import '../Models/residente_model.dart';

class FirebaseResidenteRepository {
  FirebaseResidenteRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('residentes');

  /// Lista en tiempo real ordenada por nombre.
  Stream<List<ResidenteModel>> streamResidentes() {
    return _col.orderBy('nombre').snapshots().map((snapshot) {
      return snapshot.docs
          .map((d) => ResidenteModel.fromMap(d.id, d.data()))
          .toList();
    });
  }

  Future<String> crear(ResidenteModel residente) async {
    final doc = await _col.add(residente.toMap());
    return doc.id;
  }

  Future<void> actualizar(ResidenteModel residente) async {
    await _col.doc(residente.id).update(residente.toMap());
  }

  Future<void> eliminar(String id) async {
    await _col.doc(id).delete();
  }
}
