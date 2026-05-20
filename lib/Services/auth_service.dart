// Importa Firebase Authentication para manejar usuarios y sesiones.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../Models/app_user.dart';

// Servicio que encapsula toda la comunicacion con Firebase Authentication.
class AuthService {
  // Crea una referencia privada a la instancia global de FirebaseAuth.
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  // Expone un stream que avisa cuando el usuario inicia o cierra sesion.
  Stream<User?> get authState => _auth.authStateChanges();

  // Expone el usuario autenticado actual, o null si no hay sesion.
  User? get currentUser => _auth.currentUser;

  // Metodo para iniciar sesion usando correo y contrasena.
  Future<UserCredential> signInWithEmail({
    // Correo escrito por el usuario.
    required String email,

    // Contrasena escrita por el usuario.
    required String password,
  }) {
    // Llama a Firebase para validar credenciales y abrir sesion.
    return _auth.signInWithEmailAndPassword(
      // Envia el correo al servicio de Firebase.
      email: email,

      // Envia la contrasena al servicio de Firebase.
      password: password,
    );
  }

  // Metodo para registrar un usuario nuevo con correo, contrasena y nombre.
  Future<UserCredential> registerWithEmail({
    // Correo que se guardara como identificador de acceso.
    required String email,

    // Contrasena que Firebase validara con minimo 6 caracteres.
    required String password,

    // Nombre visible que se mostrara en posts y tarjeta de presentacion.
    required String displayName,
  }) async {
    // Crea el usuario en Firebase Authentication.
    final credential = await _auth.createUserWithEmailAndPassword(
      // Envia el correo al metodo de registro.
      email: email,

      // Envia la contrasena al metodo de registro.
      password: password,
    );

    // Elimina espacios al inicio y al final del nombre.
    final cleanName = displayName.trim();

    // Verifica que el estudiante haya escrito un nombre real.
    if (cleanName.isNotEmpty) {
      // Actualiza el perfil del usuario con el nombre visible.
      await credential.user?.updateDisplayName(cleanName);
    }

    // Recarga el usuario para que el displayName quede disponible de inmediato.
    await credential.user?.reload();

    final u = credential.user;
    if (u != null) {
      await _users.doc(u.uid).set(
            AppUser(
              uid: u.uid,
              email: email.trim(),
              role: UserRoles.residente,
              nombre: cleanName,
            ).toMap(),
          );
    }

    // Retorna la credencial por si la UI necesita consultar UID o email.
    return credential;
  }

  /// Crea el documento `users/{uid}` si no existe (usuarios antiguos u otros flujos).
  Future<void> ensureUserDocumentIfMissing(User user) async {
    final ref = _users.doc(user.uid);
    final snap = await ref.get();
    if (snap.exists) return;
    final nombre = user.displayName?.trim() ?? '';
    await ref.set(
      AppUser(
        uid: user.uid,
        email: user.email ?? '',
        role: UserRoles.residente,
        nombre: nombre,
      ).toMap(),
    );
  }

  // Metodo para cerrar la sesion activa.
  Future<void> signOut() {
    // Firebase borra la sesion local y notifica por authStateChanges().
    return _auth.signOut();
  }
}
