import 'package:flutter/material.dart';
import 'Pantallas/inicio_screen.dart';
import 'Pantallas/reservas_screen.dart';
import 'Pantallas/pagos_screen.dart';
import 'Pantallas/perfil_screen.dart';
import 'dart:ui';

void main() {
  runApp(const SistemaPHApp());
}

class SistemaPHApp extends StatelessWidget {
  const SistemaPHApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema Integral PH',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      ),
      home: const MenuNavegacionPrincipal(),
    );
  }
}

class MenuNavegacionPrincipal extends StatefulWidget {
  const MenuNavegacionPrincipal({super.key});

  @override
  State<MenuNavegacionPrincipal> createState() => _MenuNavegacionPrincipalState();
}

// 1. AQUÍ AGREGAMOS EL "CRONÓMETRO" (SingleTickerProviderStateMixin)
class _MenuNavegacionPrincipalState extends State<MenuNavegacionPrincipal> with SingleTickerProviderStateMixin {
  int _indiceSeleccionado = 0;

  // 2. VARIABLES DE ANIMACIÓN PARA EL BOTÓN SOS
  late AnimationController _controladorAnimacion;
  late Animation<double> _animacionLatido;

  final List<Widget> _pantallas = [
    const InicioScreen(),
    const ReservasScreen(),
    const PagosScreen(),
    const PerfilScreen(),
  ];

  // 3. INICIAMOS EL LATIDO A LO QUE ARRANCA LA APP
  @override
  void initState() {
    super.initState();
    _controladorAnimacion = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1), // Dura un segundo en inflarse
    )..repeat(reverse: true); // Y se repite hacia atrás (se desinfla)

    _animacionLatido = Tween<double>(begin: 1.0, end: 1.15).animate(_controladorAnimacion);
  }

  // 4. APAGAMOS EL MOTOR SI CERRAMOS LA APP
  @override
  void dispose() {
    _controladorAnimacion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // <--- NUEVO: Deja que el contenido pase por detrás del menú
      body: _pantallas[_indiceSeleccionado],

      // 5. ENVOLVEMOS EL BOTÓN SOS EN LA ANIMACIÓN DE ESCALA
      floatingActionButton: ScaleTransition(
        scale: _animacionLatido, // Conectamos el tamaño al latido
        child: FloatingActionButton(
          onPressed: () {},
          backgroundColor: const Color(0xFF2563EB),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 4,
          child: const Icon(Icons.sos, color: Colors.white, size: 28),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: BottomAppBar(
            shape: const CircularNotchedRectangle(),
            notchMargin: 8.0,
            color: Colors.white70, // <-- El blanco transparente
            elevation: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _construirIconoNav(Icons.home, 'Inicio', 0),
                _construirIconoNav(Icons.calendar_today, 'Reservas', 1),
                const SizedBox(width: 40),
                _construirIconoNav(Icons.receipt_long, 'Pagos', 2),
                _construirIconoNav(Icons.person, 'Perfil', 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _construirIconoNav(IconData icono, String etiqueta, int indice) {
    bool seleccionado = _indiceSeleccionado == indice;
    return InkWell(
      onTap: () {
        setState(() => _indiceSeleccionado = indice);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, color: seleccionado ? const Color(0xFF2563EB) : Colors.grey, size: 26),
            Text(etiqueta, style: TextStyle(fontSize: 10, color: seleccionado ? const Color(0xFF2563EB) : Colors.grey, fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}
