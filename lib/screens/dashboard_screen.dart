// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:maintenance_app/models/equipement.dart';
import 'package:maintenance_app/screens/equipements/equipement_list_screen.dart';
import 'package:maintenance_app/screens/interventions/intervention_list_screen.dart';
import 'package:maintenance_app/screens/pannes/panne_list_screen.dart';
import 'package:maintenance_app/services/hive_service.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // Widget pour construire les cartes de statistiques
  Widget _buildStatCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias, // Coupe le contenu qui déborde
      color: color.withAlpha((255 * 0.1).round()),
      child: Padding(
        padding: const EdgeInsets.all(8.0),

        // On utilise SingleChildScrollView pour éviter les erreurs d'overflow
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              // FittedBox pour que le texte se redimensionne si besoin
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // On écoute les changements pour que le dashboard se mette à jour
    final hiveService = context.watch<HiveService>();
    final equipements = hiveService.equipementsBox.values.toList();
    final interventions = hiveService.interventionsBox.values.toList();
    final pannes = hiveService.pannesBox.values.toList();

    // Calculs pour les statistiques
    final totalCost =
        interventions.fold<double>(0, (sum, item) => sum + item.cout);
    final maintenanceEnRetard = equipements
        .where((e) => e.maintenanceStatus == MaintenanceStatus.enRetard)
        .length;
    final maintenanceBientot = equipements
        .where((e) => e.maintenanceStatus == MaintenanceStatus.bientot)
        .length;

    // Données pour la grille de statistiques
    final statCardsData = [
      {
        'icon': Icons.precision_manufacturing,
        'title': 'Équipements',
        'value': equipements.length.toString(),
        'color': Colors.blue
      },
      {
        'icon': Icons.build,
        'title': 'Interventions',
        'value': interventions.length.toString(),
        'color': Colors.green
      },
      {
        'icon': Icons.error,
        'title': 'Pannes',
        'value': pannes.length.toString(),
        'color': Colors.orange
      },
      {
        'icon': Icons.euro,
        'title': 'Coût Total',
        'value': NumberFormat.currency(locale: 'fr_FR', symbol: '€')
            .format(totalCost),
        'color': Colors.red
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard de Maintenance'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Vue d'ensemble",
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
                childAspectRatio: 1.2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: statCardsData.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final cardData = statCardsData[index];
                return _buildStatCard(
                  context: context,
                  icon: cardData['icon'] as IconData,
                  title: cardData['title'] as String,
                  value: cardData['value'] as String,
                  color: cardData['color'] as Color,
                );
              },
            ),
            const SizedBox(height: 24),
            Text("État des Maintenances",
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildMaintenanceStatus(
                context, maintenanceEnRetard, maintenanceBientot),
            const SizedBox(height: 24),
            Text("Répartition par Type",
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildTypeChart(context, equipements),
            const SizedBox(height: 24),
            Text("Gestion", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildNavigationCard(
                context,
                'Gérer les Équipements',
                Icons.precision_manufacturing_outlined,
                const EquipementListScreen()),
            _buildNavigationCard(context, 'Gérer les Interventions',
                Icons.build_outlined, const InterventionListScreen()),
            _buildNavigationCard(context, 'Gérer les Pannes',
                Icons.error_outline, const PanneListScreen()),
          ],
        ),
      ),
    );
  }

  // Widget pour la carte de statut de maintenance
  Widget _buildMaintenanceStatus(
      BuildContext context, int enRetard, int bientot) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Text(enRetard.toString(),
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(color: Colors.red)),
                const Text('En retard', style: TextStyle(color: Colors.red)),
              ],
            ),
            Column(
              children: [
                Text(bientot.toString(),
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(color: Colors.orange)),
                const Text('Bientôt', style: TextStyle(color: Colors.orange)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget pour le graphique de répartition
  Widget _buildTypeChart(BuildContext context, List<Equipement> equipements) {
    if (equipements.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: Text("Aucune donnée pour le graphique.")),
        ),
      );
    }

    final Map<String, int> typeCounts = {};
    for (var equipement in equipements) {
      typeCounts[equipement.type] = (typeCounts[equipement.type] ?? 0) + 1;
    }

    final List<PieChartSectionData> sections = [];
    final List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal
    ];
    int colorIndex = 0;

    typeCounts.forEach((type, count) {
      final section = PieChartSectionData(
        color: colors[colorIndex % colors.length],
        value: count.toDouble(),
        title: '$count',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [Shadow(color: Colors.black, blurRadius: 2)],
        ),
      );
      sections.add(section);
      colorIndex++;
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(
              height: 150,
              child: PieChart(
                  PieChartData(sections: sections, centerSpaceRadius: 40)),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: typeCounts.keys.map((type) {
                final index = typeCounts.keys.toList().indexOf(type);
                return _buildLegend(type, colors[index % colors.length]);
              }).toList(),
            )
          ],
        ),
      ),
    );
  }

  // Widget pour la légende du graphique
  Widget _buildLegend(String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 16, height: 16, color: color),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }

  // Widget pour les cartes de navigation
  Widget _buildNavigationCard(
      BuildContext context, String title, IconData icon, Widget screen) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => screen));
        },
      ),
    );
  }
}
