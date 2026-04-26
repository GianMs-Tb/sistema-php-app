import 'package:flutter/material.dart';

class ReservasScreen extends StatelessWidget {
const ReservasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservar Zonas', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Selecciona una etapa', style: TextStyle(fontSize: 16, color: Colors.grey)), // RF-01 y RF-02
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _construirFiltroEtapa('Todas', true),
                  _construirFiltroEtapa('Torre 1', false),
                  _construirFiltroEtapa('Torre 2', false),
                  _construirFiltroEtapa('Torre 3', false),
                  _construirFiltroEtapa('Zonas Comunes', false),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text('Espacios Disponibles', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 15),
            Expanded(
              child: ListView(
                children: [
                  _construirTarjetaReserva(
                    context,
                    'Piscina Climatizada',
                    'Capacidad: 15 personas',
                    'Disponible Hoy',
                    Icons.pool,
                    Colors.lightBlue,
                  ),
                  _construirTarjetaReserva(
                    context,
                    'Cancha Múltiple',
                    'Capacidad: 10 personas',
                    'Ocupada (Próx. disp: 4 PM)',
                    Icons.sports_tennis,
                    Colors.orange,
                    disponible: false, // RF-03
                  ),
                  _construirTarjetaReserva(
                    context,
                    'Salón Social VIP',
                    'Capacidad: 50 personas',
                    'Requiere depósito',
                    Icons.celebration,
                    Colors.purple,
                  ),
                  _construirTarjetaReserva(
                      context,
                      'Gimnasio',
                      'Capacidad: 20 personas',
                      'Disponible Hoy',
                      Icons.fitness_center,
                      Colors.green,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirFiltroEtapa(String texto, bool seleccionado) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: seleccionado ? const Color.fromARGB(255, 36, 63, 137) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: seleccionado ? Colors.transparent : Colors.grey.shade300),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: seleccionado ? Colors.white : Colors.grey.shade700,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _construirTarjetaReserva(BuildContext context, String titulo, String subtitulo, String estado, IconData icono, Color colorIcono, {bool disponible = true}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: colorIcono.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
              child: Icon(icono, color: colorIcono, size: 30),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 5),
                  Text(subtitulo, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 5),
                  Text(
                    estado,
                    style: TextStyle(color: disponible ? Colors.green : Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: disponible ? () {} : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: disponible ? const Color(0xFF3B82F6) : Colors.grey.shade300,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Reservar', style: TextStyle(color: disponible ? Colors.white : Colors.grey.shade600)),
            )
          ],
        ),
      ),
    );
  }
}
