import 'package:flutter/material.dart';

import '../Models/alerta_sos_model.dart';
import '../Models/residente_model.dart';
import '../Services/firebase_alerta_sos_repository.dart';
import '../Services/firebase_residente_repository.dart';
import '../Widgets/banner_sos_emergencia.dart';
import '../Widgets/glass_card.dart';
import '../theme/app_theme.dart';
import 'admin_pqrs_screen.dart';

class AdminResidentesScreen extends StatefulWidget {
  const AdminResidentesScreen({super.key});

  @override
  State<AdminResidentesScreen> createState() => _AdminResidentesScreenState();
}

class _AdminResidentesScreenState extends State<AdminResidentesScreen> {
  final _repo = FirebaseResidenteRepository();
  final _alertaSosRepo = FirebaseAlertaSosRepository();
  final _searchCtrl = TextEditingController();
  String _query = '';

  /// Si es `true` la lista muestra residentes inactivos en lugar de activos.
  bool _verArchivados = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Filtro local por nombre/apartamento/torre + segmento activo/archivado.
  List<ResidenteModel> _filtrar(List<ResidenteModel> lista) {
    final segmento = lista.where((r) =>
        _verArchivados ? r.esInactivo : r.esActivo);

    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return segmento.toList();

    return segmento.where((r) {
      return r.nombre.toLowerCase().contains(q) ||
          r.apartamento.toLowerCase().contains(q) ||
          r.torre.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      appBar: AppBar(
        title: const Text('Residentes / Apartamentos'),
        actions: [
          IconButton(
            tooltip: 'Gestión PQRS',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AdminPqrsScreen()),
            ),
            icon: const Icon(Icons.support_agent),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StreamBuilder(
            stream: _alertaSosRepo.streamActivas(),
            builder: (context, sosSnap) {
              final activas = sosSnap.data ?? const <AlertaSos>[];
              return BannerSosEmergencia(
                alertas: activas,
                onMarcarAtendida: (id) => _marcarAlertaAtendida(id),
              );
            },
          ),
          Expanded(
            child: StreamBuilder<List<ResidenteModel>>(
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

                final cargando =
                    snapshot.connectionState == ConnectionState.waiting;
                final todos = snapshot.data ?? const <ResidenteModel>[];
                final totalActivos = todos.where((r) => r.esActivo).length;
                final totalArchivados = todos.where((r) => r.esInactivo).length;
                final filtradas = _filtrar(todos);

                return Column(
                  children: [
                    _construirEstadisticas(total: totalActivos),
                    _construirToggleArchivados(
                      totalArchivados: totalArchivados,
                      totalActivos: totalActivos,
                    ),
                    _construirBuscador(),
                    const SizedBox(height: 8),
                    Expanded(
                      child: cargando
                          ? const Center(child: CircularProgressIndicator())
                          : _construirListado(
                              filtradas,
                              totalActivos,
                              totalArchivados,
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarDialogoNuevoResidente(context),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
    );
  }

  Future<void> _marcarAlertaAtendida(String id) async {
    try {
      await _alertaSosRepo.marcarAtendida(id);
      _mostrarSnack('Alerta marcada como atendida');
    } catch (e) {
      _mostrarSnack('Error al actualizar alerta: $e', esError: true);
    }
  }

  // ---------------------------------------------------------------------------
  // Dashboard: tarjetas de estadísticas
  // ---------------------------------------------------------------------------

  Widget _construirEstadisticas({required int total}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              icono: Icons.people,
              titulo: 'Total Residentes',
              valor: '$total',
              color: AppColors.mint,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: _StatCard(
              icono: Icons.check_circle,
              titulo: 'Zonas Activas',
              valor: '4',
              color: AppColors.mintDim,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Toggle Activos / Archivados
  // ---------------------------------------------------------------------------

  Widget _construirToggleArchivados({
    required int totalArchivados,
    required int totalActivos,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment<bool>(
                  value: false,
                  label: Text('Activos ($totalActivos)'),
                  icon: const Icon(Icons.people_alt_outlined),
                ),
                ButtonSegment<bool>(
                  value: true,
                  label: Text('Archivados ($totalArchivados)'),
                  icon: const Icon(Icons.archive_outlined),
                ),
              ],
              selected: {_verArchivados},
              showSelectedIcon: false,
              onSelectionChanged: (selected) {
                setState(() => _verArchivados = selected.first);
              },
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                textStyle: const WidgetStatePropertyAll(
                  TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Buscador reactivo
  // ---------------------------------------------------------------------------

  Widget _construirBuscador() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
          controller: _searchCtrl,
          onChanged: (value) => setState(() => _query = value),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Buscar por nombre, apartamento o torre',
            prefixIcon: const Icon(Icons.search, color: AppColors.mint),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _query = '');
                    },
                  ),
          ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Listado de residentes (resultado del filtro local)
  // ---------------------------------------------------------------------------

  Widget _construirListado(
    List<ResidenteModel> filtradas,
    int totalActivos,
    int totalArchivados,
  ) {
    if (_verArchivados && totalArchivados == 0) {
      return _construirVacio(
        Icons.archive_outlined,
        'No hay residentes archivados.',
      );
    }
    if (!_verArchivados && totalActivos == 0) {
      return _construirVacio(
        Icons.people_outline,
        'No hay residentes.\nToca + para agregar.',
      );
    }
    if (filtradas.isEmpty) {
      return _construirVacio(
        Icons.search_off,
        'Sin resultados para "${_query.trim()}".',
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: filtradas.length,
      itemBuilder: (context, index) {
        final r = filtradas[index];
        return _TarjetaResidente(
          residente: r,
          mostrarComoArchivado: _verArchivados,
          onEditarDatos: () => _mostrarDialogoEditar(context, r),
          onInactivar: () => _confirmarInactivar(context, r),
          onReactivar: () => _confirmarReactivar(context, r),
        );
      },
    );
  }

  Widget _construirVacio(IconData icono, String texto) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, color: Colors.grey.shade400, size: 56),
            const SizedBox(height: 14),
            Text(
              texto,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Diálogo de nuevo residente (formulario limpio)
  // ---------------------------------------------------------------------------

  Future<void> _mostrarDialogoNuevoResidente(BuildContext context) async {
    final result = await _mostrarFormularioResidente(
      context: context,
      titulo: 'Nuevo residente',
      etiquetaAccion: 'Guardar',
    );
    if (result == null) return;

    final nuevo = ResidenteModel(
      id: '',
      nombre: result.nombre,
      apartamento: result.apartamento,
      torre: result.torre,
      saldoPendiente: 0,
      fechaVencimiento: null,
      notificacionesSinLeer: 0,
      status: ResidenteStatus.active,
    );

    try {
      await _repo.crear(nuevo);
      _mostrarSnack('Residente creado');
    } catch (e) {
      _mostrarSnack('Error al crear: $e', esError: true);
    }
  }

  // ---------------------------------------------------------------------------
  // Diálogo de edición de residente (pre-llenado)
  // ---------------------------------------------------------------------------

  Future<void> _mostrarDialogoEditar(
    BuildContext context,
    ResidenteModel r,
  ) async {
    final result = await _mostrarFormularioResidente(
      context: context,
      titulo: 'Editar residente',
      etiquetaAccion: 'Guardar cambios',
      nombreInicial: r.nombre,
      apartamentoInicial: r.apartamento,
      torreInicial: r.torre,
    );
    if (result == null) return;

    try {
      await _repo.actualizar(
        r.copyWith(
          nombre: result.nombre,
          apartamento: result.apartamento,
          torre: result.torre,
        ),
      );
      _mostrarSnack('Residente actualizado');
    } catch (e) {
      _mostrarSnack('Error al actualizar: $e', esError: true);
    }
  }

  /// Formulario único reutilizado para crear y editar. Devuelve `null` si el
  /// usuario cancela o si la validación falla.
  Future<_DatosResidenteForm?> _mostrarFormularioResidente({
    required BuildContext context,
    required String titulo,
    required String etiquetaAccion,
    String nombreInicial = '',
    String apartamentoInicial = '',
    String torreInicial = '',
  }) async {
    final nombreCtrl = TextEditingController(text: nombreInicial);
    final aptoCtrl = TextEditingController(text: apartamentoInicial);
    final torreCtrl = TextEditingController(text: torreInicial);

    _DatosResidenteForm? datos;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre'),
                textCapitalization: TextCapitalization.words,
                autofocus: nombreInicial.isEmpty,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: aptoCtrl,
                decoration: const InputDecoration(labelText: 'Apartamento'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: torreCtrl,
                decoration: const InputDecoration(labelText: 'Torre'),
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
            child: Text(etiquetaAccion),
          ),
        ],
      ),
    );

    if (ok == true) {
      final nombre = nombreCtrl.text.trim();
      if (nombre.isEmpty) {
        _mostrarSnack('El nombre es obligatorio.', esError: true);
      } else {
        datos = _DatosResidenteForm(
          nombre: nombre,
          apartamento: aptoCtrl.text.trim(),
          torre: torreCtrl.text.trim(),
        );
      }
    }

    nombreCtrl.dispose();
    aptoCtrl.dispose();
    torreCtrl.dispose();

    return datos;
  }

  // ---------------------------------------------------------------------------
  // Inactivar / reactivar (soft delete)
  // ---------------------------------------------------------------------------

  Future<void> _confirmarInactivar(
      BuildContext context, ResidenteModel r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Inactivar residente'),
        content: Text(
          '¿Seguro que deseas inactivar a ${r.nombre}? '
          'No podrá acceder a la app, pero su historial se conservará.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEA580C),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Inactivar'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await _repo.inactivar(r.id);
      _mostrarSnack('${r.nombre} fue archivado');
    } catch (e) {
      _mostrarSnack('Error al inactivar: $e', esError: true);
    }
  }

  Future<void> _confirmarReactivar(
      BuildContext context, ResidenteModel r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reactivar residente'),
        content: Text('¿Reactivar a ${r.nombre}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reactivar'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await _repo.reactivar(r.id);
      _mostrarSnack('${r.nombre} fue reactivado');
    } catch (e) {
      _mostrarSnack('Error al reactivar: $e', esError: true);
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

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

// =============================================================================
// Modelos de soporte locales
// =============================================================================

class _DatosResidenteForm {
  const _DatosResidenteForm({
    required this.nombre,
    required this.apartamento,
    required this.torre,
  });

  final String nombre;
  final String apartamento;
  final String torre;
}

// =============================================================================
// Widgets de soporte
// =============================================================================

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icono,
    required this.titulo,
    required this.valor,
    required this.color,
  });

  final IconData icono;
  final String titulo;
  final String valor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icono, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 2),
                Text(
                  valor,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaResidente extends StatelessWidget {
  const _TarjetaResidente({
    required this.residente,
    required this.mostrarComoArchivado,
    required this.onEditarDatos,
    required this.onInactivar,
    required this.onReactivar,
  });

  final ResidenteModel residente;
  final bool mostrarComoArchivado;
  final VoidCallback onEditarDatos;
  final VoidCallback onInactivar;
  final VoidCallback onReactivar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final archivado = residente.esInactivo;

    return Opacity(
      opacity: archivado ? 0.85 : 1.0,
      child: GlassCard(
        margin: const EdgeInsets.only(bottom: 12),
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
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _detalleUbicacion(),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  if (archivado)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEA580C).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFEA580C).withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Text(
                        'Archivado',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFEA580C),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              _construirAcciones(context),
            ],
        ),
      ),
    );
  }

  Widget _construirAcciones(BuildContext context) {
    if (mostrarComoArchivado) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton.icon(
            onPressed: onReactivar,
            icon: const Icon(Icons.unarchive_outlined, size: 18),
            label: const Text('Reactivar'),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          tooltip: 'Editar datos',
          icon: const Icon(Icons.edit_outlined, size: 20),
          color: AppColors.mint,
          onPressed: onEditarDatos,
        ),
        TextButton.icon(
          onPressed: onInactivar,
          icon: const Icon(Icons.archive_outlined, size: 18),
          label: const Text('Inactivar'),
          style: TextButton.styleFrom(foregroundColor: AppColors.danger),
        ),
      ],
    );
  }

  String _detalleUbicacion() {
    final parts = <String>[
      if (residente.apartamento.isNotEmpty) residente.apartamento,
      if (residente.torre.isNotEmpty) residente.torre,
    ];
    return parts.isEmpty ? 'Sin ubicación asignada' : parts.join(' · ');
  }
}
