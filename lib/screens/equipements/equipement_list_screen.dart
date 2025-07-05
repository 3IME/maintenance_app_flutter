// lib/screens/equipements/equipement_list_screen.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintenance_app/models/equipement.dart';
import 'package:maintenance_app/screens/equipements/equipement_detail_screen.dart';
import 'package:maintenance_app/screens/equipements/equipement_form_screen.dart'; // <-- Ajoutez cet import
import 'package:maintenance_app/services/hive_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class EquipementListScreen extends StatelessWidget {
  const EquipementListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hiveService = Provider.of<HiveService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste des Équipements'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // --- MODIFICATION ICI ---
              // On navigue vers l'écran de formulaire
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const EquipementFormScreen()));
              // --- FIN DE LA MODIFICATION ---
            },
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: hiveService.equipementsBox.listenable(),
        builder: (context, Box<Equipement> box, _) {
          final equipements = box.values.toList();
          // Trier pour afficher les plus urgents en premier
          equipements.sort((a, b) =>
              a.maintenanceStatus.index.compareTo(b.maintenanceStatus.index));

          if (equipements.isEmpty) {
            return const Center(
                child: Text(
                    'Aucun équipement. Appuyez sur + pour en ajouter un.'));
          }
          return ListView.builder(
            itemCount: equipements.length,
            itemBuilder: (context, index) {
              final equipement = equipements[index];
              final status = equipement.maintenanceStatus;
              final color = _getColorForStatus(status);

              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color,
                    child: Icon(
                      _getIconForStatus(status),
                      color: Colors.white,
                    ),
                  ),
                  title: Text(equipement.nom,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      'Type: ${equipement.type}\nProch. maint: ${DateFormat.yMd('fr_FR').format(equipement.prochaineMaintenance)}'),
                  isThreeLine: true,
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => EquipementDetailScreen(
                                equipementId: equipement.id)));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getColorForStatus(MaintenanceStatus status) {
    switch (status) {
      case MaintenanceStatus.enRetard:
        return Colors.red;
      case MaintenanceStatus.bientot:
        return Colors.orange;
      case MaintenanceStatus.aJour:
        return Colors.green;
    }
  }

  IconData _getIconForStatus(MaintenanceStatus status) {
    switch (status) {
      case MaintenanceStatus.enRetard:
        return Icons.error_outline;
      case MaintenanceStatus.bientot:
        return Icons.warning_amber;
      case MaintenanceStatus.aJour:
        return Icons.check;
    }
  }
}
