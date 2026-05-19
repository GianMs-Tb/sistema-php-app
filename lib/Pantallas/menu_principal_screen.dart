import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/Services/firebase_alerta_sos_repository.dart';
import 'package:flutter_application_1/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'admin_pqrs_screen.dart';
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
      widget.isAdmin ? const AdminPqrsScreen() : const PqrsScreen(),
      const PerfilScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: pantallas[_indiceSeleccionado],
      floatingActionButton: _indiceSeleccionado == 1
          ? null
          : ScaleTransition(
              scale: _animacionLatido,
              child: FloatingActionButton(
                onPressed: () => _mostrarOpcionesSos(context),
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 4,
                child: const Icon(Icons.sos, size: 28),
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _indiceSeleccionado,
        onTap: (i) => setState(() => _indiceSeleccionado = i),
        showUnselectedLabels: true,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.support_agent_outlined),
            activeIcon: Icon(Icons.support_agent),
            label: 'PQRS',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarOpcionesSos(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.slate.withValues(alpha: 0.95),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: const Border(
                  top: BorderSide(color: AppColors.glassBorder),
                  left: BorderSide(color: AppColors.glassBorder),
                  right: BorderSide(color: AppColors.glassBorder),
                ),
              ),
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
                        color: AppColors.textSecondary.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Emergencia',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Elige una acción. En caso de peligro inmediato, llama a emergencias.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 54,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _llamarEmergencias(context);
                      },
                      icon: const Icon(Icons.phone_in_talk),
                      label: Text(
                        'Llamar a Emergencias (123)',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 54,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _enviarAlertaPorteria(context);
                      },
                      icon: const Icon(Icons.notifications_active_outlined),
                      label: Text(
                        'Enviar alerta a Portería y Administración',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
            backgroundColor: AppColors.mintDim,
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

}
