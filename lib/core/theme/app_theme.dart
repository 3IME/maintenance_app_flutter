// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';

class AppTheme {
  // Thème Clair
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primarySwatch: Colors.blue,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light, // Important de le spécifier ici aussi
    ),

    // C'EST ICI QUE LA MAGIE OPÈRE
    appBarTheme: const AppBarTheme(
      // Couleur de fond de l'AppBar en thème clair
      backgroundColor: Colors
          .blue, // ou Colors.white, ou Theme.of(context).colorScheme.primaryContainer...

      // Couleur du texte du titre et des icônes (comme le bouton toggle)
      // En thème clair, sur un fond indigo, on veut du blanc.
      foregroundColor: Colors.black,
    ),

    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );

  // Thème Sombre
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primarySwatch: Colors.indigo,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.indigo,
      brightness: Brightness.dark, // Important pour le thème sombre
    ),

    // ET ICI AUSSI POUR LE THÈME SOMBRE
    appBarTheme: AppBarTheme(
      // Couleur de fond de l'AppBar en thème sombre.
      // Un gris très foncé est souvent un bon choix.
      backgroundColor: Colors.grey[900],

      // Couleur du texte du titre et des icônes.
      // En thème sombre, sur un fond foncé, on veut du blanc.
      foregroundColor: Colors.white,
    ),

    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.grey[850],
    ),
  );
}
