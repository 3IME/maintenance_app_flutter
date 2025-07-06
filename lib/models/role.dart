// lib/models/role.dart
import 'package:hive/hive.dart';

part 'role.g.dart'; // On va générer ce fichier

@HiveType(typeId: 4) // Utilisez un typeId qui n'a jamais été utilisé
enum Role {
  @HiveField(0)
  technicien,

  @HiveField(1)
  preparateur,

  @HiveField(2)
  administrateur,
}
