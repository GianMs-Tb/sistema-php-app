import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';

import '../Models/reserva_model.dart';
import '../Services/firebase_reserva_repository.dart';
import '../Widgets/glass_card.dart';
import '../Widgets/reserva_glass_card.dart';
import '../theme/app_theme.dart';

/// Pantalla para reservar zonas comunes con calendario, hora y tarjetas glass.
class ReservasScreen extends StatefulWidget {
  const ReservasScreen({
    super.key,
    this.nombre = 'Residente',
    this.apartamento = '',
    this.torre = '',
    this.zonaInicial,
  });

  final String nombre;
  final String apartamento;
  final String torre;
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
  String? _horaSeleccionada;
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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.navy,
      appBar: AppBar(title: const Text('Reservar Zonas')),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _construirCalendario(),
              const SizedBox(height: 20),
              Text('Zona común', style: theme.textTheme.titleMedium),
              const SizedBox(height: 10),
              _construirSelectorZona(),
              const SizedBox(height: 20),
              Text('Hora de la reserva', style: theme.textTheme.titleMedium),
              const SizedBox(height: 10),
              _construirSelectorHora(),
              const SizedBox(height: 20),
              _construirBotonReservar(),
              const SizedBox(height: 24),
              Text('Mis reservas', style: theme.textTheme.titleMedium),
              const SizedBox(height: 10),
              _construirListaReservas(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirCalendario() {
    return GlassCard(
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
          defaultTextStyle: GoogleFonts.inter(color: AppColors.textPrimary),
          weekendTextStyle: GoogleFonts.inter(color: AppColors.danger),
          outsideTextStyle: GoogleFonts.inter(color: AppColors.textSecondary),
          todayDecoration: BoxDecoration(
            color: AppColors.mint.withValues(alpha: 0.25),
            shape: BoxShape.circle,
          ),
          todayTextStyle: GoogleFonts.inter(
            color: AppColors.mint,
            fontWeight: FontWeight.w700,
          ),
          selectedDecoration: const BoxDecoration(
            color: AppColors.mint,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: GoogleFonts.inter(
            color: AppColors.navy,
            fontWeight: FontWeight.w800,
          ),
        ),
        headerStyle: HeaderStyle(
          formatButtonShowsNext: false,
          titleCentered: true,
          titleTextStyle: GoogleFonts.poppins(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          leftChevronIcon: const Icon(Icons.chevron_left, color: AppColors.mint),
          rightChevronIcon: const Icon(Icons.chevron_right, color: AppColors.mint),
          formatButtonDecoration: BoxDecoration(
            color: AppColors.mint.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.mint.withValues(alpha: 0.35)),
          ),
          formatButtonTextStyle: GoogleFonts.inter(
            color: AppColors.mint,
            fontWeight: FontWeight.w700,
          ),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
          weekendStyle: GoogleFonts.inter(
            color: AppColors.danger,
            fontSize: 12,
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
        return FilterChip(
          label: Text(zona),
          selected: seleccionada,
          showCheckmark: false,
          selectedColor: AppColors.mint,
          backgroundColor: AppColors.slate.withValues(alpha: 0.6),
          labelStyle: GoogleFonts.inter(
            color: seleccionada ? AppColors.navy : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          side: BorderSide(
            color: seleccionada
                ? AppColors.mint
                : AppColors.glassBorder,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          onSelected: (_) => setState(() => _zonaSeleccionada = zona),
        );
      }).toList(),
    );
  }

  Widget _construirSelectorHora() {
    final tieneHora = _horaSeleccionada != null && _horaSeleccionada!.isNotEmpty;
    return GlassCard(
      onTap: _seleccionarHora,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Icon(
            Icons.schedule_rounded,
            color: tieneHora ? AppColors.mint : AppColors.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tieneHora ? _horaSeleccionada! : 'Seleccionar Hora',
              style: GoogleFonts.inter(
                color: tieneHora ? AppColors.mint : AppColors.textSecondary,
                fontSize: 15,
                fontWeight: tieneHora ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary.withValues(alpha: 0.8),
          ),
        ],
      ),
    );
  }

  Future<void> _seleccionarHora() async {
    final partes = _horaSeleccionada?.split(':');
    TimeOfDay inicial = TimeOfDay.now();
    if (partes != null && partes.length == 2) {
      final h = int.tryParse(partes[0]);
      final m = int.tryParse(partes[1]);
      if (h != null && m != null) {
        inicial = TimeOfDay(hour: h, minute: m);
      }
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: inicial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.mint,
              onPrimary: AppColors.navy,
              surface: AppColors.slate,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _horaSeleccionada =
            '${picked.hour.toString().padLeft(2, '0')}:'
            '${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Widget _construirBotonReservar() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: _guardando ? null : _guardarReserva,
        icon: _guardando
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.navy,
                ),
              )
            : const Icon(Icons.event_available),
        label: Text(_guardando ? 'Guardando...' : 'Reservar'),
      ),
    );
  }

  Widget _construirListaReservas() {
    final uid = _uid;
    if (uid == null) {
      return Text(
        'Inicia sesión para ver tus reservas.',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    return StreamBuilder<List<Reserva>>(
      stream: _repo.streamReservasDeResidente(uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text(
            'Error: ${snapshot.error}',
            style: const TextStyle(color: AppColors.danger),
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
          return Text(
            'Aún no tienes reservas.',
            style: Theme.of(context).textTheme.bodyMedium,
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: lista.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final r = lista[index];
            return ReservaGlassCard(
              reserva: r,
              onDelete: () => _confirmarEliminar(r),
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
    if (_horaSeleccionada == null || _horaSeleccionada!.isEmpty) {
      _mostrarMensaje('Selecciona la hora de la reserva.');
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
          hora: _horaSeleccionada!,
        ),
      );
      _mostrarMensaje(
        'Reserva guardada: $_zonaSeleccionada el ${_formatearFechaCorta(fecha)} '
        'a las $_horaSeleccionada.',
      );
    } catch (e) {
      _mostrarMensaje('Error al guardar: $e');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _confirmarEliminar(Reserva r) async {
    final horaTxt = r.hora.isNotEmpty ? ' a las ${r.hora}' : '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar reserva'),
        content: Text(
          '¿Cancelar la reserva de ${r.zona} para el '
          '${_formatearFechaCorta(r.fecha)}$horaTxt?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
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

  String _formatearFechaCorta(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}
