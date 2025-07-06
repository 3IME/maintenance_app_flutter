import 'package:flutter/material.dart';
import 'package:maintenance_app/models/intervention.dart';
import 'package:maintenance_app/services/hive_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintenance_app/screens/interventions/intervention_form_screen.dart';

class InterventionListScreen extends StatelessWidget {
  const InterventionListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hiveService = context.watch<HiveService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste des interventions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const InterventionFormScreen()),
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: hiveService.interventionsBox.listenable(),
        builder: (context, Box<Intervention> box, _) {
          final interventions = box.values.toList();
          interventions.sort(
              (a, b) => b.dateDebut.compareTo(a.dateDebut)); // Trier par date

          if (interventions.isEmpty) {
            return const Center(
                child: Text(
                    'Aucune intervention trouvée. Appuyez sur + pour en ajouter une.'));
          }

          return ListView.builder(
            itemCount:
                interventions.length, // Maintenant, 'interventions' est défini
            itemBuilder: (context, index) {
              final intervention = interventions[index];
              final equipement =
                  hiveService.getEquipementById(intervention.equipmentId);

              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: ListTile(
                  leading: Icon(
                    intervention.urgence ? Icons.flash_on : Icons.build,
                    color: intervention.urgence
                        ? Colors.amber.shade700
                        : Colors.grey,
                  ),
                  title: Text(
                      '${intervention.type} sur ${equipement?.nom ?? 'Équipement supprimé'}'),
                  subtitle: Text(
                      'Du ${DateFormat.yMd('fr_FR').format(intervention.dateDebut)} au ${DateFormat.yMd('fr_FR').format(intervention.dateFin)}\nCoût: ${NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(intervention.cout)}'),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.grey),
                    tooltip: 'Supprimer l\'intervention',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Confirmer la suppression'),
                          content: const Text(
                              'Voulez-vous vraiment supprimer cette intervention ?'),
                          actions: [
                            TextButton(
                                child: const Text('Annuler'),
                                onPressed: () => Navigator.of(ctx).pop()),
                            TextButton(
                              style: TextButton.styleFrom(
                                  foregroundColor: Colors.red),
                              child: const Text('Supprimer'),
                              onPressed: () {
                                hiveService.deleteIntervention(intervention.id);
                                Navigator.of(ctx).pop();
                              },
                            ),
                          ],
                        ),
                      );
                    },
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
