// lib/data_sources/article_data_source.dart
import 'package:flutter/material.dart';
import 'package:maintenance_app/models/article.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ArticleDataSource extends DataTableSource {
  final Box<Article> _articlesBox;
  final Function(Article) onDelete;
  final Function(Article) onEdit;
  final Function(Article)? onPrint;
  Article? highlightedArticle; // For highlighting

  ArticleDataSource(this._articlesBox,
      {required this.onDelete,
      required this.onEdit,
      this.onPrint,
      this.highlightedArticle});

  @override
  DataRow? getRow(int index) {
    if (index >= _articlesBox.length) {
      return null;
    }

    final article = _articlesBox.getAt(index)!;

    // Check if this article should be highlighted
    final isHighlighted =
        highlightedArticle?.codeArticle == article.codeArticle;

    return DataRow(
      key: ValueKey(article.codeArticle), // Use ValueKey for row identification
      color: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) {
          if (isHighlighted) {
            return Colors.yellow.withAlpha((255 * 0.3).round());
          }
          return null;
        },
      ),
      cells: [
        DataCell(Text(article.category)),
        DataCell(Text(article.codeArticle.toString())),
        DataCell(Text(article.stockInitial.toString())),
        DataCell(Text(article.stockMini.toString())),
        DataCell(Text(article.stockMaxi.toString())),
        DataCell(Text(article.pointCommande.toString())),
        DataCell(Text('${article.prixUnitaire.toStringAsFixed(2)} €')),
        DataCell(Text(article.commentaire)),
        DataCell(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => onEdit(article),
              tooltip: 'Modifier',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => onDelete(article),
              tooltip: 'Effacer',
            ),
            if (onPrint !=
                null) // Affichez l'icône seulement si le callback est fourni
              IconButton(
                icon: const Icon(Icons.print, color: Colors.yellow),
                onPressed: () =>
                    onPrint!(article), // Appelle le callback d'impression
                tooltip: 'Imprimer',
              ),
          ],
        )),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => _articlesBox.length;
  @override
  int get selectedRowCount => 0;
}
