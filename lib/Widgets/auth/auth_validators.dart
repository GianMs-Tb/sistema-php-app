/// Valida que el nombre no esté vacío.
String? validateRequiredName(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Ingresa tu nombre.';
  }
  return null;
}

/// Valida un formato básico de correo electrónico.
String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) {
    return 'Ingresa tu correo.';
  }
  if (!email.contains('@') || !email.contains('.')) {
    return 'Ingresa un correo válido.';
  }
  return null;
}

/// Valida la longitud mínima requerida por Firebase Authentication.
String? validatePassword(String? value) {
  if (value == null || value.length < 6) {
    return 'La contraseña debe tener mínimo 6 caracteres.';
  }
  return null;
}
