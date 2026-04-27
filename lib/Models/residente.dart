class Residente {
  final String nombre;
  final String apartamento;
  final String torre;
  final double saldoPendiente;
  final DateTime fechaVencimiento;
  final int notificacionesSinLeer;

  const Residente({
    required this.nombre,
    required this.apartamento,
    required this.torre,
    required this.saldoPendiente,
    required this.fechaVencimiento,
    this.notificacionesSinLeer = 0,
  });

  String get unidadCompleta => '$apartamento - $torre';

  String get saldoFormateado {
    final valor = saldoPendiente.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return '\$ $valor';
  }
}
