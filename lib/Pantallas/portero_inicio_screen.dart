import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../Models/visita_model.dart';
import '../Services/firebase_visita_repository.dart';

/// Pantalla exclusiva del rol `portero`: validación manual del código de visita.
class PorteroInicioScreen extends StatefulWidget {
  const PorteroInicioScreen({super.key});

  @override
  State<PorteroInicioScreen> createState() => _PorteroInicioScreenState();
}

class _PorteroInicioScreenState extends State<PorteroInicioScreen> {
  final _repo = FirebaseVisitaRepository();
  bool _validando = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          'Portería',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () async => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.18),
                          child: const Icon(
                            Icons.shield_outlined,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Control de acceso',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Valida el código (ID) del QR o escríbelo manualmente para registrar el ingreso.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        height: 1.45,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Acciones',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 56,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _validando ? null : _mostrarDialogoCodigo,
                  icon: const Icon(Icons.qr_code_2, size: 26),
                  label: const Text(
                    'Validar entrada (Ingresar código)',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Sesión: ${FirebaseAuth.instance.currentUser?.email ?? "—"}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _mostrarDialogoCodigo() async {
    final ctrl = TextEditingController();
    final id = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Código de visita'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pega o escribe el ID del documento (equivalente a escanear el QR).',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                labelText: 'ID de la visita',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) =>
                  Navigator.pop(ctx, ctrl.text.trim()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Consultar'),
          ),
        ],
      ),
    );
    ctrl.dispose();

    if (id == null || id.isEmpty) return;

    setState(() => _validando = true);
    Visita? visita;
    try {
      visita = await _repo.obtenerPorId(id);
    } catch (e) {
      if (mounted) {
        _snack('Error de consulta: $e', error: true);
      }
      setState(() => _validando = false);
      return;
    }
    setState(() => _validando = false);

    if (!mounted) return;

    if (visita == null) {
      _snack('No existe una visita con ese código.', error: true);
      return;
    }

    if (!visita.esPendiente) {
      final procesada = visita;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Visita ya procesada'),
          content: Text(
            'Estado actual: ${procesada.estado}\n'
            'Visitante: ${procesada.nombreVisitante}\n'
            'Destino: ${procesada.unidadDestino}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
      return;
    }

    final pendiente = visita;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          22,
          14,
          22,
          22 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
              'Visita pendiente',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFFB45309),
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              pendiente.nombreVisitante,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 14),
            _filaInfo(Icons.apartment, 'Apartamento / torre', pendiente.unidadDestino),
            const SizedBox(height: 10),
            if (pendiente.residenteNombre.isNotEmpty)
              _filaInfo(Icons.person, 'Residente', pendiente.residenteNombre),
            if (pendiente.residenteNombre.isNotEmpty) const SizedBox(height: 10),
            _filaInfo(
              Icons.schedule,
              'Esperado',
              _formatoFecha(pendiente.fechaHoraEsperada),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await _permitir(pendiente.id);
                },
                icon: const Icon(Icons.check_circle_outline),
                label: const Text(
                  'Permitir acceso',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filaInfo(IconData icono, String etiqueta, String valor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 20, color: const Color(0xFF64748B)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                etiqueta,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.withValues(alpha: 0.95),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                valor.isEmpty ? '—' : valor,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _permitir(String id) async {
    try {
      await _repo.permitirAcceso(id);
      _snack('Acceso permitido. Ingreso registrado.');
    } catch (e) {
      _snack('No se pudo registrar el ingreso: $e', error: true);
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.redAccent : const Color(0xFF16A34A),
      ),
    );
  }

  static String _formatoFecha(DateTime? fecha) {
    if (fecha == null) return '—';
    final dd = fecha.day.toString().padLeft(2, '0');
    final mm = fecha.month.toString().padLeft(2, '0');
    final hh = fecha.hour.toString().padLeft(2, '0');
    final mi = fecha.minute.toString().padLeft(2, '0');
    return '$dd/$mm/${fecha.year} $hh:$mi';
  }
}
