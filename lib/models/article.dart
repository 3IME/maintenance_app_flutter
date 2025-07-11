// lib/models/article.dart
import 'package:hive/hive.dart';

part 'article.g.dart'; // Ceci sera généré par build_runner

@HiveType(typeId: 6) // Assurez-vous que l'ID est unique dans votre projet
class Article extends HiveObject {
  @HiveField(0)
  late String category;

  @HiveField(1)
  late String codeArticle;

  @HiveField(2)
  late int stockInitial;

  @HiveField(3)
  late int stockMini;

  @HiveField(4)
  late int stockMaxi;

  @HiveField(5)
  late int pointCommande;

  @HiveField(6)
  late double prixUnitaire;

  @HiveField(7)
  late String commentaire;

  Article({
    required this.category,
    required this.codeArticle,
    required this.stockInitial,
    required this.stockMini,
    required this.stockMaxi,
    required this.pointCommande,
    required this.prixUnitaire,
    required this.commentaire,
  });
}
