// lib/screens/equipements/equipement_form_screen.dart

import 'package:flutter/material.dart';
import 'package:maintenance_app/models/equipement.dart';
import 'package:maintenance_app/services/hive_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class EquipementFormScreen extends StatefulWidget {
  // On rend le formulaire réutilisable pour la modification
  final Equipement? equipement;

  const EquipementFormScreen({super.key, this.equipement});

  @override
  EquipementFormScreenState createState() => EquipementFormScreenState();
}

class EquipementFormScreenState extends State<EquipementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _nom;
  late String _type;
  late DateTime _dateMiseEnService;

  late TextEditingController _dateController;
  final Uuid _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    // Si on modifie, on pré-remplit les champs
    // Sinon, on initialise avec des valeurs par défaut
    _nom = widget.equipement?.nom ?? '';
    _type = widget.equipement?.type ?? '';
    _dateMiseEnService = widget.equipement?.dateMiseEnService ?? DateTime.now();

    // Le contrôleur pour le champ de date
    _dateController = TextEditingController(
        text: DateFormat.yMd('fr_FR').format(_dateMiseEnService));
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  // Affiche un calendrier pour choisir la date
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateMiseEnService,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      locale: const Locale('fr', 'FR'), // Pour avoir le calendrier en français
    );
    if (picked != null && picked != _dateMiseEnService) {
      setState(() {
        _dateMiseEnService = picked;
        _dateController.text =
            DateFormat.yMd('fr_FR').format(_dateMiseEnService);
      });
    }
  }

  // Soumet le formulaire
  void _submitForm() {
    // On vérifie si le formulaire est valide
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save(); // Exécute les onSaved de chaque champ

      final hiveService = Provider.of<HiveService>(context, listen: false);

      final equipement = Equipement(
        // Si on modifie, on garde l'ID existant. Sinon on en génère un nouveau.
        id: widget.equipement?.id ?? _uuid.v4(),
        nom: _nom,
        type: _type,
        dateMiseEnService: _dateMiseEnService,
      );

      hiveService.addOrUpdateEquipement(equipement);

      // On retourne à l'écran précédent
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Le titre change selon si on ajoute ou modifie
        title: Text(widget.equipement == null
            ? 'Ajouter un équipement'
            : 'Modifier l\'équipement'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            // ListView pour éviter les problèmes de clavier sur petits écrans
            children: <Widget>[
              TextFormField(
                initialValue: _nom,
                decoration: const InputDecoration(
                  labelText: 'Nom de l\'équipement',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.precision_manufacturing),
                ),
                validator: (value) =>
                    value!.trim().isEmpty ? 'Veuillez entrer un nom.' : null,
                onSaved: (value) => _nom = value!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: 'Type (ex: Machine, Transport)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                validator: (value) =>
                    value!.trim().isEmpty ? 'Veuillez entrer un type.' : null,
                onSaved: (value) => _type = value!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: 'Date de mise en service',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true, // Le champ n'est pas éditable directement
                onTap: () =>
                    _selectDate(context), // Ouvre le calendrier au clic
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _submitForm,
                icon: const Icon(Icons.save),
                label: const Text('Enregistrer'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(fontSize: 18),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
