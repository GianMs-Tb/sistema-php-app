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
  final String nombre;
  final String apartamento;
  final String torre;

  const AppUser({
    required this.uid,
    required this.email,
    required this.role,
    this.nombre = '',
    this.apartamento = '',
    this.torre = '',
  });

  bool get isAdmin => role == UserRoles.admin;

  bool get isPortero => role == UserRoles.portero;

  bool get isResidente => role == UserRoles.residente;

  /// Nombre visible: Firestore → parte del email → "Usuario".
  String get nombreParaMostrar {
    if (nombre.trim().isNotEmpty) return nombre.trim();
    final mail = email.trim();
    if (mail.contains('@')) {
      final parte = mail.split('@').first.trim();
      if (parte.isNotEmpty) return parte;
    }
    return 'Usuario';
  }

  /// Badge de unidad solo para residentes con datos completos.
  bool get mostrarBadgeUnidad =>
      !isAdmin &&
      !isPortero &&
      apartamento.trim().isNotEmpty &&
      torre.trim().isNotEmpty;

  String get unidadCompleta => '${apartamento.trim()} - ${torre.trim()}';

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    final raw = (map['role'] as String?)?.trim().toLowerCase();
    final role = raw == UserRoles.admin ||
            raw == UserRoles.portero ||
            raw == UserRoles.residente
        ? raw!
        : UserRoles.residente;

    return AppUser(
      uid: uid,
      email: (map['email'] as String?)?.trim() ?? '',
      role: role,
      nombre: (map['nombre'] as String?)?.trim() ?? '',
      apartamento: (map['apartamento'] as String?)?.trim() ?? '',
      torre: (map['torre'] as String?)?.trim() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'role': role,
        'nombre': nombre,
        'apartamento': apartamento,
        'torre': torre,
      };

  AppUser copyWith({
    String? email,
    String? role,
    String? nombre,
    String? apartamento,
    String? torre,
  }) {
    return AppUser(
      uid: uid,
      email: email ?? this.email,
      role: role ?? this.role,
      nombre: nombre ?? this.nombre,
      apartamento: apartamento ?? this.apartamento,
      torre: torre ?? this.torre,
    );
  }
}
