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
import 'package:lottie/lottie.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:url_launcher/url_launcher.dart';
import 'package:maintenance_app/screens/kanban/kanban_screen.dart';

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
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showAproposDialog(context);
            },
          ),
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
            _buildNavigationCard(context, 'Kanban', Icons.view_kanban_outlined,
                const KanbanScreen()),
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

void _showAproposDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Center(
        // Centrer la boîte de dialogue
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: EdgeInsets.zero, // Supprimer les marges par défaut
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.topCenter,
                children: [
                  const SizedBox(
                    width: 300,
                    height: 323,
                  ),
                  Container(
                    width: 300,
                    height: 300,
                    //color: Colors.white,
                    alignment: Alignment.centerLeft,
                    child: Lottie.asset('assets/blob_lottie.json',
                        width: 300, height: 300, fit: BoxFit.fill),
                  ),
                  Positioned(
                    top: 40,
                    child: Container(
                      width: 200,
                      height: 200,
                      margin: const EdgeInsets.all(
                          10), // Marge entre l'image et les bords
                      decoration: const BoxDecoration(
                        color: Colors.transparent, // Couleur de fond du cercle
                        shape: BoxShape.circle, // Forme circulaire
                        image: DecorationImage(
                          image: AssetImage(
                              'assets/Eric-portrait-petit-Alpha.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 80,
                    left: 40, // Descend le demi-cercle
                    child: CustomPaint(
                      size: const Size(320, 160), // Taille du demi-cercle
                      painter: HalfCircle(),
                    ),
                  ),
                  Positioned(
                    top: 270,
                    child: Column(
                      // Utilisez une colonne pour empiler le texte et le lien
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '3IME',
                          style: TextStyle(
                            color: Colors
                                .black, // Adaptez la couleur si votre thème est sombre
                            fontFamily: 'Inter',
                            fontSize: 24.0,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        // Ajout du lien
                        GestureDetector(
                          onTap: () async {
                            final Uri url = Uri.parse('https://www.3ime.fr/');
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url);
                            } else {
                              // Gérer le cas où le lien ne peut pas être ouvert
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Impossible d\'ouvrir le lien')),
                              );
                            }
                          },
                          child: const Text(
                            'www.3ime.fr',
                            style: TextStyle(
                              color: Colors.blue, // Couleur de lien typique
                              decoration: TextDecoration
                                  .underline, // Souligner pour indiquer que c'est un lien
                              fontSize: 16.0,
                              decorationColor: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop(); // Fermer l'AlertDialog
                },
                icon: const Icon(Icons.exit_to_app),
                label: const Text('Fermer'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      );
    },
  );
}

class HalfCircle extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const rect = Rect.fromLTRB(0, 0, 220, 180);
    const startAngle = 0.0;
    const sweepAngle = math.pi;
    const useCenter = false;
    final paint = Paint()
      ..shader =
          ui.Gradient.linear(const Offset(0, 0), const Offset(220, 180), [
        const Color(0xffda1b60),
        const Color(0xffff8a00),
      ])
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;

    canvas.drawArc(rect, startAngle, sweepAngle, useCenter, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
