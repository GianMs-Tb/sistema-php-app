// Importa los formularios de login y registro que se alternan dentro de la tarjeta.
import 'package:flutter_application_1/Widgets/auth/login_form.dart';
import 'package:flutter_application_1/Widgets/auth/register_form.dart';
import 'package:flutter/material.dart';

/// Tarjeta visual que contiene login o registro.
class AuthCard extends StatelessWidget {
  // Indica si la tarjeta muestra login o registro.
  final bool isLogin;

  // Acción que alterna entre login y registro.
  final VoidCallback onToggleMode;

  // Constructor con estado visual y acción de cambio.
  const AuthCard({
    super.key,
    required this.isLogin,
    required this.onToggleMode,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.dynamic_feed, size: 56),
            const SizedBox(height: 12),
            Text(
              isLogin ? 'Iniciar sesión' : 'Crear cuenta',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isLogin
                  ? 'Accede para ver tu tarjeta de presentación.'
                  : 'Regístrate para publicar en el feed.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: isLogin
                  ? const LoginForm(key: ValueKey('login'))
                  : const RegisterForm(key: ValueKey('register')),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onToggleMode,
              child: Text(
                isLogin
                    ? '¿No tienes cuenta? Regístrate'
                    : '¿Ya tienes cuenta? Inicia sesión',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
