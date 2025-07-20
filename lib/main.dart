import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:maintenance_app/core/theme/app_theme.dart';
import 'package:maintenance_app/core/theme/theme_cubit.dart';
import 'package:maintenance_app/services/hive_service.dart';
import 'package:maintenance_app/screens/splash_screen.dart'; // Importe la SplashScreen
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Les initialisations lourdes (Hive, thème, etc.) seront gérées dans SplashScreen.
  // initializeDateFormatting('fr_FR', null); // Initialisation déplacée si nécessaire
  // Centrage de la fenêtre (si Desktop uniquement)
  await windowManager.ensureInitialized();
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1100, 750),
    center: true, // ✅ centrage automatique
    title: 'maintenance_app',
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const MainApplicationWidget());
}

class MainApplicationWidget extends StatefulWidget {
  const MainApplicationWidget({super.key});

  @override
  State<MainApplicationWidget> createState() => _MainApplicationWidgetState();
}

class _MainApplicationWidgetState extends State<MainApplicationWidget>
    with WidgetsBindingObserver {
  // WidgetsBindingObserver peut toujours être utile pour le cycle de vie global
  // Ces services seront initialisés dans SplashScreen, pas ici.
  // Ils seront ensuite passés via les Providers.
  final HiveService _hiveService = HiveService();
  final ThemeCubit _themeCubit = ThemeCubit();

  @override
  void initState() {
    super.initState();
    debugPrint('MainApplicationWidget initState appelé.');
    WidgetsBinding.instance.addObserver(this);
    // Pas d'initialisation de services ici car c'est géré par SplashScreen.
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('Changement de l\'état de l\'application : $state');
    // Ici, vous pouvez gérer les événements globaux du cycle de vie de l'application
    // par exemple, sauvegarder des données avant la suspension.
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    debugPrint(
        'MainApplicationWidget dispose appelé. Fermeture de l\'application...');
    // Assurez-vous que tous les services sont fermés ici si le dispose est appelé.
    // Cela devrait être géré par les providers ou par la logique de la splash screen si elle appelle directement.
    _hiveService
        .close(); // Ferme Hive ici ou là où le service est géré globalement
    _themeCubit.close(); // Ferme le cubit
    super.dispose();
    // Dans une application Flutter Desktop à fenêtre unique, exit(0) est souvent géré automatiquement
    // par le framework quand la fenêtre est fermée.
    // Si ce n'est pas le cas, vous pouvez l'ajouter :
    // exit(0);
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
        'MainApplicationWidget build appelé. Lance SplashScreen comme home.');
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _hiveService),
        BlocProvider.value(value: _themeCubit),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
            title: 'maintenance_app',
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
            home: const SplashScreen(), // SplashScreen est le premier écran
          );
        },
      ),
    );
  }
}
