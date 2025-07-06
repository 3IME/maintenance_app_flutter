import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maintenance_app/models/reservation.dart';
import 'package:maintenance_app/services/hive_service.dart';
import 'package:provider/provider.dart';

class ReservationFormScreen extends StatefulWidget {
  final Reservation? reservation;
  final DateTime initialDate;

  const ReservationFormScreen({
    super.key,
    this.reservation,
    required this.initialDate,
  });

  @override
  State<ReservationFormScreen> createState() => _ReservationFormScreenState();
}

class _ReservationFormScreenState extends State<ReservationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _subjectController;
  late Color _selectedColor;
  late DateTime _startTime;
  late DateTime _endTime;
  late bool _isAllDay;
  late List<dynamic> _selectedCollaborateurKeys;

  final List<Color> _availableColors = [
    Colors.blue,
    Colors.green,
    Colors.red,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.brown,
    Colors.grey,
    Colors.cyan
  ];
  bool get isEditing => widget.reservation != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _subjectController =
          TextEditingController(text: widget.reservation!.subject);
      _selectedColor = widget.reservation!.color;
      _startTime = widget.reservation!.startTime;
      _endTime = widget.reservation!.endTime;
      _isAllDay = widget.reservation!.startTime.hour == 0 &&
          widget.reservation!.startTime.minute == 0 &&
          widget.reservation!.endTime.hour == 23 &&
          widget.reservation!.endTime.minute == 59;
      _selectedCollaborateurKeys = List.from(widget.reservation!.resourceIds);
    } else {
      _subjectController = TextEditingController();
      _selectedColor = _availableColors.first;
      _startTime = widget.initialDate;
      _endTime = widget.initialDate.add(const Duration(hours: 1));
      _isAllDay = false;
      _selectedCollaborateurKeys = [];
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_selectedCollaborateurKeys.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Veuillez assigner au moins un collaborateur.')));
        return;
      }

      final reservation = widget.reservation ?? Reservation();
      reservation.subject = _subjectController.text;
      reservation.colorValue = _selectedColor.value;
      reservation.resourceIds = _selectedCollaborateurKeys;

      if (_isAllDay) {
        reservation.startTime =
            DateTime(_startTime.year, _startTime.month, _startTime.day, 0, 0);
        reservation.endTime =
            DateTime(_endTime.year, _endTime.month, _endTime.day, 23, 59);
      } else {
        reservation.startTime = _startTime;
        reservation.endTime = _endTime;
      }

      context.read<HiveService>().addOrUpdateReservation(reservation);
      Navigator.of(context).pop(true);
    }
  }

  // --- NOUVELLE FONCTION POUR LA SUPPRESSION ---
  void _deleteReservation() {
    // On s'assure qu'on est bien en mode modification
    if (!isEditing) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text('Voulez-vous vraiment supprimer ce rendez-vous ?'),
        actions: [
          TextButton(
            child: const Text('Annuler'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
            onPressed: () {
              context
                  .read<HiveService>()
                  .deleteReservation(widget.reservation!.key);
              // On ferme la boîte de dialogue
              Navigator.of(ctx).pop();
              // On ferme l'écran de formulaire et on retourne 'true' pour rafraîchir
              Navigator.of(context).pop(true);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier le RDV' : 'Nouveau RDV'),
        actions: [
          // --- MODIFICATION : On ajoute une icône de suppression ---
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteReservation,
              tooltip: 'Supprimer',
            ),
          IconButton(
              icon: const Icon(Icons.save),
              onPressed: _submitForm,
              tooltip: 'Enregistrer'),
        ],
      ),
      body: Form(
        // Le reste de la méthode build ne change pas...
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(
                    labelText: 'Titre / Sujet', border: OutlineInputBorder()),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Le titre est requis'
                    : null,
              ),
              const SizedBox(height: 20),
              const Text('Collaborateurs assignés',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              _buildCollaboratorsChips(),
              const SizedBox(height: 20),
              const Text('Couleur',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _availableColors
                    .map((color) => GestureDetector(
                          onTap: () => setState(() => _selectedColor = color),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: color,
                            child: _selectedColor == color
                                ? const Icon(Icons.check, color: Colors.white)
                                : null,
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 20),
              CheckboxListTile(
                title: const Text('Toute la journée'),
                value: _isAllDay,
                onChanged: (value) => setState(() => _isAllDay = value!),
              ),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Début'),
                subtitle:
                    Text(DateFormat('dd/MM/yyyy HH:mm').format(_startTime)),
                onTap: _isAllDay ? null : _pickStartTime,
              ),
              ListTile(
                leading: const Icon(Icons.access_time_filled),
                title: const Text('Fin'),
                subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(_endTime)),
                onTap: _isAllDay ? null : _pickEndTime,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCollaboratorsChips() {
    final collaborateurs =
        context.read<HiveService>().collaborateursBox.values.toList();
    return Wrap(
      spacing: 8.0,
      children: collaborateurs.map((collab) {
        final isSelected = _selectedCollaborateurKeys.contains(collab.key);
        return FilterChip(
          label: Text(collab.nomComplet),
          selected: isSelected,
          onSelected: (bool selected) {
            setState(() {
              if (selected) {
                _selectedCollaborateurKeys.add(collab.key);
              } else {
                _selectedCollaborateurKeys.remove(collab.key);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Future<void> _pickStartTime() async {
    final date = await showDatePicker(
        context: context,
        initialDate: _startTime,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030));
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(_startTime));
    if (time == null) return;
    setState(() {
      _startTime =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
      if (_startTime.isAfter(_endTime)) {
        _endTime = _startTime.add(const Duration(hours: 1));
      }
    });
  }

  Future<void> _pickEndTime() async {
    final date = await showDatePicker(
        context: context,
        initialDate: _endTime,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030));
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(_endTime));
    if (time == null) return;
    setState(() {
      _endTime =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }
}
