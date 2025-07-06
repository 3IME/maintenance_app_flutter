import 'package:flutter/material.dart';
import 'package:maintenance_app/models/reservation.dart';
import 'package:maintenance_app/services/hive_service.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:maintenance_app/screens/planning/reservation_form_screen.dart';

class PlanningScreen extends StatefulWidget {
  const PlanningScreen({super.key});
  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> {
  final CalendarController _controller = CalendarController();
  late _DataSource _dataSource;
  CalendarView _currentView = CalendarView.timelineWorkWeek;

  @override
  void initState() {
    super.initState();
    _dataSource = _getInitialDataSource();
    _updateAppointmentsForDate(DateTime.now());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToPreviousWeek() {
    _controller.backward!();
  }

  void _goToNextWeek() {
    _controller.forward!();
  }

  void _goToToday() {
    _controller.displayDate = DateTime.now();
    _updateAppointmentsForDate(DateTime.now());
  }

  void _onCalendarTapped(CalendarTapDetails details) {
    if (details.targetElement == CalendarElement.appointment) {
      final Appointment tappedAppointment = details.appointments!.first;
      final hiveService = context.read<HiveService>();
      final originalReservation = hiveService.reservationsBox.values.firstWhere(
          (res) =>
              res.startTime == tappedAppointment.startTime &&
              res.subject == tappedAppointment.subject,
          orElse: () => Reservation());
      if (originalReservation.key == null) return;
      _navigateToForm(reservation: originalReservation);
    } else if (details.targetElement == CalendarElement.calendarCell) {
      _navigateToForm(date: details.date);
    }
  }

  Future<void> _navigateToForm(
      {Reservation? reservation, DateTime? date}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => ReservationFormScreen(
                reservation: reservation,
                initialDate: date ?? reservation?.startTime ?? DateTime.now(),
              )),
    );
    if (result == true) {
      _updateAppointmentsForDate(_controller.displayDate ?? DateTime.now());
    }
  }

