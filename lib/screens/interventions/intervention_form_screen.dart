// lib/screens/interventions/intervention_form_screen.dart

import 'package:flutter/material.dart';
import 'package:maintenance_app/models/equipement.dart';
import 'package:maintenance_app/models/intervention.dart';
import 'package:maintenance_app/services/hive_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class InterventionFormScreen extends StatefulWidget {
  final Intervention? intervention;
  final String? initialEquipmentId; // Pour pré-sélectionner un équipement

  const InterventionFormScreen(
      {super.key, this.intervention, this.initialEquipmentId});

  @override
  State<InterventionFormScreen> createState() => _InterventionFormScreenState();
}

class _InterventionFormScreenState extends State<InterventionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final Uuid _uuid = const Uuid();

  // Contrôleurs et variables d'état
  String? _selectedEquipmentId;
  DateTime _dateDebut = DateTime.now();
  DateTime _dateFin = DateTime.now().add(const Duration(days: 1));
  String _type = 'Préventive';
  bool _urgence = false;
  final TextEditingController _coutController = TextEditingController();
  final TextEditingController _dureeController = TextEditingController();
  final TextEditingController _dateDebutController = TextEditingController();
  final TextEditingController _dateFinController = TextEditingController();

  List<Equipement> _equipements = [];

  @override
  void initState() {
    super.initState();
    final hiveService = Provider.of<HiveService>(context, listen: false);
    _equipements = hiveService.equipementsBox.values.toList();

    // Pré-remplissage si on modifie une intervention
    if (widget.intervention != null) {
      _selectedEquipmentId = widget.intervention!.equipmentId;
      _dateDebut = widget.intervention!.dateDebut;
      _dateFin = widget.intervention!.dateFin;
      _type = widget.intervention!.type;
      _urgence = widget.intervention!.urgence;
      _coutController.text = widget.intervention!.cout.toString();
      _dureeController.text = widget.intervention!.dureeHeures.toString();
    } else if (widget.initialEquipmentId != null) {
      _selectedEquipmentId = widget.initialEquipmentId;
    }

    _dateDebutController.text = DateFormat.yMd('fr_FR').format(_dateDebut);
    _dateFinController.text = DateFormat.yMd('fr_FR').format(_dateFin);
  }

  @override
  void dispose() {
    _coutController.dispose();
    _dureeController.dispose();
    _dateDebutController.dispose();
    _dateFinController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _dateDebut : _dateFin,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _dateDebut = picked;
          _dateDebutController.text = DateFormat.yMd('fr_FR').format(picked);
        } else {
          _dateFin = picked;
          _dateFinController.text = DateFormat.yMd('fr_FR').format(picked);
        }
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final hiveService = Provider.of<HiveService>(context, listen: false);

      final intervention = Intervention(
        id: widget.intervention?.id ?? _uuid.v4(),
        equipmentId: _selectedEquipmentId!,
        dateDebut: _dateDebut,
        dateFin: _dateFin,
        type: _type,
        cout: double.tryParse(_coutController.text) ?? 0.0,
        dureeHeures: int.tryParse(_dureeController.text) ?? 0,
        urgence: _urgence,
      );

      hiveService.addOrUpdateIntervention(intervention);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.intervention == null
            ? 'Ajouter une intervention'
            : 'Modifier l\'intervention'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // --- Sélecteur d'équipement ---
              DropdownButtonFormField<String>(
                value: _selectedEquipmentId,
                items: _equipements.map((equipement) {
                  return DropdownMenuItem(
                    value: equipement.id,
                    child: Text(equipement.nom),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedEquipmentId = value;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Équipement concerné',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null
                    ? 'Veuillez sélectionner un équipement.'
                    : null,
              ),
              const SizedBox(height: 16),
              // --- Type d'intervention ---
              DropdownButtonFormField<String>(
                value: _type,
                items: ['Préventive', 'Corrective'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _type = newValue!;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Type d\'intervention',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              // --- Dates ---
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _dateDebutController,
                      decoration: const InputDecoration(
                          labelText: 'Date de début',
                          border: OutlineInputBorder()),
                      readOnly: true,
                      onTap: () => _selectDate(context, true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _dateFinController,
                      decoration: const InputDecoration(
                          labelText: 'Date de fin',
                          border: OutlineInputBorder()),
                      readOnly: true,
                      onTap: () => _selectDate(context, false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // --- Coût et Durée ---
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _coutController,
                      decoration: const InputDecoration(
                          labelText: 'Coût (€)', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (value) => value!.isEmpty ? 'Requis' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _dureeController,
                      decoration: const InputDecoration(
                          labelText: 'Durée (h)', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (value) => value!.isEmpty ? 'Requis' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // --- Urgence ---
              SwitchListTile(
                title: const Text('Intervention Urgente'),
                value: _urgence,
                onChanged: (bool value) {
                  setState(() {
                    _urgence = value;
                  });
                },
                secondary: Icon(_urgence ? Icons.flash_on : Icons.flash_off),
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
              )
            ],
          ),
        ),
      ),
    );
  }
}
