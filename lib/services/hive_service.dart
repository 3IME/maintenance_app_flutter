import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintenance_app/models/equipement.dart';
import 'package:maintenance_app/models/intervention.dart';
import 'package:maintenance_app/models/panne.dart';
import 'package:uuid/uuid.dart';

class HiveService extends ChangeNotifier {
  static const String equipementsBoxName = 'equipements';
  static const String interventionsBoxName = 'interventions';
  static const String pannesBoxName = 'pannes';

  var uuid = const Uuid();

  Future<void> init() async {
    await Hive.initFlutter();

    // Enregistrement des adaptateurs
    if (!Hive.isAdapterRegistered(EquipementAdapter().typeId)) {
      Hive.registerAdapter(EquipementAdapter());
    }
    if (!Hive.isAdapterRegistered(InterventionAdapter().typeId)) {
      Hive.registerAdapter(InterventionAdapter());
    }
    if (!Hive.isAdapterRegistered(PanneAdapter().typeId)) {
      Hive.registerAdapter(PanneAdapter());
    }

    // Ouverture des boîtes
    await Hive.openBox<Equipement>(equipementsBoxName);
    await Hive.openBox<Intervention>(interventionsBoxName);
    await Hive.openBox<Panne>(pannesBoxName);

    // Ajouter des données de démo si les boîtes sont vides
    await addDemoData();

    notifyListeners();
  }

  // --- GETTERS ---
  Box<Equipement> get equipementsBox =>
      Hive.box<Equipement>(equipementsBoxName);
  Box<Intervention> get interventionsBox =>
      Hive.box<Intervention>(interventionsBoxName);
  Box<Panne> get pannesBox => Hive.box<Panne>(pannesBoxName);

  // --- CRUD Operations ---

  // Equipement
  Future<void> addOrUpdateEquipement(Equipement equipement) async {
    await equipementsBox.put(equipement.id, equipement);
    notifyListeners();
  }

  Future<void> deleteEquipement(String id) async {
    // Supprimer aussi les interventions et pannes liées
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

  // --- Demo Data ---
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
      for (var e in equipements) {
        await addOrUpdateEquipement(e);
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
  }
}
