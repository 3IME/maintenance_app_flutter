// lib/screens/pannes/panne_list_screen.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintenance_app/models/panne.dart';
import 'package:maintenance_app/screens/pannes/panne_form_screen.dart';
import 'package:maintenance_app/services/hive_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class PanneListScreen extends StatelessWidget {
  const PanneListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hiveService = context.watch<HiveService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des Pannes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const PanneFormScreen()),
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: hiveService.pannesBox.listenable(),
        builder: (context, Box<Panne> box, _) {
          // --- LIGNE MANQUANTE ICI ---
          final pannes = box.values.toList();
          pannes.sort((a, b) => b.datePanne.compareTo(a.datePanne));
          // --- FIN DE LA LIGNE MANQUANTE ---

          if (pannes.isEmpty) {
            return const Center(
                child: Text(
                    'Aucune panne trouvée. Appuyez sur + pour en signaler une.'));
          }

          return ListView.builder(
            itemCount: pannes.length, // 'pannes' est maintenant défini
            itemBuilder: (context, index) {
              final panne = pannes[index];
              final equipement =
                  hiveService.getEquipementById(panne.equipmentId);
              final bool isRepaired = panne.dateReparation != null;
              final Color statusColor = isRepaired ? Colors.green : Colors.red;
              final IconData statusIcon =
                  isRepaired ? Icons.check_circle : Icons.error;
              final String statusText = isRepaired ? 'Réparé' : 'En cours';

              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: ListTile(
                  leading: Icon(statusIcon, color: statusColor, size: 30),
                  title: Text(panne.cause),
                  subtitle: Text(
                      'Équipement: ${equipement?.nom ?? 'N/A'}\nLe ${DateFormat.yMd('fr_FR').format(panne.datePanne)}'),
                  isThreeLine: true,
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                PanneFormScreen(panne: panne)));
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize
                        .min, // Pour que la Row prenne le moins de place possible
                    children: [
                      Text(statusText,
                          style: TextStyle(
                              color: statusColor, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.grey),
                        tooltip: 'Supprimer la panne',
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Confirmer la suppression'),
                              content: const Text(
                                  'Voulez-vous vraiment supprimer cette panne ?'),
                              actions: [
                                TextButton(
                                    child: const Text('Annuler'),
                                    onPressed: () => Navigator.of(ctx).pop()),
                                TextButton(
                                  style: TextButton.styleFrom(
                                      foregroundColor: Colors.red),
                                  child: const Text('Supprimer'),
                                  onPressed: () {
                                    hiveService.deletePanne(panne.id);
                                    Navigator.of(ctx).pop();
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
