import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Pour accéder au ThemeCubit
import 'package:intl/date_symbol_data_local.dart'; // Pour initializeDateFormatting
import 'package:provider/provider.dart'; // Pour accéder au HiveService

import 'package:maintenance_app/screens/dashboard_screen.dart'; // L'écran vers lequel naviguer
import 'package:maintenance_app/services/hive_service.dart';
import 'package:maintenance_app/core/theme/theme_cubit.dart'; // Assurez-vous d'importer ThemeCubit

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key}); // Plus besoin de windowId ou mainWindowId

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  final double imageSize = 150.0;

  late double _leftPosition;
  late double _topPosition;
  late double _dx;
  late double _dy;
  Timer? _animationTimer;
  bool _showImage = true;

  @override
  void initState() {
    super.initState();
    _leftPosition = 50;
    _topPosition = 50;
    _dx = 2;
    _dy = 2;

    _animationTimer = Timer.periodic(const Duration(milliseconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _updatePosition();
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAndNavigate();
    });
  }

  void _updatePosition() {
    final Size screenBounds = MediaQuery.of(context).size;
    final double contentWidth = screenBounds.width;
    final double contentHeight = screenBounds.height;

    if (_leftPosition <= 0 || _leftPosition >= contentWidth - imageSize) {
      _dx = -_dx;
    }
    if (_topPosition <= 0 || _topPosition >= contentHeight - imageSize) {
      _dy = -_dy;
    }
    _leftPosition += _dx;
    _topPosition += _dy;
  }

  Future<void> _initializeAndNavigate() async {
    final hiveService = Provider.of<HiveService>(context, listen: false);
    final themeCubit = BlocProvider.of<ThemeCubit>(context, listen: false);

    await hiveService.init();
    await themeCubit.loadTheme();
    await initializeDateFormatting('fr_FR', null);

    // Disparaître l’image à 2.8 secondes
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) {
        setState(() {
          _showImage = false;
        });
      }
    });

    // Attendre jusqu’à 3 secondes au total
    await Future.delayed(const Duration(seconds: 3));

    _animationTimer?.cancel();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    }
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 14),
            left: _leftPosition,
            top: _topPosition,
            child: AnimatedOpacity(
              opacity: _showImage ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                width: imageSize,
                height: imageSize,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: AssetImage('assets/logo2_1024.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
