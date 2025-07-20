import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintenance_app/models/equipement.dart';
import 'package:maintenance_app/models/intervention.dart';
import 'package:maintenance_app/models/panne.dart';
import 'package:maintenance_app/models/article.dart';
import 'package:uuid/uuid.dart';
import 'package:maintenance_app/models/reservation.dart';

// Import des nouveaux modèles
import 'package:maintenance_app/models/collaborateur.dart';
import 'package:maintenance_app/models/role.dart';

// IMPORTANT: Assurez-vous que ces imports sont présents
import 'package:maintenance_app/models/kanban_task.dart'; // Pour KanbanTask et KanbanStatus
import 'package:flutter/material.dart'; // Pour Colors (utilisé dans les données de démo)

class HiveService extends ChangeNotifier {
  // Constantes pour les noms des "boîtes" (tables)
  static const String equipementsBoxName = 'equipements';
  static const String interventionsBoxName = 'interventions';
  static const String pannesBoxName = 'pannes';
  static const String collaborateursBoxName = 'collaborateurs';
  static const String reservationsBoxName = 'reservations';
  static const String articlesBoxName = 'articles';
  static const String kanbanTasksBoxName =
      'kanbanTasks'; // Nouvelle boîte pour Kanban

  var uuid = const Uuid();

  // Déclaration des boîtes directement pour les getters
  late Box<Equipement> _equipementsBox;
  late Box<Intervention> _interventionsBox;
  late Box<Panne> _pannesBox;
  late Box<Collaborateur> _collaborateursBox;
  late Box<Reservation> _reservationsBox;
  late Box<Article> _articlesBox;
  late Box<KanbanTask> _kanbanTasksBox;

