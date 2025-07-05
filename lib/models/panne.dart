import 'package:hive/hive.dart';

part 'panne.g.dart';

@HiveType(typeId: 2)
class Panne extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String equipmentId;

  @HiveField(2)
  DateTime datePanne;

  @HiveField(3)
  DateTime? dateReparation; // Peut être nulle si pas encore réparé

  @HiveField(4)
  String cause;

  Panne({
    required this.id,
    required this.equipmentId,
    required this.datePanne,
    this.dateReparation,
    required this.cause,
  });

  Duration? get dureePanne {
    if (dateReparation != null) {
      return dateReparation!.difference(datePanne);
    }
    return null;
  }
}
