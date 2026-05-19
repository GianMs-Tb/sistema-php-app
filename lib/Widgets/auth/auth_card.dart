import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/Widgets/auth/login_form.dart';
import 'package:flutter_application_1/Widgets/auth/register_form.dart';
import 'package:flutter_application_1/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tarjeta glass con login o registro.
class AuthCard extends StatelessWidget {
  const AuthCard({
    super.key,
    required this.isLogin,
    required this.onToggleMode,
  });

  final bool isLogin;
  final VoidCallback onToggleMode;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          decoration: BoxDecoration(
            color: AppColors.slate.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.glassBorder, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.mint.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.mint.withValues(alpha: 0.35),
                  ),
                ),
                child: const Icon(
                  Icons.apartment_rounded,
                  size: 40,
                  color: AppColors.mint,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isLogin ? 'Bienvenido' : 'Crear cuenta',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isLogin
                    ? 'Accede a la gestión digital de tu conjunto.'
                    : 'Regístrate para usar los servicios del edificio.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.45,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 28),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                child: isLogin
                    ? const LoginForm(key: ValueKey('login'))
                    : const RegisterForm(key: ValueKey('register')),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: onToggleMode,
                child: Text(
                  isLogin
                      ? '¿No tienes cuenta? Regístrate'
                      : '¿Ya tienes cuenta? Inicia sesión',
                  style: GoogleFonts.inter(
                    color: AppColors.mint,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
