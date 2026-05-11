import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../Models/reserva_model.dart';
import '../Services/firebase_reserva_repository.dart';

/// Pantalla para que el residente reserve una zona común en una fecha
/// usando `table_calendar` y persistiendo en Firestore.
class ReservasScreen extends StatefulWidget {
  const ReservasScreen({
    super.key,
    this.nombre = 'Residente',
    this.apartamento = '',
    this.torre = '',
    this.zonaInicial,
  });

  /// Datos del residente que se almacenarán junto con la reserva.
  final String nombre;
  final String apartamento;
  final String torre;

  /// Si viene desde el grid de categorías, preselecciona esta zona.
  final String? zonaInicial;

  @override
  State<ReservasScreen> createState() => _ReservasScreenState();
}

class _ReservasScreenState extends State<ReservasScreen> {
  final _repo = FirebaseReservaRepository();

  late DateTime _focusedDay;
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  late String _zonaSeleccionada;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final hoy = DateTime.now();
    _focusedDay = DateTime(hoy.year, hoy.month, hoy.day);
    _selectedDay = _focusedDay;
    final inicial = widget.zonaInicial;
    _zonaSeleccionada = (inicial != null && ZonasComunes.todas.contains(inicial))
        ? inicial
        : ZonasComunes.piscina;
  }

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservar Zonas',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _construirCalendario(),
              const SizedBox(height: 20),
              const Text('Zona común',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B))),
              const SizedBox(height: 10),
              _construirSelectorZona(),
              const SizedBox(height: 20),
              _construirBotonReservar(),
              const SizedBox(height: 24),
              const Text('Mis reservas',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B))),
              const SizedBox(height: 8),
              _construirListaReservas(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirCalendario() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: TableCalendar(
          firstDay: DateTime.now().subtract(const Duration(days: 1)),
          lastDay: DateTime.now().add(const Duration(days: 365)),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          startingDayOfWeek: StartingDayOfWeek.monday,
          availableCalendarFormats: const {
            CalendarFormat.month: 'Mes',
            CalendarFormat.twoWeeks: '2 sem.',
            CalendarFormat.week: 'Semana',
          },
          selectedDayPredicate: (day) =>
              _selectedDay != null && isSameDay(day, _selectedDay),
          onDaySelected: (selected, focused) {
            setState(() {
              _selectedDay = DateTime(selected.year, selected.month, selected.day);
              _focusedDay = focused;
            });
          },
          onFormatChanged: (format) {
            setState(() => _calendarFormat = format);
          },
          onPageChanged: (focused) => _focusedDay = focused,
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: const Color(0xFF93C5FD),
              shape: BoxShape.circle,
            ),
            selectedDecoration: const BoxDecoration(
              color: Color(0xFF2563EB),
              shape: BoxShape.circle,
            ),
            weekendTextStyle: const TextStyle(color: Color(0xFFEF4444)),
          ),
          headerStyle: const HeaderStyle(
            formatButtonShowsNext: false,
            titleCentered: true,
            formatButtonDecoration: BoxDecoration(
              color: Color(0xFFE0E7FF),
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            formatButtonTextStyle: TextStyle(
              color: Color(0xFF1E3A8A),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _construirSelectorZona() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ZonasComunes.todas.map((zona) {
        final seleccionada = zona == _zonaSeleccionada;
        return ChoiceChip(
          label: Text(zona),
          selected: seleccionada,
          selectedColor: const Color(0xFF2563EB),
          backgroundColor: Colors.white,
          labelStyle: TextStyle(
            color: seleccionada ? Colors.white : const Color(0xFF1E293B),
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: seleccionada
                  ? Colors.transparent
                  : Colors.grey.withValues(alpha: 0.4),
            ),
          ),
          onSelected: (_) => setState(() => _zonaSeleccionada = zona),
        );
      }).toList(),
    );
  }

  Widget _construirBotonReservar() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton.icon(
        onPressed: _guardando ? null : _guardarReserva,
        icon: _guardando
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.event_available),
        label: Text(_guardando ? 'Guardando...' : 'Reservar'),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF1E3A8A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _construirListaReservas() {
    final uid = _uid;
    if (uid == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('Inicia sesión para ver tus reservas.'),
      );
    }

    return StreamBuilder<List<Reserva>>(
      stream: _repo.streamReservasDeResidente(uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text('Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red)),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final lista = snapshot.data ?? const <Reserva>[];
        if (lista.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Aún no tienes reservas.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: lista.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final r = lista[index];
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFE0E7FF),
                  child: Icon(_iconoZona(r.zona), color: const Color(0xFF1E3A8A)),
                ),
                title: Text(r.zona,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(_formatearFechaLarga(r.fecha)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () => _confirmarEliminar(r),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _guardarReserva() async {
    final uid = _uid;
    if (uid == null) {
      _mostrarMensaje('Debes iniciar sesión para reservar.');
      return;
    }
    final fecha = _selectedDay;
    if (fecha == null) {
      _mostrarMensaje('Selecciona una fecha en el calendario.');
      return;
    }

    setState(() => _guardando = true);
    try {
      final yaExiste = await _repo.existeReservaEn(
        fecha: fecha,
        zona: _zonaSeleccionada,
      );
      if (yaExiste) {
        _mostrarMensaje(
          '$_zonaSeleccionada ya está reservada el ${_formatearFechaCorta(fecha)}.',
        );
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      final nombre = widget.nombre.isNotEmpty
          ? widget.nombre
          : (user?.displayName?.trim().isNotEmpty == true
              ? user!.displayName!
              : (user?.email?.split('@').first ?? 'Residente'));

      await _repo.crear(
        Reserva(
          id: '',
          residenteUid: uid,
          residenteNombre: nombre,
          apartamento: widget.apartamento,
          torre: widget.torre,
          zona: _zonaSeleccionada,
          fecha: fecha,
        ),
      );
      _mostrarMensaje(
        'Reserva guardada: $_zonaSeleccionada el ${_formatearFechaCorta(fecha)}.',
      );
    } catch (e) {
      _mostrarMensaje('Error al guardar: $e');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _confirmarEliminar(Reserva r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar reserva'),
        content: Text(
            '¿Cancelar la reserva de ${r.zona} para el ${_formatearFechaCorta(r.fecha)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await _repo.eliminar(r.id);
        _mostrarMensaje('Reserva eliminada.');
      } catch (e) {
        _mostrarMensaje('Error al eliminar: $e');
      }
    }
  }

  void _mostrarMensaje(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), duration: const Duration(seconds: 2)),
    );
  }

  IconData _iconoZona(String zona) {
    switch (zona) {
      case ZonasComunes.piscina:
        return Icons.pool;
      case ZonasComunes.bbq:
        return Icons.outdoor_grill;
      case ZonasComunes.salonSocial:
        return Icons.celebration;
      case ZonasComunes.cancha:
        return Icons.sports_soccer;
      case ZonasComunes.cine:
        return Icons.movie;
      default:
        return Icons.event;
    }
  }

  String _formatearFechaCorta(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String _formatearFechaLarga(DateTime d) {
    const dias = [
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
      'domingo'
    ];
    const meses = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre'
    ];
    final diaSemana = dias[d.weekday - 1];
    final mes = meses[d.month - 1];
    return '${diaSemana[0].toUpperCase()}${diaSemana.substring(1)} '
        '${d.day} de $mes ${d.year}';
  }
}
