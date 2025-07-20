import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'package:maintenance_app/models/kanban_task.dart';
import 'package:maintenance_app/services/hive_service.dart';

// Génère un ID unique pour les nouvelles tâches
const Uuid uuid = Uuid();

class KanbanScreen extends StatefulWidget {
  const KanbanScreen({super.key});

  @override
  State<KanbanScreen> createState() => _KanbanScreenState();
}

class _KanbanScreenState extends State<KanbanScreen> {
  // Contrôleurs de texte pour le formulaire d'ajout/édition de tâche
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime? _selectedDueDate;
  Color _selectedColor = Colors.blueAccent;

  // Fonction pour afficher le sélecteur de date
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDueDate) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  // Fonction pour afficher le dialogue d'ajout/édition de tâche
  void _showTaskDialog({KanbanTask? task}) {
    // Initialise les contrôleurs avec les données de la tâche si en mode édition
    if (task != null) {
      _titleController.text = task.title;
      _descriptionController.text = task.description;
      _selectedDueDate = task.dueDate;
      _selectedColor = task.color;
    } else {
      // Réinitialise pour une nouvelle tâche
      _titleController.clear();
      _descriptionController.clear();
      _selectedDueDate = null;
      _selectedColor = Colors.blueAccent; // Couleur par défaut
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateInDialog) {
            return AlertDialog(
              title: Text(
                  task == null ? 'Ajouter une tâche' : 'Modifier la tâche'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Titre'),
                    ),
                    TextField(
                      controller: _descriptionController,
                      decoration:
                          const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                    ),
                    ListTile(
                      title: Text(
                        _selectedDueDate == null
                            ? 'Date de fin (non définie)'
                            : 'Date de fin: ${DateFormat('dd/MM/yyyy').format(_selectedDueDate!)}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        await _selectDate(context);
                        setStateInDialog(
                            () {}); // Met à jour l'état du dialogue
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text('Couleur de la tâche:'),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () {
                            // Implémentez un sélecteur de couleur simple
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text('Choisir une couleur'),
                                  content: Wrap(
                                    spacing: 8.0,
                                    runSpacing: 8.0,
                                    children: [
                                      _buildColorOption(
                                          Colors.blueAccent, setStateInDialog),
                                      _buildColorOption(Colors.purpleAccent,
                                          setStateInDialog),
                                      _buildColorOption(
                                          Colors.redAccent, setStateInDialog),
                                      _buildColorOption(
                                          Colors.greenAccent, setStateInDialog),
                                      _buildColorOption(Colors.orangeAccent,
                                          setStateInDialog),
                                      _buildColorOption(
                                          Colors.pinkAccent, setStateInDialog),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: _selectedColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade400),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                // Bouton Annuler
                TextButton(
                  child: const Text('Annuler'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                // Bouton Supprimer (apparaît seulement en mode modification)
                if (task != null) // <--- Ajout de cette condition
                  TextButton(
                    onPressed: () async {
                      final hiveService = context.read<HiveService>();
                      final bool? confirmDelete = await showDialog<bool>(
                        // <-- Attendre le résultat du dialogue
                        context:
                            context, // Utilisez le context du dialogue d'édition, il est encore valide ici.
                        builder: (ctx) => AlertDialog(
                          title: const Text('Confirmer la suppression'),
                          content: Text(
                              'Êtes-vous sûr de vouloir supprimer la tâche "${task.title}" ?'),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.of(ctx)
                                  .pop(false), // Retourne false si Annuler
                              child: const Text('Annuler'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(ctx)
                                  .pop(true), // Retourne true si Supprimer
                              child: const Text('Supprimer',
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );

                      // 3. Vérifiez la confirmation et effectuez la suppression
                      if (confirmDelete == true) {
                        hiveService.deleteKanbanTask(task.id);
                      }

                      // 4. Quoi qu'il arrive (suppression ou annulation), fermez le dialogue d'édition initial
                      if (mounted) {
                        // <--- AJOUTEZ CETTE LIGNE
                        Navigator.of(this.context)
                            .pop(); // Ferme le dialogue de modification
                      }
                      // Ferme le dialogue de modification
                    },
                    child: const Text('Supprimer',
                        style: TextStyle(color: Colors.red)),
                  ),
                // Bouton Ajouter/Modifier
                ElevatedButton(
                  child: Text(task == null ? 'Ajouter' : 'Modifier'),
                  onPressed: () {
                    if (_titleController.text.isEmpty ||
                        _selectedDueDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Veuillez remplir le titre et la date de fin.')),
                      );
                      return;
                    }
                    final hiveService = context.read<HiveService>();
                    if (task == null) {
                      final newTask = KanbanTask(
                        id: uuid.v4(),
                        title: _titleController.text,
                        description: _descriptionController.text,
                        dueDate: _selectedDueDate!,
                        status: KanbanStatus.todo,
                        colorValue: _selectedColor.toARGB32(),
                      );
                      hiveService.addOrUpdateKanbanTask(newTask);
                    } else {
                      task.title = _titleController.text;
                      task.description = _descriptionController.text;
                      task.dueDate = _selectedDueDate!;
                      task.colorValue = _selectedColor.toARGB32();
                      hiveService.addOrUpdateKanbanTask(task);
                    }
                    Navigator.of(context)
                        .pop(); // Ferme le dialogue d'ajout/modification
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildColorOption(
      Color color, Function(VoidCallback) setStateInDialog) {
    return GestureDetector(
      onTap: () {
        setStateInDialog(() {
          _selectedColor = color;
        });
        Navigator.of(context)
            .pop(); // Ferme le dialogue de sélection de couleur
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: _selectedColor == color
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 3,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Row(
          children: [
            const Text('Tableau Kanban'),
            const SizedBox(width: 12), // espace entre les deux textes
            Text(
              'Appui long sur la tâche pour faire du drag&drop',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[200] // sombre doux
                    : Colors
                        .grey[850], // un gris clair qui va bien dans l'appbar
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showTaskDialog();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Colonne "À faire"
            Expanded(
              // <--- ADDED THIS
              child: _buildKanbanColumn(
                context,
                'À faire',
                KanbanStatus.todo,
              ),
            ),
            // Colonne "En cours"
            Expanded(
              // <--- ADDED THIS
              child: _buildKanbanColumn(
                context,
                'En cours',
                KanbanStatus.inProgress,
              ),
            ),
            // Colonne "Terminé"
            Expanded(
              // <--- ADDED THIS
              child: _buildKanbanColumn(
                context,
                'Terminé',
                KanbanStatus.done,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget pour construire une colonne Kanban
  Widget _buildKanbanColumn(
      BuildContext context, String title, KanbanStatus status) {
    final hiveService = context.watch<HiveService>();
    // Récupérer les tâches filtrées par le statut de la colonne
    final tasks =
        hiveService.kanbanTasks.where((task) => task.status == status).toList();

    return DragTarget<KanbanTask>(
      // <--- Ajout de DragTarget
      onAcceptWithDetails: (details) {
        // Appelé quand une carte est déposée
        final KanbanTask droppedTask = details.data;
        if (droppedTask.status != status) {
          // Si la tâche est déposée dans une nouvelle colonne
          hiveService.updateKanbanTaskStatus(droppedTask.id, status);
          // Vous pouvez ajouter un feedback visuel ici si nécessaire
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Tâche "${droppedTask.title}" déplacée vers ${status.name}'),
            ),
          );
        }
      },
      builder: (BuildContext context, List<dynamic> accepted,
          List<dynamic> rejected) {
        // Le builder contient le contenu de la colonne
        return Container(
          width: 250, // Largeur de la colonne Kanban
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[850] // sombre doux
                : Colors.grey[200], // clair doux
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
              ),
              Divider(
                height: 1,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[400] // gris clair
                    : Colors.black26,
              ),
              Expanded(
                child: tasks.isEmpty
                    ? Center(
                        child: Text(
                          'Aucune tâche ${statusToFrench(status)}',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    : ListView.builder(
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          return _buildKanbanCard(tasks[index]);
                        },
                      ),
              ),
              // Bouton "Ajouter une tâche"
            ],
          ),
        );
      },
    );
  }

  // Widget pour construire une carte Kanban
  Widget _buildKanbanCard(KanbanTask task) {
    return LongPressDraggable<KanbanTask>(
      // Changez Draggable en LongPressDraggable
      data: task, // Les données que vous transférez pendant le drag
      feedback: Material(
        // C'est l'apparence de la carte pendant le drag
        elevation: 4.0,
        child: Container(
          padding: const EdgeInsets.all(8.0),
          width: 200, // Largeur de la carte feedback
          decoration: BoxDecoration(
            color: task.color
                .withAlpha((255 * 0.8).round()), // Couleur avec opacité
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                task.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (task.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    task.description,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Échéance: ${DateFormat('dd/MM/yyyy').format(task.dueDate)}',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging:
          Container(), // Ce qui est affiché à l'emplacement d'origine pendant le drag (peut être vide)
      child: Card(
        // Votre carte Kanban existante
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        color: task.color,
        child: InkWell(
          onTap: () => _showTaskDialog(task: task),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (task.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      task.description,
                      style:
                          const TextStyle(fontSize: 14, color: Colors.white70),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Échéance: ${DateFormat('dd/MM/yyyy').format(task.dueDate)}',
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String statusToFrench(KanbanStatus status) {
    switch (status) {
      case KanbanStatus.todo:
        return 'à faire';
      case KanbanStatus.inProgress:
        return 'en cours';
      case KanbanStatus.done:
        return 'terminée';
    }
  }
}
