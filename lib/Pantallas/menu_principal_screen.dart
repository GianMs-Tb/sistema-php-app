import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/Services/firebase_alerta_sos_repository.dart';
import 'package:url_launcher/url_launcher.dart';

import 'inicio_screen.dart';
import 'perfil_screen.dart';
import 'pqrs_screen.dart';

/// Shell principal con navegación inferior (Inicio, PQRS, Perfil) y botón SOS central.
class MenuNavegacionPrincipal extends StatefulWidget {
  const MenuNavegacionPrincipal({
    super.key,
    required this.isAdmin,
  });

  final bool isAdmin;

  @override
  State<MenuNavegacionPrincipal> createState() => _MenuNavegacionPrincipalState();
}

class _MenuNavegacionPrincipalState extends State<MenuNavegacionPrincipal>
    with SingleTickerProviderStateMixin {
  int _indiceSeleccionado = 0;

  final _alertaSosRepo = FirebaseAlertaSosRepository();

  late AnimationController _controladorAnimacion;
  late Animation<double> _animacionLatido;

  @override
  void initState() {
    super.initState();
    _controladorAnimacion = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _animacionLatido = Tween<double>(begin: 1.0, end: 1.15).animate(_controladorAnimacion);
  }

  @override
  void dispose() {
    _controladorAnimacion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pantallas = <Widget>[
      InicioScreen(isAdmin: widget.isAdmin),
      const PqrsScreen(),
      const PerfilScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: pantallas[_indiceSeleccionado],
      floatingActionButton: ScaleTransition(
        scale: _animacionLatido,
        child: FloatingActionButton(
          onPressed: () => _mostrarOpcionesSos(context),
          backgroundColor: const Color(0xFFB91C1C),
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
            color: Colors.white70,
            elevation: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _construirIconoNav(Icons.home, 'Inicio', 0),
                _construirIconoNav(Icons.support_agent, 'PQRS', 1),
                const SizedBox(width: 48),
                _construirIconoNav(Icons.person, 'Perfil', 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _mostrarOpcionesSos(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Emergencia',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Elige una acción. En caso de peligro inmediato, llama a emergencias.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF64748B), height: 1.4),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 54,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _llamarEmergencias(context);
                  },
                  icon: const Icon(Icons.phone_in_talk),
                  label: const Text(
                    'Llamar a Emergencias (123)',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 54,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFB91C1C),
                    side: const BorderSide(color: Color(0xFFB91C1C), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _enviarAlertaPorteria(context);
                  },
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: const Text(
                    'Enviar alerta a Portería y Administración',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _llamarEmergencias(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: '123');
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir el marcador telefónico.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al llamar: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _enviarAlertaPorteria(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debes iniciar sesión.')),
        );
      }
      return;
    }

    String apartamento = 'N/D';
    String torre = 'N/D';
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = doc.data();
      if (data != null) {
        apartamento = (data['apartamento'] as String?)?.trim().isNotEmpty == true
            ? (data['apartamento'] as String).trim()
            : apartamento;
        torre = (data['torre'] as String?)?.trim().isNotEmpty == true
            ? (data['torre'] as String).trim()
            : torre;
      }
    } catch (_) {}

    final nombre = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!.trim()
        : (user.email ?? 'Residente');

    try {
      await _alertaSosRepo.crearActiva(
        residenteUid: user.uid,
        nombreResidente: nombre,
        apartamento: apartamento,
        torre: torre,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Alerta enviada a portería y administración.',
            ),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo enviar la alerta: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Widget _construirIconoNav(IconData icono, String etiqueta, int indice) {
    final seleccionado = _indiceSeleccionado == indice;
    return InkWell(
      onTap: () => setState(() => _indiceSeleccionado = indice),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icono,
              color: seleccionado ? const Color(0xFF2563EB) : Colors.grey,
              size: 26,
            ),
            Text(
              etiqueta,
              style: TextStyle(
                fontSize: 10,
                color: seleccionado ? const Color(0xFF2563EB) : Colors.grey,
                fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
