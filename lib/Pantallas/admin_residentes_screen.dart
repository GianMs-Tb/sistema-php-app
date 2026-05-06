import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../Models/residente_model.dart';
import '../Services/firebase_residente_repository.dart';

String _formatoFechaCorta(DateTime d) {
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class AdminResidentesScreen extends StatefulWidget {
  const AdminResidentesScreen({super.key});

  @override
  State<AdminResidentesScreen> createState() => _AdminResidentesScreenState();
}

class _AdminResidentesScreenState extends State<AdminResidentesScreen> {
  final _repo = FirebaseResidenteRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Residentes / Apartamentos'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<List<ResidenteModel>>(
        stream: _repo.streamResidentes(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error al cargar datos:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final lista = snapshot.data ?? [];
          if (lista.isEmpty) {
            return Center(
              child: Text(
                'No hay residentes.\nToca + para agregar.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: lista.length,
            itemBuilder: (context, index) {
              final r = lista[index];
              return _TarjetaResidente(
                residente: r,
                onEditarSaldo: () => _mostrarDialogoSaldo(context, r),
                onEliminar: () => _confirmarEliminar(context, r),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialogoNuevoResidente(context),
        backgroundColor: const Color(0xFF2563EB),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Future<void> _mostrarDialogoNuevoResidente(BuildContext context) async {
    final nombreCtrl = TextEditingController();
    final aptoCtrl = TextEditingController();
    final torreCtrl = TextEditingController();
    final saldoCtrl = TextEditingController();
    final notifCtrl = TextEditingController(text: '0');
    DateTime fecha = DateTime.now().add(const Duration(days: 30));

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          return AlertDialog(
            title: const Text('Nuevo residente'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nombreCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    textCapitalization: TextCapitalization.words,
                  ),
                  TextField(
                    controller: aptoCtrl,
                    decoration: const InputDecoration(labelText: 'Apartamento'),
                  ),
                  TextField(
                    controller: torreCtrl,
                    decoration: const InputDecoration(labelText: 'Torre'),
                  ),
                  TextField(
                    controller: saldoCtrl,
                    decoration: const InputDecoration(labelText: 'Saldo pendiente'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Vencimiento'),
                    subtitle: Text(_formatoFechaCorta(fecha)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: fecha,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setLocal(() => fecha = picked);
                      }
                    },
                  ),
                  TextField(
                    controller: notifCtrl,
                    decoration: const InputDecoration(labelText: 'Notif. sin leer'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
          );
        },
      ),
    );

    if (ok == true && context.mounted) {
      final nombre = nombreCtrl.text.trim();
      if (nombre.isEmpty) return;

      final saldo = double.tryParse(saldoCtrl.text.replaceAll(',', '.')) ?? 0;
      final notif = int.tryParse(notifCtrl.text.trim()) ?? 0;

      final nuevo = ResidenteModel(
        id: '',
        nombre: nombre,
        apartamento: aptoCtrl.text.trim(),
        torre: torreCtrl.text.trim(),
        saldoPendiente: saldo,
        fechaVencimiento: fecha,
        notificacionesSinLeer: notif,
      );

      try {
        await _repo.crear(nuevo);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Residente creado')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }

    nombreCtrl.dispose();
    aptoCtrl.dispose();
    torreCtrl.dispose();
    saldoCtrl.dispose();
    notifCtrl.dispose();
  }

  Future<void> _mostrarDialogoSaldo(BuildContext context, ResidenteModel r) async {
    final ctrl = TextEditingController(text: r.saldoPendiente.toString());

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Saldo — ${r.nombre}'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Saldo pendiente',
            prefixText: '\$ ',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
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

    if (ok == true && context.mounted) {
      final saldo = double.tryParse(ctrl.text.replaceAll(',', '.')) ?? r.saldoPendiente;
      try {
        await _repo.actualizar(r.copyWith(saldoPendiente: saldo));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saldo actualizado')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
    ctrl.dispose();
  }

  Future<void> _confirmarEliminar(BuildContext context, ResidenteModel r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar residente'),
        content: Text('¿Eliminar a ${r.nombre}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (ok == true && context.mounted) {
      try {
        await _repo.eliminar(r.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Residente eliminado')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

}

class _TarjetaResidente extends StatelessWidget {
  const _TarjetaResidente({
    required this.residente,
    required this.onEditarSaldo,
    required this.onEliminar,
  });

  final ResidenteModel residente;
  final VoidCallback onEditarSaldo;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final saldoTxt = residente.saldoPendiente.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        residente.nombre,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${residente.apartamento} · ${residente.torre}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                if (residente.notificacionesSinLeer > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${residente.notificacionesSinLeer} avisos',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.account_balance_wallet_outlined, size: 18, color: Colors.grey.shade700),
                const SizedBox(width: 6),
                Text(
                  '\$ $saldoTxt',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.event_outlined, size: 18, color: Colors.grey.shade700),
                const SizedBox(width: 6),
                Text(
                  _formatoFechaCorta(residente.fechaVencimiento),
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onEditarSaldo,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Editar saldo'),
                ),
                TextButton.icon(
                  onPressed: onEliminar,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Eliminar'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
