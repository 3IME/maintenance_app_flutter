// lib/models/reservation.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'reservation.g.dart'; // On va générer ce fichier

@HiveType(typeId: 5) // Utilisez un typeId qui n'a jamais été utilisé
class Reservation extends HiveObject {
  @HiveField(0)
  late DateTime startTime;

  @HiveField(1)
  late DateTime endTime;

  @HiveField(2)
  late String subject; // Ex: "Intervention sur Presse Hydraulique"

  @HiveField(3)
  late int colorValue; // On stocke la valeur de la couleur (int)

  @HiveField(4)
  late List<dynamic>
      resourceIds; // La liste des clés des collaborateurs concernés

  // Getter pratique pour récupérer la couleur
  Color get color => Color(colorValue);
}
