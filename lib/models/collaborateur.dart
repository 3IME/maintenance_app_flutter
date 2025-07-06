// lib/models/collaborateur.dart
import 'package:hive/hive.dart';
import 'package:maintenance_app/models/role.dart';

part 'collaborateur.g.dart'; // On va générer ce fichier

@HiveType(typeId: 3) // Utilisez un typeId qui n'a jamais été utilisé
class Collaborateur extends HiveObject {
  @HiveField(0)
  late String nom;

  @HiveField(1)
  late String prenom;

  @HiveField(2)
  late Role fonction;

  // Un getter pratique pour afficher le nom complet
  String get nomComplet => '$prenom $nom';
}
