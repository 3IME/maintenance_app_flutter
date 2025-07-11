import 'package:flutter/foundation.dart';
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

class HiveService extends ChangeNotifier {
  // Constantes pour les noms des "boîtes" (tables)
  static const String equipementsBoxName = 'equipements';
  static const String interventionsBoxName = 'interventions';
  static const String pannesBoxName = 'pannes';
  static const String collaborateursBoxName = 'collaborateurs';
  static const String reservationsBoxName = 'reservations';
  static const String articlesBoxName = 'articles';

  var uuid = const Uuid();

  // Initialisation du service Hive
  Future<void> init() async {
    await Hive.initFlutter();

    // Enregistrement des adaptateurs (empêche les erreurs de ré-enregistrement)
    if (!Hive.isAdapterRegistered(EquipementAdapter().typeId)) {
      Hive.registerAdapter(EquipementAdapter());
    }
    if (!Hive.isAdapterRegistered(InterventionAdapter().typeId)) {
      Hive.registerAdapter(InterventionAdapter());
    }
    if (!Hive.isAdapterRegistered(PanneAdapter().typeId)) {
      Hive.registerAdapter(PanneAdapter());
    }
    // Enregistrement des nouveaux adaptateurs
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

    // Ouverture des boîtes
    await Hive.openBox<Equipement>(equipementsBoxName);
    await Hive.openBox<Intervention>(interventionsBoxName);
    await Hive.openBox<Panne>(pannesBoxName);
    await Hive.openBox<Collaborateur>(collaborateursBoxName);
    await Hive.openBox<Reservation>(reservationsBoxName);
    await Hive.openBox<Article>(articlesBoxName);

    // Ajout des données de démo si les boîtes sont vides
    await addDemoData();

    // Notifier les auditeurs que les données sont prêtes
    notifyListeners();
  }

  // --- GETTERS ---
  // Accès direct et typé aux boîtes Hive pour une utilisation facile dans l'UI
  Box<Equipement> get equipementsBox =>
      Hive.box<Equipement>(equipementsBoxName);
  Box<Intervention> get interventionsBox =>
      Hive.box<Intervention>(interventionsBoxName);
  Box<Panne> get pannesBox => Hive.box<Panne>(pannesBoxName);
  Box<Collaborateur> get collaborateursBox =>
      Hive.box<Collaborateur>(collaborateursBoxName);
  Box<Reservation> get reservationsBox =>
      Hive.box<Reservation>(reservationsBoxName);
  Box<Article> get articlesBox => Hive.box<Article>(articlesBoxName);

  // --- OPÉRATIONS CRUD ---

  // Equipement
  Future<void> addOrUpdateEquipement(Equipement equipement) async {
    await equipementsBox.put(equipement.id, equipement);
    notifyListeners();
  }

  Future<void> deleteEquipement(String id) async {
    final interventionsToDelete =
        interventionsBox.values.where((i) => i.equipmentId == id).toList();
    for (var i in interventionsToDelete) {
      await i.delete();
    }
    final pannesToDelete =
        pannesBox.values.where((p) => p.equipmentId == id).toList();
    for (var p in pannesToDelete) {
      await p.delete();
    }
    await equipementsBox.delete(id);
    notifyListeners();
  }

  Equipement? getEquipementById(String id) {
    return equipementsBox.get(id);
  }

  // Intervention
  Future<void> addOrUpdateIntervention(Intervention intervention) async {
    await interventionsBox.put(intervention.id, intervention);
    notifyListeners();
  }

  Future<void> deleteIntervention(String id) async {
    await interventionsBox.delete(id);
    notifyListeners();
  }

  List<Intervention> getInterventionsForEquipement(String equipementId) {
    return interventionsBox.values
        .where((i) => i.equipmentId == equipementId)
        .toList();
  }

  // Panne
  Future<void> addOrUpdatePanne(Panne panne) async {
    await pannesBox.put(panne.id, panne);
    notifyListeners();
  }

  Future<void> deletePanne(String id) async {
    await pannesBox.delete(id);
    notifyListeners();
  }

  List<Panne> getPannesForEquipement(String equipementId) {
    return pannesBox.values
        .where((p) => p.equipmentId == equipementId)
        .toList();
  }

  // --- CRUD pour Collaborateur ---
  Future<void> addOrUpdateCollaborateur(Collaborateur collaborateur) async {
    // Si l'objet a une clé, `put` le mettra à jour.
    // Sinon, `add` en créera un nouveau avec une clé auto-générée.
    if (collaborateur.isInBox) {
      await collaborateur
          .save(); // Méthode de HiveObject pour sauvegarder les changements
    } else {
      await collaborateursBox.add(collaborateur);
    }
    notifyListeners();
  }

  Future<void> deleteCollaborateur(dynamic key) async {
    await collaborateursBox.delete(key);
    notifyListeners();
  }

  Future<void> addOrUpdateReservation(Reservation reservation) async {
    if (reservation.isInBox) {
      await reservation.save();
    } else {
      await reservationsBox.add(reservation);
    }
    notifyListeners();
  }

  Future<void> deleteReservation(dynamic key) async {
    await reservationsBox.delete(key);
    notifyListeners();
  }

  // CRUD pour article
  Future<void> addOrUpdateArticle(Article article) async {
    if (article.isInBox) {
      await article.save(); // Met à jour l'article existant
    } else {
      await articlesBox.put(
          article.codeArticle, article); // Ajoute un nouvel article
    }
    notifyListeners();
  }

  Future<void> deleteArticle(String codeArticle) async {
    // <<< Le type de la clé doit être String
    await articlesBox
        .delete(codeArticle); // Supprime l'article par son codeArticle
    notifyListeners();
  }

  Article? getArticleByCode(String codeArticle) {
    // <<< Nom de méthode plus clair
    return articlesBox.get(codeArticle);
  }

  List<Article> getAllArticles() {
    return articlesBox.values.toList();
  }

  // --- DONNÉES DE N ---
  Future<void> addDemoData() async {
    if (equipementsBox.isEmpty) {
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
      // Boucle corrigée pour ajouter les équipements
      for (var e in equipements) {
        await equipementsBox.put(e.id, e);
      }
    }

    if (interventionsBox.isEmpty) {
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
      // Boucle corrigée pour ajouter les interventions
      for (var i in interventions) {
        await addOrUpdateIntervention(i);
      }
    }

    if (pannesBox.isEmpty) {
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

    if (collaborateursBox.isEmpty) {
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
        await collaborateursBox.add(c);
      }
    }

    // Ajout de données de démonstration pour les articles ---
    if (articlesBox.isEmpty) {
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
        await articlesBox.put(article.codeArticle, article);
        // Utilisation de add pour les nouveaux articles
      }
    }
  }
}
