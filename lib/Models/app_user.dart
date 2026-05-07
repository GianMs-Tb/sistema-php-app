/// Rol almacenado en Firestore (`users.role`).
abstract class UserRoles {
  static const admin = 'admin';
  static const residente = 'residente';
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

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      email: map['email'] as String? ?? '',
      role: (map['role'] as String?)?.trim().toLowerCase() ?? UserRoles.residente,
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'role': role,
      };
}