  String _viewToString(CalendarView view) {
    switch (view) {
      case CalendarView.timelineDay:
        return "Jour";
      case CalendarView.timelineWorkWeek:
        return "Semaine";
      case CalendarView.month:
        return "Mois";
      case CalendarView.schedule:
        return "Liste (Tous)";
      default:
        return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    final hiveService = context.read<HiveService>();

    return Scaffold(
      appBar: AppBar(
        title: Text("Planning - ${_viewToString(_currentView)}"),
        actions: [
          if (_currentView != CalendarView.schedule)
            IconButton(
                icon: const Icon(Icons.today),
                tooltip: "Aujourd'hui",
                onPressed: _goToToday),
          if (_currentView != CalendarView.schedule)
            IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Précédent',
                onPressed: _goToPreviousWeek),
          if (_currentView != CalendarView.schedule)
            IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Suivant',
                onPressed: _goToNextWeek),
          IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Ajouter un rendez-vous',
              onPressed: () => _navigateToForm(
                  date: _controller.displayDate ?? DateTime.now())),
          PopupMenuButton<CalendarView>(
            icon: const Icon(Icons.view_module),
            tooltip: 'Changer de vue',
            onSelected: (CalendarView view) {
              setState(() {
                _currentView = view;
                _controller.view = view;
              });
            },
            itemBuilder: (BuildContext context) =>
                <PopupMenuEntry<CalendarView>>[
              const PopupMenuItem<CalendarView>(
                  value: CalendarView.timelineDay, child: Text('Jour')),
              const PopupMenuItem<CalendarView>(
                  value: CalendarView.timelineWorkWeek, child: Text('Semaine')),
              const PopupMenuItem<CalendarView>(
                  value: CalendarView.month, child: Text('Mois')),
              const PopupMenuDivider(),
              const PopupMenuItem<CalendarView>(
                  value: CalendarView.schedule, child: Text('Liste (Tous)')),
            ],
          ),
        ],
      ),
      body: SfCalendar(
        controller: _controller,
        view: _currentView,
        dataSource: _dataSource,
        firstDayOfWeek: DateTime.monday,
        onTap: _onCalendarTapped,
        onViewChanged: (ViewChangedDetails details) {
          if (_currentView != CalendarView.schedule) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _updateAppointmentsForDate(details.visibleDates.first);
            });
          }
        },
        showCurrentTimeIndicator: true,

        // --- CORRECTION : Le builder est maintenant conditionnel ---
        // On ne l'utilise QUE si la vue est 'schedule'
        appointmentBuilder: (_currentView == CalendarView.schedule)
            ? (BuildContext context, CalendarAppointmentDetails details) {
                final appointment = details.appointments.first;
                final List<String> collaboratorNames = [];
                if (appointment.resourceIds != null) {
                  for (var key in appointment.resourceIds!) {
                    final collaborator = hiveService.collaborateursBox.get(key);
                    if (collaborator != null) {
                      collaboratorNames.add(collaborator.prenom);
                    }
                  }
                }

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(
                    color: appointment.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border(
                        left: BorderSide(color: appointment.color, width: 5)),
                  ),
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(appointment.subject,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                          overflow: TextOverflow.ellipsis),
                      const Spacer(),
                      if (collaboratorNames.isNotEmpty)
                        Row(
                          children: [
                            Icon(Icons.people_alt_outlined,
                                size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Expanded(
                                child: Text(collaboratorNames.join(', '),
                                    style: TextStyle(
                                        color: Colors.grey[700], fontSize: 12),
                                    overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                    ],
                  ),
                );
              }
            : null, // Si ce n'est pas la vue schedule, on n'utilise PAS de builder.

        timeSlotViewSettings: const TimeSlotViewSettings(
            startHour: 8, endHour: 18, timeFormat: 'HH:mm'),
        monthViewSettings: const MonthViewSettings(
            appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
            showAgenda: true),
        scheduleViewSettings: const ScheduleViewSettings(
          appointmentItemHeight: 70,
          monthHeaderSettings: MonthHeaderSettings(
            height: 80,
            textAlign: TextAlign.left,
            backgroundColor: Colors.blueGrey,
            monthTextStyle: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        resourceViewSettings: const ResourceViewSettings(size: 100),
        resourceViewHeaderBuilder: (_currentView == CalendarView.timelineDay ||
                _currentView == CalendarView.timelineWorkWeek)
            ? (BuildContext context, ResourceViewHeaderDetails details) {
                final resource = details.resource;
                final String displayName = resource.displayName;
                final parts =
                    displayName.split(' ').where((p) => p.isNotEmpty).toList();
                String initials =
                    parts.isNotEmpty ? parts.first.substring(0, 1) : '?';
                if (parts.length > 1) initials += parts.last.substring(0, 1);
                return Container(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                              radius: 15,
                              backgroundColor: resource.color,
                              child: Text(initials.toUpperCase(),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold))),
                          const SizedBox(height: 4),
                          Text(displayName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12))
                        ]));
              }
            : null,
      ),
    );
  }

  void _updateAppointmentsForDate(DateTime date) {
    final hiveService = context.read<HiveService>();
    final List<Appointment> newAppointments = [];
    final reservations = hiveService.reservationsBox.values.toList();
    for (final reservation in reservations) {
      newAppointments.add(Appointment(
          startTime: reservation.startTime,
          endTime: reservation.endTime,
          subject: reservation.subject,
          color: reservation.color,
          resourceIds: List<Object>.from(reservation.resourceIds)));
    }
    _dataSource.appointments = newAppointments;
    _dataSource.notifyListeners(
        CalendarDataSourceAction.reset, newAppointments);
  }

  _DataSource _getInitialDataSource() {
    final hiveService = context.read<HiveService>();
    final List<CalendarResource> resources = [];
    final collaborateurs = hiveService.collaborateursBox.values.toList();
    final List<Color> userColors = [
      Colors.blue,
      Colors.green,
      Colors.red,
      Colors.orange,
      Colors.purple,
      Colors.teal
    ];
    int colorIndex = 0;
    for (final collab in collaborateurs) {
      resources.add(CalendarResource(
          displayName: collab.nomComplet,
          id: collab.key,
          color: userColors[colorIndex % userColors.length]));
      colorIndex++;
    }
    return _DataSource(<Appointment>[], resources);
  }
}

class _DataSource extends CalendarDataSource {
  _DataSource(List<Appointment> source, List<CalendarResource> resourceColl) {
    appointments = source;
    resources = resourceColl;
  }
}