  // Initialisation du service Hive
  Future<void> init() async {
    await Hive.initFlutter();

    // --- ENREGISTREMENT DES ADAPTATEURS ---
    // C'est CRUCIAL que tous les adaptateurs soient enregistrés AVANT d'ouvrir leurs boîtes.

    if (!Hive.isAdapterRegistered(EquipementAdapter().typeId)) {
      Hive.registerAdapter(EquipementAdapter());
    }
    if (!Hive.isAdapterRegistered(InterventionAdapter().typeId)) {
      Hive.registerAdapter(InterventionAdapter());
    }
    if (!Hive.isAdapterRegistered(PanneAdapter().typeId)) {
      Hive.registerAdapter(PanneAdapter());
    }
    if (!Hive.isAdapterRegistered(CollaborateurAdapter().typeId)) {
      Hive.registerAdapter(CollaborateurAdapter());
    }
    if (!Hive.isAdapterRegistered(RoleAdapter().typeId)) {
      Hive.registerAdapter(RoleAdapter());
    }
    if (!Hive.isAdapterRegistered(ReservationAdapter().typeId)) {
      Hive.registerAdapter(ReservationAdapter());
    }
    if (!Hive.isAdapterRegistered(ArticleAdapter().typeId)) {
      Hive.registerAdapter(ArticleAdapter());
    }

    // IMPORTANT: Enregistrez KanbanStatusAdapter et KanbanTaskAdapter ici
    if (!Hive.isAdapterRegistered(KanbanStatusAdapter().typeId)) {
      Hive.registerAdapter(KanbanStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(KanbanTaskAdapter().typeId)) {
      Hive.registerAdapter(KanbanTaskAdapter());
    }

    // --- OUVERTURE DES BOÎTES ---
    // Les boîtes sont ouvertes APRÈS que tous leurs adaptateurs respectifs soient enregistrés.
    _equipementsBox = await Hive.openBox<Equipement>(equipementsBoxName);
    _interventionsBox = await Hive.openBox<Intervention>(interventionsBoxName);
    _pannesBox = await Hive.openBox<Panne>(pannesBoxName);
    _collaborateursBox =
        await Hive.openBox<Collaborateur>(collaborateursBoxName);
    _reservationsBox = await Hive.openBox<Reservation>(reservationsBoxName);
    _articlesBox = await Hive.openBox<Article>(articlesBoxName);
    _kanbanTasksBox = await Hive.openBox<KanbanTask>(
        kanbanTasksBoxName); // Ouverture de la boîte Kanban

    // Écoutez les changements de la boîte kanbanTasksBox pour notifier les listeners
    // Cela garantit que l'UI se met à jour quand des tâches sont ajoutées/modifiées/supprimées
    _kanbanTasksBox.watch().listen((_) {
      notifyListeners();
    });

    // Ajout des données de démo si les boîtes sont vides
    await addDemoData();

    // Notifier les auditeurs que les données sont prêtes
    notifyListeners();
  }

  // --- GETTERS pour accéder aux boîtes ---
  Box<Equipement> get equipementsBox => _equipementsBox;
  Box<Intervention> get interventionsBox => _interventionsBox;
  Box<Panne> get pannesBox => _pannesBox;
  Box<Collaborateur> get collaborateursBox => _collaborateursBox;
  Box<Reservation> get reservationsBox => _reservationsBox;
  Box<Article> get articlesBox => _articlesBox;
  Box<KanbanTask> get kanbanTasksBox =>
      _kanbanTasksBox; // Getter pour la boîte Kanban

  // --- Getter pour toutes les tâches Kanban (utile pour l'affichage) ---
  List<KanbanTask> get kanbanTasks => _kanbanTasksBox.values.toList();

  // --- OPÉRATIONS CRUD ---

  // Equipement
  Future<void> addOrUpdateEquipement(Equipement equipement) async {
    await _equipementsBox.put(equipement.id, equipement);
    notifyListeners();
  }

  Future<void> deleteEquipement(String id) async {
    final interventionsToDelete =
        _interventionsBox.values.where((i) => i.equipmentId == id).toList();
    for (var i in interventionsToDelete) {
      await i.delete();
    }
    final pannesToDelete =
        _pannesBox.values.where((p) => p.equipmentId == id).toList();
    for (var p in pannesToDelete) {
      await p.delete();
    }
    await _equipementsBox.delete(id);
    notifyListeners();
  }

  Equipement? getEquipementById(String id) {
    return _equipementsBox.get(id);
  }

  // Intervention
  Future<void> addOrUpdateIntervention(Intervention intervention) async {
    await _interventionsBox.put(intervention.id, intervention);
    notifyListeners();
  }

  Future<void> deleteIntervention(String id) async {
    await _interventionsBox.delete(id);
    notifyListeners();
  }

  List<Intervention> getInterventionsForEquipement(String equipementId) {
    return _interventionsBox.values
        .where((i) => i.equipmentId == equipementId)
        .toList();
  }

  // Panne
  Future<void> addOrUpdatePanne(Panne panne) async {
    await _pannesBox.put(panne.id, panne);
    notifyListeners();
  }

  Future<void> deletePanne(String id) async {
    await _pannesBox.delete(id);
    notifyListeners();
  }

  List<Panne> getPannesForEquipement(String equipementId) {
    return _pannesBox.values
        .where((p) => p.equipmentId == equipementId)
        .toList();
  }

  // --- CRUD pour Collaborateur ---
  Future<void> addOrUpdateCollaborateur(Collaborateur collaborateur) async {
    if (collaborateur.isInBox) {
      await collaborateur.save();
    } else {
      await _collaborateursBox.add(collaborateur);
    }
    notifyListeners();
  }

  Future<void> deleteCollaborateur(dynamic key) async {
    await _collaborateursBox.delete(key);
    notifyListeners();
  }

  Future<void> addOrUpdateReservation(Reservation reservation) async {
    if (reservation.isInBox) {
      await reservation.save();
    } else {
      await _reservationsBox.add(reservation);
    }
    notifyListeners();
  }

  Future<void> deleteReservation(dynamic key) async {
    await _reservationsBox.delete(key);
    notifyListeners();
  }

  // CRUD pour article
  Future<void> addOrUpdateArticle(Article article) async {
    if (article.isInBox) {
      await article.save();
    } else {
      await _articlesBox.put(article.codeArticle, article);
    }
    notifyListeners();
  }

  Future<void> deleteArticle(String codeArticle) async {
    await _articlesBox.delete(codeArticle);
    notifyListeners();
  }

  Article? getArticleByCode(String codeArticle) {
    return _articlesBox.get(codeArticle);
  }

  List<Article> getAllArticles() {
    return _articlesBox.values.toList();
  }

  // --- CRUD pour KanbanTask ---
  Future<void> addOrUpdateKanbanTask(KanbanTask task) async {
    await _kanbanTasksBox.put(task.id, task);
    // notifyListeners() est déjà appelé par le listener de la boîte
    // notifyListeners();
  }

  Future<void> deleteKanbanTask(String id) async {
    await _kanbanTasksBox.delete(id);
    // notifyListeners();
  }

  Future<void> updateKanbanTaskStatus(
      String taskId, KanbanStatus newStatus) async {
    final task = _kanbanTasksBox.get(taskId);
    if (task != null) {
      task.status = newStatus;
      await task.save();
      // notifyListeners();
    }
  }

  // --- DONNÉES DE DÉMO ---
  Future<void> addDemoData() async {
    if (_equipementsBox.isEmpty) {
      final equipements = [
        Equipement(
            id: 'EQ001',
            nom: 'Presse hydraulique',
            type: 'Machine',
            dateMiseEnService: DateTime(2022, 1, 15)),
        Equipement(
            id: 'EQ002',
            nom: 'Convoyeur #1',
            type: 'Transport',
            dateMiseEnService:
                DateTime.now().subtract(const Duration(days: 380))),
        Equipement(
            id: 'EQ003',
            nom: 'Four industriel',
            type: 'Chauffage',
            dateMiseEnService:
                DateTime.now().subtract(const Duration(days: 25))),
      ];
      for (var e in equipements) {
        await _equipementsBox.put(e.id, e);
      }
    }

    if (_interventionsBox.isEmpty) {
      final interventions = [
        Intervention(
            id: 'INT001',
            equipmentId: 'EQ001',
            dateDebut: DateTime(2024, 6, 1),
            dateFin: DateTime(2024, 6, 2),
            type: 'Préventive',
            cout: 300,
            dureeHeures: 6,
            urgence: false),
        Intervention(
            id: 'INT002',
            equipmentId: 'EQ002',
            dateDebut: DateTime(2024, 6, 5),
            dateFin: DateTime(2024, 6, 6),
            type: 'Corrective',
            cout: 1200,
            dureeHeures: 10,
            urgence: true),
      ];
      for (var i in interventions) {
        await addOrUpdateIntervention(i);
      }
    }

    if (_pannesBox.isEmpty) {
      final pannes = [
        Panne(
            id: 'PAN001',
            equipmentId: 'EQ001',
            datePanne: DateTime(2024, 5, 10),
            dateReparation: DateTime(2024, 5, 11),
            cause: 'Roulement usé'),
        Panne(
            id: 'PAN002',
            equipmentId: 'EQ002',
            datePanne: DateTime(2024, 5, 18),
            dateReparation: DateTime(2024, 5, 20),
            cause: 'Moteur bloqué'),
      ];
      for (var p in pannes) {
        await addOrUpdatePanne(p);
      }
    }

    if (_collaborateursBox.isEmpty) {
      final collaborateurs = [
        Collaborateur()
          ..prenom = 'Mohamed'
          ..nom = 'BENATTALAH'
          ..fonction = Role.technicien,
        Collaborateur()
          ..prenom = 'Kevin'
          ..nom = 'BERC'
          ..fonction = Role.technicien,
        Collaborateur()
          ..prenom = 'Adrien'
          ..nom = 'GARNIER-BEYER'
          ..fonction = Role.technicien,
        Collaborateur()
          ..prenom = 'Karim'
          ..nom = 'JEBLI Karim'
          ..fonction = Role.technicien,
        Collaborateur()
          ..prenom = 'Adam'
          ..nom = 'LAGUEL'
          ..fonction = Role.technicien,
        Collaborateur()
          ..prenom = 'Marwan'
          ..nom = 'MAIZI'
          ..fonction = Role.technicien,
        Collaborateur()
          ..prenom = 'Saif Eddine'
          ..nom = 'MANAI'
          ..fonction = Role.technicien,
        Collaborateur()
          ..prenom = 'Denis'
          ..nom = 'MENNEA'
          ..fonction = Role.technicien,
        Collaborateur()
          ..prenom = 'Dorian'
          ..nom = 'MOREL'
          ..fonction = Role.technicien,
        Collaborateur()
          ..prenom = 'Eric'
          ..nom = 'MATHIOT'
          ..fonction = Role.administrateur,
      ];
      for (var c in collaborateurs) {
        await _collaborateursBox.add(c);
      }
    }

    if (_articlesBox.isEmpty) {
      final articles = [
        Article(
          category: "Consommables",
          codeArticle: "CONS001",
          stockInitial: 100,
          stockMini: 20,
          stockMaxi: 200,
          pointCommande: 30,
          prixUnitaire: 5.99,
          commentaire: "Gants de protection taille L",
        ),
        Article(
          category: "Outillages manuels",
          codeArticle: "OUT001",
          stockInitial: 10,
          stockMini: 2,
          stockMaxi: 15,
          pointCommande: 3,
          prixUnitaire: 49.99,
          commentaire: "Clé à molette réglable 300mm",
        ),
        Article(
          category: "Visseries",
          codeArticle: "VIS001",
          stockInitial: 500,
          stockMini: 100,
          stockMaxi: 1000,
          pointCommande: 150,
          prixUnitaire: 0.15,
          commentaire: "Vis M8x20mm acier inoxydable",
        ),
      ];
      for (var article in articles) {
        await _articlesBox.put(article.codeArticle, article);
      }
    }

    if (_kanbanTasksBox.isEmpty) {
      final kanbanTasks = [
        KanbanTask(
          id: uuid.v4(),
          title: 'Vérifier l\'huile de la presse',
          description:
              'Vérification du niveau d\'huile et appoint si nécessaire pour la presse hydraulique.',
          dueDate: DateTime.now().add(const Duration(days: 7)),
          status: KanbanStatus.todo,
          colorValue: Colors.blue
              .toARGB32(), // Utilisation de .value pour les démo (ou .toARGB32())
        ),
        KanbanTask(
          id: uuid.v4(),
          title: 'Changer courroie Convoyeur #1',
          description:
              'Remplacement de la courroie principale du convoyeur numéro 1.',
          dueDate: DateTime.now().add(const Duration(days: 3)),
          status: KanbanStatus.inProgress,
          colorValue: Colors.orange.toARGB32(),
        ),
        KanbanTask(
          id: uuid.v4(),
          title: 'Nettoyage Four industriel',
          description:
              'Nettoyage complet des chambres de cuisson et des filtres du four.',
          dueDate: DateTime.now().subtract(const Duration(days: 2)),
          status: KanbanStatus.done,
          colorValue: Colors.green.toARGB32(),
        ),
        KanbanTask(
          id: uuid.v4(),
          title: 'Planifier maintenance EQ003',
          description:
              'Préparer le planning de maintenance préventive pour l\'équipement EQ003.',
          dueDate: DateTime.now().add(const Duration(days: 14)),
          status: KanbanStatus.todo,
          colorValue: Colors.purple.toARGB32(),
        ),
        KanbanTask(
          id: uuid.v4(),
          title: 'Commander pièces rechange',
          description:
              'Commander les pièces détachées pour la prochaine maintenance du Convoyeur #1.',
          dueDate: DateTime.now().add(const Duration(days: 10)),
          status: KanbanStatus.inProgress,
          colorValue: Colors.red.toARGB32(),
        ),
      ];
      for (var task in kanbanTasks) {
        await _kanbanTasksBox.put(task.id, task);
      }
    }
  }

  // --- RENOMMER closeAllBoxes() en close() ---
  // C'est la méthode que vous tentez d'appeler depuis main.dart
  Future<void> close() async {
    await _equipementsBox.close();
    await _interventionsBox.close();
    await _pannesBox.close();
    await _collaborateursBox.close();
    await _reservationsBox.close();
    await _articlesBox.close();
    await _kanbanTasksBox.close();
    debugPrint('Toutes les boîtes Hive fermées.');
  }
}
