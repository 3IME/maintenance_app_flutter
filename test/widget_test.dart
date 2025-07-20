// test/widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:maintenance_app/main.dart'; // Contient MainApplicationWidget
import 'package:maintenance_app/services/hive_service.dart';
import 'package:maintenance_app/core/theme/theme_cubit.dart';
import 'package:maintenance_app/screens/dashboard_screen.dart'; // Pour le test du Dashboard

void main() {
  testWidgets('Test du démarrage de l\'application et du SplashScreen',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<HiveService>(create: (_) => HiveService()),
          BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()),
        ],
        // Utilisez MainApplicationWidget ici !
        child:
            const MainApplicationWidget(), // Le nom de votre classe d'application principale
      ),
    );

    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Dashboard de Maintenance'), findsNothing);
  });

  testWidgets('Test du contenu du DashboardScreen',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<HiveService>(create: (_) => HiveService()),
          BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()),
        ],
        child: const MaterialApp(
          home: DashboardScreen(),
        ),
      ),
    );

    expect(find.text('Dashboard de Maintenance'), findsOneWidget);
  });
}
