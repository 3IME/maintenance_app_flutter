import 'package:flutter/material.dart';
import 'package:maintenance_app/models/equipement.dart';
import 'package:maintenance_app/screens/equipements/equipement_list_screen.dart';
import 'package:maintenance_app/screens/interventions/intervention_list_screen.dart';
import 'package:maintenance_app/screens/pannes/panne_list_screen.dart';
import 'package:maintenance_app/services/hive_service.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart'; // Cet import est maintenant utilisé !
import 'package:intl/intl.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hiveService = Provider.of<HiveService>(context);
    final equipements = hiveService.equipementsBox.values.toList();
    final interventions = hiveService.interventionsBox.values.toList();
    final pannes = hiveService.pannesBox.values.toList();

    final totalCost =
        interventions.fold<double>(0, (sum, item) => sum + item.cout);
    final maintenanceEnRetard = equipements
        .where((e) => e.maintenanceStatus == MaintenanceStatus.enRetard)
        .length;
    final maintenanceBientot = equipements
        .where((e) => e.maintenanceStatus == MaintenanceStatus.bientot)
        .length;

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
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStatCard(context, Icons.precision_manufacturing,
                    'Équipements', equipements.length.toString(), Colors.blue),
                _buildStatCard(context, Icons.build, 'Interventions',
                    interventions.length.toString(), Colors.green),
                _buildStatCard(context, Icons.error, 'Pannes',
                    pannes.length.toString(), Colors.orange),
                _buildStatCard(
                    context,
                    Icons.euro,
                    'Coût Total',
                    NumberFormat.currency(locale: 'fr_FR', symbol: '€')
                        .format(totalCost),
                    Colors.red),
              ],
            ),
            const SizedBox(height: 24),
            Text("État des Maintenances",
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildMaintenanceStatus(
                context, maintenanceEnRetard, maintenanceBientot),

            // --- NOUVELLE SECTION POUR LE GRAPHIQUE ---
            const SizedBox(height: 24),
            Text("Répartition par Type",
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildTypeChart(context, equipements),
            // --- FIN DE LA NOUVELLE SECTION ---

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

  // NOUVEAU WIDGET POUR LE GRAPHIQUE
  Widget _buildTypeChart(BuildContext context, List<Equipement> equipements) {
    if (equipements.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: Text("Aucune donnée pour le graphique.")),
        ),
      );
    }

    // 1. Compter les équipements par type
    final Map<String, int> typeCounts = {};
    for (var equipement in equipements) {
      typeCounts[equipement.type] = (typeCounts[equipement.type] ?? 0) + 1;
    }

    // 2. Créer les sections du graphique
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

    // 3. Construire le widget du graphique
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(
              height: 150,
              child: PieChart(PieChartData(sections: sections)),
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

  // --- Le reste des méthodes ne change pas ---

  Widget _buildStatCard(BuildContext context, IconData icon, String title,
      String value, Color color) {
    return Card(
      color: color.withAlpha((255 * 0.1).round()),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 10),
            Text(title, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 4),
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

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
