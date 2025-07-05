// lib/screens/pannes/panne_form_screen.dart

import 'package:flutter/material.dart';
import 'package:maintenance_app/models/equipement.dart';
import 'package:maintenance_app/models/panne.dart';
import 'package:maintenance_app/services/hive_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class PanneFormScreen extends StatefulWidget {
  final Panne? panne;
  final String? initialEquipmentId;

  const PanneFormScreen({super.key, this.panne, this.initialEquipmentId});

  @override
  State<PanneFormScreen> createState() => _PanneFormScreenState();
}

class _PanneFormScreenState extends State<PanneFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final Uuid _uuid = const Uuid();

  String? _selectedEquipmentId;
  DateTime _datePanne = DateTime.now();
  DateTime? _dateReparation;
  late TextEditingController _causeController;
  late TextEditingController _datePanneController;
  late TextEditingController _dateReparationController;

  List<Equipement> _equipements = [];

  @override
  void initState() {
    super.initState();
    final hiveService = Provider.of<HiveService>(context, listen: false);
    _equipements = hiveService.equipementsBox.values.toList();

    _causeController = TextEditingController(text: widget.panne?.cause ?? '');
    _selectedEquipmentId =
        widget.panne?.equipmentId ?? widget.initialEquipmentId;
    _datePanne = widget.panne?.datePanne ?? DateTime.now();
    _dateReparation = widget.panne?.dateReparation;

    _datePanneController =
        TextEditingController(text: DateFormat.yMd('fr_FR').format(_datePanne));
    _dateReparationController = TextEditingController(
        text: _dateReparation != null
            ? DateFormat.yMd('fr_FR').format(_dateReparation!)
            : '');
  }

  @override
  void dispose() {
    _causeController.dispose();
    _datePanneController.dispose();
    _dateReparationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isPanneDate) async {
    // On s'assure que la date initiale n'est jamais nulle.
    // Pour la date de réparation, si elle est nulle, on propose la date du jour.
    DateTime initialDate;
    if (isPanneDate) {
      initialDate = _datePanne;
    } else {
      initialDate = _dateReparation ?? DateTime.now();
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate, // On utilise notre date initiale sécurisée
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      locale: const Locale('fr', 'FR'),
    );

    if (picked != null) {
      setState(() {
        if (isPanneDate) {
          _datePanne = picked;
          _datePanneController.text = DateFormat.yMd('fr_FR').format(picked);
        } else {
          _dateReparation = picked;
          _dateReparationController.text =
              DateFormat.yMd('fr_FR').format(picked);
        }
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final hiveService = Provider.of<HiveService>(context, listen: false);

      final panne = Panne(
        id: widget.panne?.id ?? _uuid.v4(),
        equipmentId: _selectedEquipmentId!,
        datePanne: _datePanne,
        dateReparation: _dateReparation,
        cause: _causeController.text,
      );

      hiveService.addOrUpdatePanne(panne);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.panne == null ? 'Signaler une panne' : 'Modifier la panne'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                value: _selectedEquipmentId,
                items: _equipements
                    .map((e) =>
                        DropdownMenuItem(value: e.id, child: Text(e.nom)))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedEquipmentId = value),
                decoration: const InputDecoration(
                    labelText: 'Équipement en panne',
                    border: OutlineInputBorder()),
                validator: (value) => value == null
                    ? 'Veuillez sélectionner un équipement.'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _causeController,
                decoration: const InputDecoration(
                    labelText: 'Cause de la panne',
                    border: OutlineInputBorder()),
                validator: (value) =>
                    value!.trim().isEmpty ? 'Veuillez décrire la cause.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _datePanneController,
                decoration: const InputDecoration(
                    labelText: 'Date de la panne',
                    border: OutlineInputBorder()),
                readOnly: true,
                onTap: () => _selectDate(context, true),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dateReparationController,
                decoration: InputDecoration(
                    labelText: 'Date de réparation (optionnel)',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _dateReparation = null;
                          _dateReparationController.clear();
                        });
                      },
                    )),
                readOnly: true,
                onTap: () => _selectDate(context, false),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _submitForm,
                icon: const Icon(Icons.save),
                label: const Text('Enregistrer'),
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
