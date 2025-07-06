import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:maintenance_app/screens/dashboard_screen.dart';
import 'package:maintenance_app/services/hive_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final hiveService = HiveService();
  await hiveService.init();

  await initializeDateFormatting('fr_FR', null);

  runApp(
    ChangeNotifierProvider.value(
      value: hiveService,
      child: const MaintenanceApp(),
    ),
  );
}

class MaintenanceApp extends StatelessWidget {
  const MaintenanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestion de Maintenance',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,

      // --- AJOUTS IMPORTANTS ICI ---
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'FR'), // Français
        Locale('en', 'US'), // Anglais, comme fallback
      ],
      locale: const Locale(
          'fr', 'FR'), // Définit le français comme langue par défaut
      // --- FIN DES AJOUTS ---

      home: const DashboardScreen(),
    );
  }
}
