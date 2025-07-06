// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Nos imports pour le thème
import 'package:maintenance_app/core/theme/app_theme.dart';
import 'package:maintenance_app/core/theme/theme_cubit.dart';

import 'package:maintenance_app/screens/dashboard_screen.dart';
import 'package:maintenance_app/services/hive_service.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. On crée nos services manuellement
  final hiveService = HiveService();
  final themeCubit = ThemeCubit();

  // 2. On les initialise
  await hiveService.init();
  await themeCubit.loadTheme(); // Chargement du thème
  await initializeDateFormatting('fr_FR', null);

  runApp(
    // On utilise MultiProvider pour fournir nos deux services
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: hiveService),
        BlocProvider.value(value: themeCubit),
      ],
      child: const MaintenanceApp(),
    ),
  );
}

class MaintenanceApp extends StatelessWidget {
  const MaintenanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        return MaterialApp(
          title: 'Gestion de Maintenance',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('fr', 'FR'),
            Locale('en', 'US'),
          ],
          locale: const Locale('fr', 'FR'),
          home: const DashboardScreen(),
        );
      },
    );
  }
}
