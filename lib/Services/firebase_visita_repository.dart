import 'package:cloud_firestore/cloud_firestore.dart';

import '../Models/visita_model.dart';

/// Operaciones sobre la colección `visitas`.
class FirebaseVisitaRepository {
  FirebaseVisitaRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('visitas');

  /// Crea una visita y devuelve el id del documento (dato del QR).
  Future<String> crear({
    required String residenteUid,
    required String residenteNombre,
    required String nombreVisitante,
    required DateTime fechaHoraEsperada,
    required String apartamento,
    required String torre,
  }) async {
    final doc = await _col.add({
      'residenteUid': residenteUid,
      'residenteNombre': residenteNombre.trim(),
      'nombreVisitante': nombreVisitante.trim(),
      'fechaHoraEsperada': Timestamp.fromDate(fechaHoraEsperada),
      'estado': VisitaEstado.pendiente,
      'fechaIngreso': null,
      'apartamento': apartamento.trim(),
      'torre': torre.trim(),
    });
    return doc.id;
  }

  Stream<List<Visita>> streamVisitasDeResidente(String uid) {
    return _col.where('residenteUid', isEqualTo: uid).snapshots().map((snap) {
      final lista =
          snap.docs.map((d) => Visita.fromMap(d.id, d.data())).toList()
            ..sort((a, b) {
              final da = a.fechaHoraEsperada ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              final db = b.fechaHoraEsperada ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              return db.compareTo(da);
            });
      return lista;
    });
  }

  Future<Visita?> obtenerPorId(String id) async {
    final snap = await _col.doc(id.trim()).get();
    if (!snap.exists || snap.data() == null) return null;
    return Visita.fromMap(snap.id, snap.data()!);
  }

  Future<void> permitirAcceso(String id) async {
    await _col.doc(id.trim()).update({
      'estado': VisitaEstado.ingreso,
      'fechaIngreso': FieldValue.serverTimestamp(),
    });
  }
}
