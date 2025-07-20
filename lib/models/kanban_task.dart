import 'package:hive/hive.dart';
import 'package:flutter/material.dart'; // Pour Color

part 'kanban_task.g.dart';

@HiveType(typeId: 8) // Assurez-vous que le typeId est unique
enum KanbanStatus {
  @HiveField(0)
  todo,
  @HiveField(1)
  inProgress,
  @HiveField(2)
  done,
}

@HiveType(typeId: 7) // Assurez-vous que le typeId est unique
class KanbanTask extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late String description;

  @HiveField(3)
  late DateTime dueDate;

  @HiveField(4)
  late KanbanStatus status;

  @HiveField(5)
  late int colorValue; // Pour stocker la couleur en tant qu'entier

  KanbanTask({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    this.status = KanbanStatus.todo,
    int? colorValue, // Rendre le paramètre optionnel
  }) : colorValue = colorValue ??
            Colors.blue
                .toARGB32(); // <-- Corrected: removed 'this.' and used .toARGB32()

  // Propriété calculée pour obtenir la couleur Flutter
  Color get color => Color(colorValue);

  // Méthode pour définir la couleur
  set color(Color newColor) {
    colorValue = newColor.toARGB32(); // <-- Corrected: used .toARGB32()
  }
}
