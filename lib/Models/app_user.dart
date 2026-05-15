/// Rol almacenado en Firestore (`users.role`).
abstract class UserRoles {
  static const admin = 'admin';
  static const residente = 'residente';
  static const portero = 'portero';
}

/// Perfil de usuario en la colección `users`.
class AppUser {
  final String uid;
  final String email;
  final String role;

  const AppUser({
    required this.uid,
    required this.email,
    required this.role,
  });

  bool get isAdmin => role == UserRoles.admin;

  bool get isPortero => role == UserRoles.portero;

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    final raw = (map['role'] as String?)?.trim().toLowerCase();
    final role = raw == UserRoles.admin ||
            raw == UserRoles.portero ||
            raw == UserRoles.residente
        ? raw!
        : UserRoles.residente;

    return AppUser(
      uid: uid,
      email: map['email'] as String? ?? '',
      role: role,
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'role': role,
      };
}
