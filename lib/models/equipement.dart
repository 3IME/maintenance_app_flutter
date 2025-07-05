import 'package:hive/hive.dart';

part 'equipement.g.dart';

enum MaintenanceStatus { aJour, bientot, enRetard }

@HiveType(typeId: 0)
class Equipement extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String nom;

  @HiveField(2)
  String type;

  @HiveField(3)
  DateTime dateMiseEnService;

  @HiveField(4)
  HiveList<dynamic>? interventions; // Utiliser HiveList pour les relations

  @HiveField(5)
  HiveList<dynamic>? pannes; // Utiliser HiveList pour les relations

  Equipement({
    required this.id,
    required this.nom,
    required this.type,
    required this.dateMiseEnService,
  });

  // Logique pour le statut de maintenance
  DateTime get prochaineMaintenance {
    DateTime now = DateTime.now();
    int anneeProchaineMaintenance = now.year;

    // Si la date de maintenance de cette année est déjà passée, on passe à l'année suivante
    if (now.month > dateMiseEnService.month ||
        (now.month == dateMiseEnService.month &&
            now.day > dateMiseEnService.day)) {
      anneeProchaineMaintenance++;
    }
    return DateTime(anneeProchaineMaintenance, dateMiseEnService.month,
        dateMiseEnService.day);
  }

  MaintenanceStatus get maintenanceStatus {
    final now = DateTime.now();
    final prochaine = prochaineMaintenance;
    final difference = prochaine.difference(now).inDays;

    if (difference < 0) {
      return MaintenanceStatus.enRetard;
    } else if (difference <= 30) {
      return MaintenanceStatus.bientot;
    } else {
      return MaintenanceStatus.aJour;
    }
  }
}
