/// Saludo según la hora local del dispositivo.
String saludoSegunHora() {
  final hora = DateTime.now().hour;
  if (hora < 12) return 'Buenos días';
  if (hora < 19) return 'Buenas tardes';
  return 'Buenas noches';
}
