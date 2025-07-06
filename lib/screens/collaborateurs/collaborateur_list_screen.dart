import 'package:flutter/material.dart';
import 'package:maintenance_app/models/collaborateur.dart';
import 'package:maintenance_app/services/hive_service.dart';
import 'package:provider/provider.dart';

// Importez l'écran de formulaire
import 'package:maintenance_app/screens/collaborateurs/collaborateur_form_screen.dart';

class CollaborateurListScreen extends StatelessWidget {
  const CollaborateurListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. On se connecte aux VRAIES données avec Provider
    final hiveService = context.watch<HiveService>();
    final collaborateurs = hiveService.collaborateursBox.values.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestion des collaborateurs"),
        // 2. Le bouton "Ajouter" est bien dans l'AppBar
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Ajouter un collaborateur',
            onPressed: () {
              // Navigue vers le formulaire en mode "Ajout"
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CollaborateurFormScreen(),
                ),
              );
            },
          ),
        ],
      ),
      // Le FloatingActionButton a été supprimé

      body:
          // 3. On gère le cas où la liste est vide
          collaborateurs.isEmpty
              ? const Center(
                  child: Text(
                    "Aucun collaborateur trouvé.\nAppuyez sur le bouton '+' en haut pour en ajouter un.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: collaborateurs.length,
                  itemBuilder: (context, index) {
                    final collab = collaborateurs[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(collab.prenom.isNotEmpty
                              ? collab.prenom.substring(0, 1)
                              : '?'),
                        ),
                        title: Text(collab.nomComplet),
                        subtitle: Text(collab.fonction.name[0].toUpperCase() +
                            collab.fonction.name.substring(1)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          onPressed: () {
                            // 4. La logique de suppression est fonctionnelle
                            _showDeleteConfirmation(
                                context, hiveService, collab);
                          },
                        ),
                        onTap: () {
                          // 5. La logique de modification est fonctionnelle
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CollaborateurFormScreen(
                                  collaborateur: collab),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }

  // Fonction pour afficher la boîte de dialogue de confirmation de suppression
  void _showDeleteConfirmation(BuildContext context, HiveService hiveService,
      Collaborateur collaborateur) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Confirmation'),
          content: Text(
              'Voulez-vous vraiment supprimer ${collaborateur.nomComplet} ?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(ctx).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Supprimer'),
              onPressed: () {
                // On utilise context.read ici car on est dans une action (pas dans build)
                context
                    .read<HiveService>()
                    .deleteCollaborateur(collaborateur.key);
                Navigator.of(ctx).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
