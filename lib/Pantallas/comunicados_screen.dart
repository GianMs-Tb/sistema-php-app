import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../Models/comunicado_model.dart';
import '../Services/firebase_comunicado_repository.dart';
import '../Widgets/glass_card.dart';
import '../theme/app_theme.dart';

/// Pantalla dedicada al feed de comunicados del edificio.
class ComunicadosScreen extends StatefulWidget {
  const ComunicadosScreen({super.key, required this.isAdmin});

  final bool isAdmin;

  @override
  State<ComunicadosScreen> createState() => _ComunicadosScreenState();
}

class _ComunicadosScreenState extends State<ComunicadosScreen> {
  final _repo = FirebaseComunicadoRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      appBar: AppBar(
        title: const Text('Comunicados'),
        actions: [
          if (widget.isAdmin)
            IconButton(
              tooltip: 'Nuevo comunicado',
              onPressed: () => _mostrarDialogoNuevoComunicado(context),
              icon: const Icon(Icons.add),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.isAdmin)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(
                'Desliza un comunicado hacia la izquierda para eliminarlo.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          Expanded(
            child: StreamBuilder<List<Comunicado>>(
              stream: _repo.stream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const _MensajeFeed(
                    icono: Icons.error_outline,
                    texto: 'Error al cargar comunicados.',
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final lista = snapshot.data ?? const <Comunicado>[];
                if (lista.isEmpty) {
                  return _MensajeFeed(
                    icono: Icons.campaign_outlined,
                    texto: widget.isAdmin
                        ? 'Aún no hay comunicados.\nPulsa + para publicar el primero.'
                        : 'Aún no hay comunicados.',
                  );
                }
                return ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: lista.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final c = lista[i];
                    final tarjeta = _TarjetaComunicado(comunicado: c);
                    if (!widget.isAdmin) return tarjeta;

                    return Dismissible(
                      key: ValueKey('comunicado_${c.id}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                        ),
                      ),
                      confirmDismiss: (_) async {
                        return showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Eliminar comunicado'),
                            content: Text(
                              '¿Eliminar "${c.titulo.isEmpty ? 'Sin título' : c.titulo}"?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancelar'),
                              ),
                              FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                ),
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Eliminar'),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (_) async {
                        try {
                          await _repo.eliminar(c.id);
                          _mostrarSnack('Comunicado eliminado');
                        } catch (e) {
                          _mostrarSnack('Error al eliminar: $e', esError: true);
                        }
                      },
                      child: tarjeta,
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

  Future<void> _mostrarDialogoNuevoComunicado(BuildContext context) async {
    final tituloCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo comunicado'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tituloCtrl,
                decoration: const InputDecoration(labelText: 'Título'),
                textCapitalization: TextCapitalization.sentences,
                autofocus: true,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  alignLabelWithHint: true,
                ),
                textCapitalization: TextCapitalization.sentences,
                minLines: 3,
                maxLines: 6,
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
            child: const Text('Publicar'),
          ),
        ],
      ),
    );

    if (ok == true) {
      final titulo = tituloCtrl.text.trim();
      final desc = descCtrl.text.trim();
      if (titulo.isEmpty || desc.isEmpty) {
        _mostrarSnack('Título y descripción son obligatorios.', esError: true);
      } else {
        final user = FirebaseAuth.instance.currentUser;
        final autor = (user?.displayName?.trim().isNotEmpty == true)
            ? user!.displayName!
            : (user?.email ?? 'Administración');
        try {
          await _repo.crear(
            Comunicado(
              id: '',
              titulo: titulo,
              descripcion: desc,
              autor: autor,
              autorUid: user?.uid ?? '',
            ),
          );
          _mostrarSnack('Comunicado publicado');
        } catch (e) {
          _mostrarSnack('Error al publicar: $e', esError: true);
        }
      }
    }

    tituloCtrl.dispose();
    descCtrl.dispose();
  }

  void _mostrarSnack(String texto, {bool esError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: esError ? Colors.redAccent : null,
      ),
    );
  }
}

class _TarjetaComunicado extends StatelessWidget {
  const _TarjetaComunicado({required this.comunicado});

  final Comunicado comunicado;

  @override
  Widget build(BuildContext context) {
    final fechaTxt = _formatearFecha(comunicado.createdAt);
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.mint.withValues(alpha: 0.15),
                child: const Icon(Icons.campaign, color: AppColors.mint),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  comunicado.titulo.isEmpty
                      ? 'Sin título'
                      : comunicado.titulo,
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            comunicado.descripcion,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.person_outline, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  comunicado.autor.isEmpty
                      ? 'Administración'
                      : comunicado.autor,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.schedule, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(fechaTxt, style: theme.textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return '—';
    final dd = fecha.day.toString().padLeft(2, '0');
    final mm = fecha.month.toString().padLeft(2, '0');
    final hh = fecha.hour.toString().padLeft(2, '0');
    final min = fecha.minute.toString().padLeft(2, '0');
    return '$dd/$mm/${fecha.year} $hh:$min';
  }
}

class _MensajeFeed extends StatelessWidget {
  const _MensajeFeed({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              texto,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
