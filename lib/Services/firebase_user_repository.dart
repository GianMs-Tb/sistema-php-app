import 'package:cloud_firestore/cloud_firestore.dart';

import '../Models/app_user.dart';

/// Lectura y actualización del perfil en `users/{uid}`.
class FirebaseUserRepository {
  FirebaseUserRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _ref(String uid) =>
      _db.collection('users').doc(uid);

  Stream<AppUser> streamUsuario(String uid) {
    return _ref(uid).snapshots().map((snap) {
      return AppUser.fromMap(uid, snap.data() ?? {});
    });
  }

  Future<void> actualizarPerfil(
    String uid, {
    String? nombre,
    String? apartamento,
    String? torre,
  }) async {
    final data = <String, dynamic>{};
    if (nombre != null) data['nombre'] = nombre.trim();
    if (apartamento != null) data['apartamento'] = apartamento.trim();
    if (torre != null) data['torre'] = torre.trim();
    if (data.isEmpty) return;
    await _ref(uid).update(data);
  }
}
