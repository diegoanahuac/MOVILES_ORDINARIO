import 'package:flutter/material.dart';

/// Paleta y tema de la app: tonos tierra cálidos, como un cuaderno de viaje.
abstract final class AppTheme {
  static const terracota = Color(0xFFB85C38);
  static const arena = Color(0xFFF6EFE6);
  static const tinta = Color(0xFF2E2A27);

  static ThemeData claro() {
    final esquema = ColorScheme.fromSeed(
      seedColor: terracota,
      surface: arena,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      scaffoldBackgroundColor: arena,
      appBarTheme: const AppBarTheme(
        backgroundColor: arena,
        foregroundColor: tinta,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: terracota,
        foregroundColor: Colors.white,
      ),
    );
  }
}
