import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../Models/alerta_sos_model.dart';
import '../Models/paquete_model.dart';
import '../Models/visita_model.dart';
import '../Services/firebase_alerta_sos_repository.dart';
import '../Services/firebase_paquete_repository.dart';
import '../Services/firebase_visita_repository.dart';
import '../Widgets/banner_sos_emergencia.dart';
import '../theme/app_theme.dart';

/// Pantalla exclusiva del rol `portero`: visitas, paquetería y alertas SOS.
class PorteroInicioScreen extends StatefulWidget {
  const PorteroInicioScreen({super.key});

  @override
  State<PorteroInicioScreen> createState() => _PorteroInicioScreenState();
}

class _PorteroInicioScreenState extends State<PorteroInicioScreen> {
  final _repoVisita = FirebaseVisitaRepository();
  final _repoPaquete = FirebasePaqueteRepository();
  final _repoAlerta = FirebaseAlertaSosRepository();

  int _pestana = 0;
  bool _validando = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      appBar: AppBar(
        title: Text(_pestana == 0 ? 'Visitas' : 'Paquetería'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () async => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StreamBuilder<List<AlertaSos>>(
            stream: _repoAlerta.streamActivas(),
            builder: (context, snap) {
              final activas = snap.data ?? const <AlertaSos>[];
              if (activas.isEmpty) return const SizedBox.shrink();
              return BannerSosEmergencia(
                alertas: activas,
                onMarcarAtendida: (id) => _marcarAlertaAtendida(id),
              );
            },
          ),
          Expanded(
            child: _pestana == 0
                ? _construirPestanaVisitas()
                : _construirPestanaPaqueteria(),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _pestana,
        onDestinationSelected: (i) => setState(() => _pestana = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.meeting_room_outlined),
            selectedIcon: Icon(Icons.meeting_room),
            label: 'Visitas',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Paquetería',
          ),
        ],
      ),
    );
  }

  Future<void> _marcarAlertaAtendida(String id) async {
    try {
      await _repoAlerta.marcarAtendida(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alerta marcada como atendida')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Widget _construirPestanaVisitas() {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
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
            const SizedBox(height: 28),
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
    );
  }

  Widget _construirPestanaPaqueteria() {
    return SafeArea(
      top: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _mostrarRegistrarPaquete,
              icon: const Icon(Icons.add_box_outlined),
              label: const Text(
                'Registrar nuevo paquete',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Pendientes en portería',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<List<Paquete>>(
              stream: _repoPaquete.streamPendientesEnPorteria(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final lista = snapshot.data ?? const <Paquete>[];
                if (lista.isEmpty) {
                  return Center(
                    child: Text(
                      'No hay paquetes pendientes.',
                      style: TextStyle(
                        color: Colors.grey.withValues(alpha: 0.9),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: lista.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final p = lista[i];
                    return _TarjetaPaquetePortero(
                      paquete: p,
                      onEntregado: () => _marcarPaqueteEntregado(p.id),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarRegistrarPaquete() async {
    final aptCtrl = TextEditingController();
    final torreCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final emailCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registrar paquete'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: aptCtrl,
                decoration: const InputDecoration(
                  labelText: 'Apartamento',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: torreCtrl,
                decoration: const InputDecoration(
                  labelText: 'Torre',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descripción (ej. Amazon, Rappi)',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo del residente (opcional)',
                  hintText: 'Para vincular con su cuenta en la app',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) {
      aptCtrl.dispose();
      torreCtrl.dispose();
      descCtrl.dispose();
      emailCtrl.dispose();
      return;
    }

    final apt = aptCtrl.text.trim();
    final torre = torreCtrl.text.trim();
    final desc = descCtrl.text.trim();
    final email = emailCtrl.text.trim();
    aptCtrl.dispose();
    torreCtrl.dispose();
    descCtrl.dispose();
    emailCtrl.dispose();

    if (apt.isEmpty || torre.isEmpty || desc.isEmpty) {
      _snack('Apartamento, torre y descripción son obligatorios.', error: true);
      return;
    }

    String uid = '';
    if (email.isNotEmpty) {
      uid = (await _repoPaquete.resolverUidPorEmail(email)) ?? '';
      if (uid.isEmpty && mounted) {
        _snack(
          'No se encontró usuario con ese correo; el paquete se guarda sin vínculo.',
          error: false,
        );
      }
    }

    try {
      await _repoPaquete.crear(
        residenteUid: uid,
        apartamento: apt,
        torre: torre,
        descripcion: desc,
      );
      _snack('Paquete registrado');
    } catch (e) {
      _snack('Error al guardar: $e', error: true);
    }
  }

  Future<void> _marcarPaqueteEntregado(String id) async {
    try {
      await _repoPaquete.marcarEntregado(id);
      _snack('Marcado como entregado');
    } catch (e) {
      _snack('Error: $e', error: true);
    }
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
              onSubmitted: (_) => Navigator.pop(ctx, ctrl.text.trim()),
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
      visita = await _repoVisita.obtenerPorId(id);
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
      await _repoVisita.permitirAcceso(id);
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

class _TarjetaPaquetePortero extends StatelessWidget {
  const _TarjetaPaquetePortero({
    required this.paquete,
    required this.onEntregado,
  });

  final Paquete paquete;
  final VoidCallback onEntregado;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            paquete.descripcion,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${paquete.apartamento} · ${paquete.torre}',
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
          if (paquete.residenteUid.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Vinculado a cuenta',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
              ),
              onPressed: onEntregado,
              child: const Text('Marcar como entregado'),
            ),
          ),
        ],
      ),
    );
  }
}
