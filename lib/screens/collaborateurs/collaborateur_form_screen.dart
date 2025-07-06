// lib/screens/collaborateurs/collaborateur_form_screen.dart

import 'package:flutter/material.dart';
import 'package:maintenance_app/models/collaborateur.dart';
import 'package:maintenance_app/models/role.dart';
import 'package:maintenance_app/services/hive_service.dart';
import 'package:provider/provider.dart';

class CollaborateurFormScreen extends StatefulWidget {
  // On accepte un collaborateur optionnel pour la modification
  final Collaborateur? collaborateur;

  const CollaborateurFormScreen({super.key, this.collaborateur});

  @override
  State<CollaborateurFormScreen> createState() =>
      _CollaborateurFormScreenState();
}

class _CollaborateurFormScreenState extends State<CollaborateurFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _prenomController;
  late TextEditingController _nomController;
  late Role _selectedRole;

  // Détermine si on est en mode "Ajout" ou "Modification"
  bool get isEditing => widget.collaborateur != null;

  @override
  void initState() {
    super.initState();
    // On initialise les contrôleurs et la valeur du rôle
    _prenomController =
        TextEditingController(text: widget.collaborateur?.prenom ?? '');
    _nomController =
        TextEditingController(text: widget.collaborateur?.nom ?? '');
    _selectedRole = widget.collaborateur?.fonction ??
        Role.technicien; // Défaut à 'technicien' si ajout
  }

  @override
  void dispose() {
    // Il faut toujours "dispose" les contrôleurs pour libérer la mémoire
    _prenomController.dispose();
    _nomController.dispose();
    super.dispose();
  }

  void _submitForm() {
    // On vérifie si le formulaire est valide
    if (_formKey.currentState!.validate()) {
      // On crée ou on met à jour l'objet collaborateur
      final collaborateur = widget.collaborateur ?? Collaborateur();
      collaborateur.prenom = _prenomController.text;
      collaborateur.nom = _nomController.text;
      collaborateur.fonction = _selectedRole;

      // On utilise le service pour sauvegarder dans Hive
      // context.read est utilisé dans les callbacks comme onPressed
      context.read<HiveService>().addOrUpdateCollaborateur(collaborateur);

      // On revient à l'écran précédent
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Le titre de la page s'adapte en fonction du mode
        title: Text(isEditing
            ? 'Modifier le collaborateur'
            : 'Ajouter un collaborateur'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _prenomController,
                decoration: const InputDecoration(
                    labelText: 'Prénom', border: OutlineInputBorder()),
                validator: (value) =>
                    value!.trim().isEmpty ? 'Le prénom est requis' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(
                    labelText: 'Nom', border: OutlineInputBorder()),
                validator: (value) =>
                    value!.trim().isEmpty ? 'Le nom est requis' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Role>(
                value: _selectedRole,
                decoration: const InputDecoration(
                    labelText: 'Fonction', border: OutlineInputBorder()),
                items: Role.values.map((Role role) {
                  return DropdownMenuItem<Role>(
                    value: role,
                    // Affiche le nom avec la première lettre en majuscule
                    child: Text(
                        role.name[0].toUpperCase() + role.name.substring(1)),
                  );
                }).toList(),
                onChanged: (newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedRole = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                child: Text(isEditing ? 'Mettre à jour' : 'Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
