// lib/screens/equipements/equipement_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:maintenance_app/models/equipement.dart';
import 'package:maintenance_app/models/intervention.dart';
import 'package:maintenance_app/models/panne.dart';
import 'package:maintenance_app/screens/equipements/equipement_form_screen.dart';
import 'package:maintenance_app/services/hive_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class EquipementDetailScreen extends StatelessWidget {
  final String equipementId;

  const EquipementDetailScreen({super.key, required this.equipementId});

  // --- CORRECTION 3 : Méthode _confirmDelete rendue robuste et asynchrone ---
  void _confirmDelete(
      BuildContext context, HiveService service, String id, String nom) async {
    final bool? aSupprimer = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
            'Êtes-vous certain de vouloir supprimer l\'équipement "$nom" et tout son historique (pannes et interventions) ?\n\nCette action est irréversible.'),
        actions: <Widget>[
          TextButton(
            child: const Text('Annuler'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
            onPressed: () {
              service.deleteEquipement(id);
              Navigator.of(ctx).pop(true);
            },
          ),
        ],
      ),
    );

    // On vérifie si le widget est toujours monté AVANT d'utiliser son context
    if (aSupprimer == true && context.mounted) {
      Navigator.of(context).pop();
    }
  }
  // --- FIN DE LA CORRECTION 3 ---

  @override
  Widget build(BuildContext context) {
    final hiveService = context.watch<HiveService>();
    final Equipement? equipement = hiveService.getEquipementById(equipementId);

    if (equipement == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text("Équipement non trouvé ou supprimé.")),
      );
    }

    final interventions =
        hiveService.getInterventionsForEquipement(equipementId);
    final pannes = hiveService.getPannesForEquipement(equipementId);

    return Scaffold(
      appBar: AppBar(
        title: Text(equipement.nom),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Modifier l\'équipement',
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) =>
                    EquipementFormScreen(equipement: equipement),
              ));
            },
          ),
          // --- CORRECTION 1 & 2 : Nom de l'icône corrigé ---
          IconButton(
            icon: const Icon(Icons.delete_forever,
                color: Colors.redAccent), // Pas de _outline
            tooltip: 'Supprimer l\'équipement',
            onPressed: () => _confirmDelete(
                context, hiveService, equipement.id, equipement.nom),
          ),
          // --- FIN DE LA CORRECTION 1 & 2 ---
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(context, equipement),
            const SizedBox(height: 24),
            _buildHistorySection(context, "Historique des interventions",
                _buildInterventionList(context, interventions)),
            const SizedBox(height: 24),
            _buildHistorySection(context, "Historique des pannes",
                _buildPanneList(context, pannes)),
          ],
        ),
      ),
    );
  }

  // --- Widgets utilitaires ---

  Widget _buildInfoCard(BuildContext context, Equipement equipement) {
    final status = equipement.maintenanceStatus;
    final color = _getColorForStatus(status);
    final statusText = _getTextForStatus(status);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.precision_manufacturing,
                  color: Theme.of(context).colorScheme.primary, size: 40),
              title: Text(equipement.nom,
                  style: Theme.of(context).textTheme.headlineSmall),
              subtitle: Text(equipement.type),
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.flag, color: color, size: 30),
              title: Text("Statut: $statusText",
                  style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              subtitle: Text(
                  "Prochaine maintenance : ${DateFormat.yMMMMEEEEd('fr_FR').format(equipement.prochaineMaintenance)}"),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.rocket_launch, size: 30),
              title: const Text("Mise en service"),
              subtitle: Text(DateFormat.yMMMMEEEEd('fr_FR')
                  .format(equipement.dateMiseEnService)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection(BuildContext context, String title, Widget list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const Divider(),
        list,
      ],
    );
  }

  Widget _buildInterventionList(
      BuildContext context, List<Intervention> interventions) {
    if (interventions.isEmpty) {
      return const Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Text("Aucune intervention enregistrée."));
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: interventions.length,
      itemBuilder: (ctx, index) {
        final i = interventions[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: Icon(i.urgence ? Icons.flash_on : Icons.build,
                color: i.urgence ? Colors.amber.shade700 : Colors.grey),
            title: Text(i.type),
            subtitle: Text(DateFormat.yMd('fr_FR').format(i.dateDebut)),
            trailing: Text(NumberFormat.currency(locale: 'fr_FR', symbol: '€')
                .format(i.cout)),
          ),
        );
      },
    );
  }

  Widget _buildPanneList(BuildContext context, List<Panne> pannes) {
    if (pannes.isEmpty) {
      return const Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Text("Aucune panne enregistrée."));
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: pannes.length,
      itemBuilder: (ctx, index) {
        final p = pannes[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: const Icon(Icons.error, color: Colors.red),
            title: Text(p.cause),
            subtitle: Text(DateFormat.yMd('fr_FR').format(p.datePanne)),
          ),
        );
      },
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

  String _getTextForStatus(MaintenanceStatus status) {
    switch (status) {
      case MaintenanceStatus.enRetard:
        return 'En retard';
      case MaintenanceStatus.bientot:
        return 'Bientôt requise';
      case MaintenanceStatus.aJour:
        return 'À jour';
    }
  }
}
