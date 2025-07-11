// lib/screens/shop/shop_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Pour FilteringTextInputFormatter
import 'package:hive_flutter/hive_flutter.dart'; // Importez Hive
import 'package:maintenance_app/models/article.dart'; // Importez votre modèle Article
import 'dart:async';
import 'package:maintenance_app/data_sources/article_data_source.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart'
    as pw; // Utilisez 'pw' comme alias pour les widgets PDF
import 'package:printing/printing.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({Key? key}) : super(key: key);

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _codeArticleController = TextEditingController();
  final TextEditingController _stockInitialController = TextEditingController();
  final TextEditingController _stockMiniController = TextEditingController();
  final TextEditingController _stockMaxiController = TextEditingController();
  final TextEditingController _pointCommandeController =
      TextEditingController();
  final TextEditingController _prixUnitaireController = TextEditingController();
  final TextEditingController _commentaireController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  String? _selectedCategory;
  final List<String> _categories = [
    "Outillages manuels",
    "Outillages électriques",
    "Appareils de mesures",
    "Visseries",
    "Consommables",
    "EPI",
    "Equipements électriques",
    "Equipements mécaniques",
    "Equipements pneumatiques",
    "Equipements hydrauliques",
  ];

  late Future<Box<Article>> _articlesBoxFuture;
  late Box<Article> _articlesBox;
  Article? _highlightedArticle;
  Timer? _highlightTimer;
  late ArticleDataSource _articleDataSource;

  // Déclarez une GlobalKey pour le PaginatedDataTable
  final GlobalKey<PaginatedDataTableState> _paginatedDataTableKey = GlobalKey();

  // New state variable to manage the current rows per page
  int _currentRowsPerPage = PaginatedDataTable.defaultRowsPerPage;

  // Déclarez le ScrollController pour le défilement horizontal de la table
  final ScrollController _horizontalDataTableScrollController =
      ScrollController();
  // Pour le défilement global de l'écran (si nécessaire pour le formulaire)
  final ScrollController _verticalScreenScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _articlesBoxFuture = Hive.openBox<Article>('articles');
  }

  @override
  void dispose() {
    _codeArticleController.dispose();
    _stockInitialController.dispose();
    _stockMiniController.dispose();
    _stockMaxiController.dispose();
    _pointCommandeController.dispose();
    _prixUnitaireController.dispose();
    _commentaireController.dispose();
    _searchController.dispose();
    _highlightTimer?.cancel();
    _horizontalDataTableScrollController
        .dispose(); // Dispose du contrôleur horizontal
    _verticalScreenScrollController.dispose(); // Dispose du contrôleur vertical
    super.dispose();
  }

  void _addArticle() {
    if (_formKey.currentState!.validate()) {
      final newArticle = Article(
        category: _selectedCategory!,
        codeArticle: _codeArticleController.text,
        stockInitial: int.parse(_stockInitialController.text),
        stockMini: int.parse(_stockMiniController.text),
        stockMaxi: int.parse(_stockMaxiController.text),
        pointCommande: int.parse(_pointCommandeController.text),
        prixUnitaire: double.parse(_prixUnitaireController.text),
        commentaire: _commentaireController.text,
      );
      _articlesBox.add(newArticle);
      _clearForm();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Article ajouté avec succès!')),
      );
    }
  }

  void _deleteArticle(Article article) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: Text(
              'Voulez-vous vraiment supprimer l\'article ${article.codeArticle} ?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                if (!dialogContext.mounted) {
                  return;
                }
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Supprimer',
                  style: TextStyle(color: Colors.white)),
              onPressed: () {
                article.delete();
                if (!dialogContext.mounted) {
                  return;
                }
                Navigator.of(dialogContext).pop();
                if (!mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Article supprimé avec succès!')),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _printArticle(Article article) async {
    final pdf = pw.Document(); // Crée un nouveau document PDF

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'Détails de l\'Article',
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 20),
              _buildDetailRow('Catégorie:', article.category),
              _buildDetailRow('Code Article:', article.codeArticle.toString()),
              _buildDetailRow(
                  'Stock Initial:', article.stockInitial.toString()),
              _buildDetailRow('Stock Minimum:', article.stockMini.toString()),
              _buildDetailRow('Stock Maximum:', article.stockMaxi.toString()),
              _buildDetailRow(
                  'Point de Commande:', article.pointCommande.toString()),
              _buildDetailRow('Prix Unitaire:',
                  '${article.prixUnitaire.toStringAsFixed(2)} Euros'),
              _buildDetailRow('Commentaire:', article.commentaire),
              pw.SizedBox(height: 40),
              pw.Text(
                  'Généré le: ${DateTime.now().toLocal().toString().split('.')[0]}'),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text('Génération du PDF pour ${article.codeArticle} terminée.')),
    );
  }

  // Fonction utilitaire pour créer une ligne de détail dans le PDF
  pw.Widget _buildDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 150, // Largeur fixe pour le label
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value),
          ),
        ],
      ),
    );
  }

  void _showEditArticleDialog(Article article) {
    // Créez des contrôleurs temporaires pour le dialogue d'édition
    final TextEditingController editCodeArticleController =
        TextEditingController(text: article.codeArticle);
    final TextEditingController editStockInitialController =
        TextEditingController(text: article.stockInitial.toString());
    final TextEditingController editStockMiniController =
        TextEditingController(text: article.stockMini.toString());
    final TextEditingController editStockMaxiController =
        TextEditingController(text: article.stockMaxi.toString());
    final TextEditingController editPointCommandeController =
        TextEditingController(text: article.pointCommande.toString());
    final TextEditingController editPrixUnitaireController =
        TextEditingController(text: article.prixUnitaire.toStringAsFixed(2));
    final TextEditingController editCommentaireController =
        TextEditingController(text: article.commentaire);

    // Variable pour la catégorie sélectionnée dans le dialogue
    String? editedCategory = article.category;
    final editFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Modifier Article'),
          content: SingleChildScrollView(
            child: Form(
              key: editFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: editedCategory,
                    hint: const Text('Sélectionnez une catégorie'),
                    items: _categories.map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      editedCategory = newValue;
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez sélectionner une catégorie';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: editCodeArticleController,
                    decoration:
                        const InputDecoration(labelText: 'Code Article'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer un code article';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: editStockInitialController,
                    decoration:
                        const InputDecoration(labelText: 'Stock Initial'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || int.tryParse(value) == null) {
                        return 'Veuillez entrer un nombre valide';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: editStockMiniController,
                    decoration:
                        const InputDecoration(labelText: 'Stock Minimum'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || int.tryParse(value) == null) {
                        return 'Veuillez entrer un nombre valide';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: editStockMaxiController,
                    decoration:
                        const InputDecoration(labelText: 'Stock Maximum'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || int.tryParse(value) == null) {
                        return 'Veuillez entrer un nombre valide';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: editPointCommandeController,
                    decoration:
                        const InputDecoration(labelText: 'Point de Commande'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || int.tryParse(value) == null) {
                        return 'Veuillez entrer un nombre valide';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: editPrixUnitaireController,
                    decoration:
                        const InputDecoration(labelText: 'Prix Unitaire (€)'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'))
                    ],
                    validator: (value) {
                      if (value == null || double.tryParse(value) == null) {
                        return 'Veuillez entrer un nombre valide (ex: 12.50)';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: editCommentaireController,
                    decoration: const InputDecoration(labelText: 'Commentaire'),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (editFormKey.currentState!.validate()) {
                  // Mettre à jour l'article existant
                  article.category = editedCategory!;
                  article.codeArticle = editCodeArticleController.text;
                  article.stockInitial =
                      int.parse(editStockInitialController.text);
                  article.stockMini = int.parse(editStockMiniController.text);
                  article.stockMaxi = int.parse(editStockMaxiController.text);
                  article.pointCommande =
                      int.parse(editPointCommandeController.text);
                  article.prixUnitaire =
                      double.parse(editPrixUnitaireController.text);
                  article.commentaire = editCommentaireController.text;

                  article.save(); // Sauvegarder les modifications dans Hive

                  Navigator.of(context).pop(); // Fermer le dialogue
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Article modifié avec succès!')),
                  );
                }
              },
              child: const Text('Sauvegarder'),
            ),
          ],
        );
      },
    );
  }

  void _clearForm() {
    _formKey.currentState!.reset();
    _codeArticleController.clear();
    _stockInitialController.clear();
    _stockMiniController.clear();
    _stockMaxiController.clear();
    _pointCommandeController.clear();
    _prixUnitaireController.clear();
    _commentaireController.clear();
    setState(() {
      _selectedCategory = null;
    });
  }

  void _searchArticle() {
    final searchTerm = _searchController.text.trim().toLowerCase();
    if (searchTerm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un terme de recherche.')),
      );
      return;
    }

    Article? foundArticle;
    int? foundIndex;
    for (int i = 0; i < _articlesBox.length; i++) {
      final article = _articlesBox.getAt(i)!;
      if (article.codeArticle.toLowerCase().contains(searchTerm)) {
        foundArticle = article;
        foundIndex = i;
        break;
      }
    }

    if (foundArticle != null && foundIndex != null) {
      setState(() {
        _highlightedArticle = foundArticle;
      });

      // Use the _currentRowsPerPage state variable
      final targetPage = (foundIndex / _currentRowsPerPage).floor();
      final newFirstRowIndex = targetPage * _currentRowsPerPage;

      _paginatedDataTableKey.currentState?.pageTo(newFirstRowIndex);

      _highlightTimer?.cancel();
      _highlightTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _highlightedArticle = null;
          });
        }
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Article "${foundArticle.codeArticle}" trouvé !')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Article "${_searchController.text}" non trouvé.')),
      );
      if (mounted && _highlightedArticle != null) {
        setState(() {
          _highlightedArticle = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion du Magasin'),
      ),
      body: FutureBuilder<Box<Article>>(
        future: _articlesBoxFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            _articlesBox = snapshot.data!;
            return _buildShopContent(context);
          } else if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return const Center(
                child: Text("Erreur lors du chargement des données."));
          }
        },
      ),
    );
  }

  Widget _buildShopContent(BuildContext context) {
    return SingleChildScrollView(
        controller:
            _verticalScreenScrollController, // Contrôleur pour le défilement vertical de la page
        padding: const EdgeInsets.all(16.0),
        child: Center(
            child: SizedBox(
                width: MediaQuery.of(context).size.width - 32.0,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "Ajouter un nouvel article",
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 20),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              hint: const Text('Sélectionnez une catégorie'),
                              items: _categories.map((String category) {
                                return DropdownMenuItem<String>(
                                  value: category,
                                  child: Text(category),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedCategory = newValue;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez sélectionner une catégorie';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _codeArticleController,
                              decoration: const InputDecoration(
                                labelText: 'Code Article',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer un code article';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _stockInitialController,
                              decoration: const InputDecoration(
                                labelText: 'Stock Initial',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer le stock initial';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Le stock initial doit être un nombre';
                                }
                                return null;
                              },
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _stockMiniController,
                              decoration: const InputDecoration(
                                labelText: 'Stock Minimum',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer le stock minimum';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Le stock minimum doit être un nombre';
                                }
                                return null;
                              },
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _stockMaxiController,
                              decoration: const InputDecoration(
                                labelText: 'Stock Maximum',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer le stock maximum';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Le stock maximum doit être un nombre';
                                }
                                return null;
                              },
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _pointCommandeController,
                              decoration: const InputDecoration(
                                labelText: 'Point de Commande',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer le point de commande';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Le point de commande doit être un nombre';
                                }
                                return null;
                              },
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _prixUnitaireController,
                              decoration: const InputDecoration(
                                labelText: 'Prix Unitaire (€)',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer le prix unitaire';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Le prix unitaire doit être un nombre valide (ex: 12.50)';
                                }
                                return null;
                              },
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d+\.?\d{0,2}')),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _commentaireController,
                              decoration: const InputDecoration(
                                labelText: 'Commentaire',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: _addArticle,
                              icon: const Icon(Icons.add),
                              label: const Text('Ajouter Article'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(50),
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor:
                                    Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Articles du Magasin",
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Rechercher un article...',
                                prefixIcon: IconButton(
                                  icon: const Icon(Icons.search),
                                  onPressed: _searchArticle,
                                ),
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 10),
                              ),
                              onSubmitted: (_) => _searchArticle(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // --- MODIFICATION CLÉ : Gérer le défilement horizontal ici ---
                      ValueListenableBuilder(
                        valueListenable: _articlesBox.listenable(),
                        builder: (context, Box<Article> box, _) {
                          // Début du builder
                          _articleDataSource = ArticleDataSource(
                            box, // Passe la Box mise à jour
                            onDelete: _deleteArticle,
                            onEdit: _showEditArticleDialog,
                            onPrint: _printArticle,
                            highlightedArticle: _highlightedArticle,
                          );

                          // Si le tableau est vide, afficher un message centré
                          if (box.values.isEmpty) {
                            return const Center(
                              child: Text(
                                  "Aucun article dans le magasin pour l'instant."),
                            );
                          } else {
                            // Début de la structure pour afficher la table
                            return Scrollbar(
                              controller: _horizontalDataTableScrollController,
                              thumbVisibility: true,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                controller:
                                    _horizontalDataTableScrollController,
                                child: SizedBox(
                                  width: 1300,
                                  child: PaginatedDataTable(
                                    // 5. Début de PaginatedDataTable
                                    key: _paginatedDataTableKey,
                                    header: const Text(
                                        'Liste des pièces détachées'),
                                    rowsPerPage: _currentRowsPerPage,
                                    availableRowsPerPage: const [
                                      5,
                                      10,
                                      20,
                                      50,
                                      100
                                    ],
                                    onPageChanged: (int page) {},
                                    onRowsPerPageChanged: (int? value) {
                                      if (value != null) {
                                        setState(() {
                                          _currentRowsPerPage = value;
                                        });
                                      }
                                    },
                                    columnSpacing: 20.0,
                                    columns: const [
                                      DataColumn(
                                          label: Text('Catégorie',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      DataColumn(
                                          label: Text('Code Article',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      DataColumn(
                                          label: Text('Stock',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      DataColumn(
                                          label: Text('Stock Mini',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      DataColumn(
                                          label: Text('Stock Maxi',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      DataColumn(
                                          label: Text('P. Commande',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      DataColumn(
                                          label: Text('Prix Unitaire',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      DataColumn(
                                          label: Text('Commentaire',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      DataColumn(
                                          label: Text('Actions',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                    ],
                                    source: _articleDataSource,
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                      )
                    ]))));
  }
}
