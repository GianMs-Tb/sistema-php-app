import 'package:flutter/material.dart';
import '../Models/residente.dart';
import 'admin_residentes_screen.dart';

class InicioScreen extends StatelessWidget {
  const InicioScreen({super.key});

  // Dato temporal: reemplazar por Provider/Bloc cuando conectemos Firebase
  static final Residente _residente = Residente(
    nombre: 'Santiago',
    apartamento: 'Apto 502',
    torre: 'Torre 1',
    saldoPendiente: 150000,
    fechaVencimiento: DateTime(2026, 4, 15),
    notificacionesSinLeer: 2,
  );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              _construirFondoHeader(context),
              Positioned(
                top: 130,
                child: _construirTarjetaSaldo(),
              ),
            ],
          ),

          // 1. EL SALVAVIDAS: Este espacio evita que la tarjeta aplaste a Gestión Digital
          const SizedBox(height: 150),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'Gestión Digital',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                ),

                // 2. Espacio perfecto entre el título y los botones
                const SizedBox(height: 10),

                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 1.3,
                  children: [
                    _construirBotonGrid(context, Icons.sports_tennis, 'Reservas', 'Zonas comunes', const Color(0xFF3B82F6), null),
                    _construirBotonGrid(context, Icons.qr_code_scanner, 'Pase Visitas', 'Generar QR', const Color(0xFF10B981), () {
                      _mostrarVentanaQR(context);
                    }),
                    _construirBotonGrid(context, Icons.inventory_2, 'Paquetes', '3 Pendientes', const Color(0xFFF59E0B), null),
                    _construirBotonGrid(context, Icons.campaign, 'Comunicados', 'Últimas noticias', const Color(0xFF8B5CF6), null),
                  ],
                ),

                // 3. Separación ideal entre los botones y la sección de comunicados
                const SizedBox(height: 35),

                const Text(
                  'Último Comunicado',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),

                const SizedBox(height: 15),
                _construirTarjetaNotificacion(),

                // 4. El colchón final para la barra de cristal
                const SizedBox(height: 90),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirFondoHeader(BuildContext context) {
    return Container(
      height: 220,
      padding: const EdgeInsets.only(top: 60, left: 20, right: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hola, ${_residente.nombre}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text(_residente.unidadCompleta, style: const TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
          GestureDetector(
  onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const AdminResidentesScreen()),
  );
},
  child: Stack(
    children: [
      const CircleAvatar(
        radius: 25, 
        backgroundColor: Colors.white24, 
        child: Icon(Icons.person, color: Colors.white, size: 30)
      ),
      if (_residente.notificacionesSinLeer > 0)
        Positioned(
          right: 0, top: 0,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.redAccent, 
              shape: BoxShape.circle
            ),
            child: Text(
              '${_residente.notificacionesSinLeer}', 
              style: const TextStyle(
                color: Colors.white, 
                fontSize: 10, 
                fontWeight: FontWeight.bold
              )
            ),
          ),
        )
    ],
  ),
),
        ],
      ),
    );
  }

  Widget _construirTarjetaSaldo() {
    return Container(
      width: 350,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, 8))],
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Estado de Cuenta', style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w600)),
              Icon(Icons.more_horiz, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 15),
          Text(_residente.saldoFormateado, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
          const SizedBox(height: 5),
          Text(
            'Vence el ${_residente.fechaVencimiento.day} de ${_nombreMes(_residente.fechaVencimiento.month)}',
            style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity, height: 45,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () {},
              child: const Text('Pagar Administración', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _construirBotonGrid(BuildContext context, IconData icono, String titulo, String subtitulo, Color color, VoidCallback? accion) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: accion ?? () {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$titulo próximamente...'), duration: const Duration(seconds: 1)));
          },
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icono, color: color, size: 28),
                ),
                const Spacer(),
                Text(titulo, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(height: 2),
                Text(subtitulo, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _construirTarjetaNotificacion() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: const Border(left: BorderSide(color: Color(0xFF3B82F6), width: 5)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: const ListTile(
        contentPadding: EdgeInsets.all(15),
        leading: CircleAvatar(backgroundColor: Color(0xFFE0E7FF), child: Icon(Icons.water_drop, color: Color(0xFF3B82F6))),
        title: Text('Mantenimiento de Piscina', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: Text('La piscina estará cerrada este viernes por mantenimiento preventivo.', style: TextStyle(fontSize: 13)),
        ),
      ),
    );
  }

  String _nombreMes(int mes) {
    const meses = ['Enero','Febrero','Marzo','Abril','Mayo','Junio','Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre'];
    return meses[mes - 1];
  }

  void _mostrarVentanaQR(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext contextoDialogo) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          child: Container(
            padding: const EdgeInsets.all(25),
            height: 380,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Pase VIP Visitas', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(height: 5),
                const Text('Válido solo por hoy', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 25),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(Icons.qr_code_2, size: 120, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 20),
                const Text('Comparte este código en portería', style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(contextoDialogo),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cerrar y Volver', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
        );
      }
    );
  }
}
