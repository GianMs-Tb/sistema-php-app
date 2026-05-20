import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Models/app_user.dart';
import '../Services/firebase_user_repository.dart';
import '../Widgets/glass_card.dart';
import '../theme/app_theme.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _userRepo = FirebaseUserRepository();

  Future<void> _cerrarSesion(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text(
          '¿Estás seguro? Tendrás que volver a iniciar sesión para acceder a tu cuenta.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cerrar sesión: $e')),
      );
    }
  }

  Future<void> _editarCampo({
    required AppUser usuario,
    required String titulo,
    required String valorInicial,
    required String label,
    required Future<void> Function(String valor) onGuardar,
  }) async {
    final ctrl = TextEditingController(text: valorInicial);

    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.slate.withValues(alpha: 0.96),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  border: const Border(
                    top: BorderSide(color: AppColors.glassBorder),
                    left: BorderSide(color: AppColors.glassBorder),
                    right: BorderSide(color: AppColors.glassBorder),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                      titulo,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: ctrl,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(labelText: label),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Guardar'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancelar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (ok == true) {
      try {
        await onGuardar(ctrl.text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Datos actualizados')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al guardar: $e'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
    ctrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final email = FirebaseAuth.instance.currentUser?.email ?? '';

    if (uid == null) {
      return Scaffold(
        backgroundColor: AppColors.navy,
        appBar: AppBar(title: const Text('Mi Perfil')),
        body: const Center(child: Text('Inicia sesión para ver tu perfil.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.navy,
      appBar: AppBar(title: const Text('Mi Perfil')),
      body: StreamBuilder<AppUser>(
        stream: _userRepo.streamUsuario(uid),
        builder: (context, snapshot) {
          final usuario = snapshot.data ??
              AppUser(uid: uid, email: email, role: UserRoles.residente);

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.mint.withValues(alpha: 0.2),
                        child: Text(
                          usuario.nombreParaMostrar.isNotEmpty
                              ? usuario.nombreParaMostrar[0].toUpperCase()
                              : '?',
                          style: GoogleFonts.poppins(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: AppColors.mint,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        usuario.nombreParaMostrar,
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        usuario.email.isNotEmpty ? usuario.email : email,
                        style: theme.textTheme.bodyMedium,
                      ),
                      if (usuario.mostrarBadgeUnidad) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.mint.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.mint.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            usuario.unidadCompleta,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: AppColors.mint,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Datos personales',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 12),
                      _FilaDatoEditable(
                        icono: Icons.person_outline,
                        etiqueta: 'Nombre',
                        valor: usuario.nombre.isNotEmpty
                            ? usuario.nombre
                            : 'Sin definir',
                        onEditar: () => _editarCampo(
                          usuario: usuario,
                          titulo: 'Editar nombre',
                          valorInicial: usuario.nombre,
                          label: 'Nombre completo',
                          onGuardar: (v) => _userRepo.actualizarPerfil(
                            uid,
                            nombre: v,
                          ),
                        ),
                      ),
                      if (usuario.isResidente) ...[
                        _FilaDatoEditable(
                          icono: Icons.apartment_outlined,
                          etiqueta: 'Apartamento',
                          valor: usuario.apartamento.isNotEmpty
                              ? usuario.apartamento
                              : 'Sin definir',
                          onEditar: () => _editarCampo(
                            usuario: usuario,
                            titulo: 'Editar apartamento',
                            valorInicial: usuario.apartamento,
                            label: 'Número o código de apartamento',
                            onGuardar: (v) => _userRepo.actualizarPerfil(
                              uid,
                              apartamento: v,
                            ),
                          ),
                        ),
                        _FilaDatoEditable(
                          icono: Icons.domain_outlined,
                          etiqueta: 'Torre',
                          valor: usuario.torre.isNotEmpty
                              ? usuario.torre
                              : 'Sin definir',
                          onEditar: () => _editarCampo(
                            usuario: usuario,
                            titulo: 'Editar torre',
                            valorInicial: usuario.torre,
                            label: 'Torre o bloque',
                            onGuardar: (v) => _userRepo.actualizarPerfil(
                              uid,
                              torre: v,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
                      Text('Configuración', style: theme.textTheme.titleSmall),
                      const SizedBox(height: 15),
                      _construirOpcionMenu(
                        context,
                        Icons.notifications_outlined,
                        'Notificaciones',
                        true,
                      ),
                      _construirOpcionMenu(
                        context,
                        Icons.lock_outline,
                        'Seguridad y Contraseña',
                        false,
                      ),
                      _construirOpcionMenu(
                        context,
                        Icons.help_outline,
                        'Soporte y Ayuda',
                        false,
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: () => _cerrarSesion(context),
                          icon: const Icon(Icons.logout, color: AppColors.danger),
                          label: const Text(
                            'Cerrar Sesión',
                            style: TextStyle(
                              color: AppColors.danger,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.danger),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _construirOpcionMenu(
    BuildContext context,
    IconData icono,
    String titulo,
    bool tieneNotificacion,
  ) {
    final theme = Theme.of(context);
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.mint.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icono, color: AppColors.mint),
        ),
        title: Text(titulo, style: theme.textTheme.titleSmall),
        trailing: tieneNotificacion
            ? Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                ),
              )
            : Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textSecondary,
              ),
        onTap: () {},
      ),
    );
  }
}

class _FilaDatoEditable extends StatelessWidget {
  const _FilaDatoEditable({
    required this.icono,
    required this.etiqueta,
    required this.valor,
    required this.onEditar,
  });

  final IconData icono;
  final String etiqueta;
  final String valor;
  final VoidCallback onEditar;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Icon(icono, color: AppColors.mint, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  etiqueta,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  valor,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onEditar,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Editar'),
          ),
        ],
      ),
    );
  }
}
