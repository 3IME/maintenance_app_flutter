import 'package:hive/hive.dart';

part 'intervention.g.dart';

@HiveType(typeId: 1)
class Intervention extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String equipmentId;

  @HiveField(2)
  DateTime dateDebut;

  @HiveField(3)
  DateTime dateFin;

  @HiveField(4)
  String type; // "Préventive", "Corrective"

  @HiveField(5)
  double cout;

  @HiveField(6)
  int dureeHeures;

  @HiveField(7)
  bool urgence;

  Intervention({
    required this.id,
    required this.equipmentId,
    required this.dateDebut,
    required this.dateFin,
    required this.type,
    required this.cout,
    required this.dureeHeures,
    required this.urgence,
  });
}
