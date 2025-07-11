import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:maintenance_app/core/theme/theme_cubit.dart';
import 'package:maintenance_app/models/equipement.dart';
import 'package:maintenance_app/services/hive_service.dart';

import 'package:maintenance_app/screens/equipements/equipement_list_screen.dart';
import 'package:maintenance_app/screens/interventions/intervention_list_screen.dart';
import 'package:maintenance_app/screens/pannes/panne_list_screen.dart';
import 'package:maintenance_app/screens/collaborateurs/collaborateur_list_screen.dart';
import 'package:maintenance_app/screens/planning/planning_screen.dart';
import 'package:maintenance_app/screens/shop/shop_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // Widget pour construire les cartes de statistiques
  Widget _buildStatCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    required Color accentColor,
  }) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: accentColor, width: 5),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: accentColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: textColor?.withAlpha((255 * 0.8).round()),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hiveService = context.watch<HiveService>();
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
        'value': NumberFormat.currency(
                locale: 'fr_FR', symbol: '€', decimalDigits: 0)
            .format(totalCost),
        'color': Colors.red
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard de Maintenance'),
        centerTitle: true,
        actions: [
          BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, state) {
              return IconButton(
                icon: Icon(state == ThemeMode.light
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined),
                onPressed: () => context.read<ThemeCubit>().toggleTheme(),
              );
            },
          ),
        ],
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
                  accentColor: cardData['color'] as Color,
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

            // --- SECTION GESTION
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
            _buildNavigationCard(context, 'Gérer les Collaborateurs',
                Icons.people_alt_outlined, const CollaborateurListScreen()),
            _buildNavigationCard(context, 'Planning de Maintenance',
                Icons.calendar_month_outlined, const PlanningScreen()),
            const SizedBox(height: 24), // Espace à la fin de la page

            // --- SECTION MAGASIN
            Text("Magasin", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildNavigationCard(context, 'Gérer les pièces détachées',
                Icons.inventory_2_outlined, const ShopScreen()),

            const SizedBox(height: 24), // Espace à la fin de la page
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

    final List<Color> colors = [
      Colors.blue.shade400,
      Colors.green.shade400,
      Colors.orange.shade400,
      Colors.purple.shade400,
      Colors.red.shade400,
      Colors.teal.shade400,
      Colors.pink.shade300,
      Colors.amber.shade600,
    ];

    final List<PieChartSectionData> sections = [];
    int colorIndex = 0;

    typeCounts.forEach((type, count) {
      sections.add(
        PieChartSectionData(
          color: colors[colorIndex % colors.length],
          value: count.toDouble(),
          title: '$count',
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [Shadow(color: Colors.black, blurRadius: 2)],
          ),
        ),
      );
      colorIndex++;
    });

    return Card(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 280,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 35,
                    pieTouchData: PieTouchData(
                      touchCallback: (event, pieTouchResponse) {},
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                children: typeCounts.keys.map((type) {
                  final index = typeCounts.keys.toList().indexOf(type);
                  return _buildLegend(type, colors[index % colors.length]);
                }).toList(),
              )
            ],
          ),
        ),
      ),
    );
  }

  // Widget pour la légende du graphique
  Widget _buildLegend(String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(text),
      ],
    );
  }

  // --- NOUVELLE VERSION DE LA CARTE DE NAVIGATION (STYLE LISTE) ---
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
