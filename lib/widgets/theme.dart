import 'package:flutter/material.dart';

class AppTheme {
  static const Color bg = Color(0xFF0A0E14);
  static const Color bgCard = Color(0xFF0F1923);
  static const Color bgElevated = Color(0xFF151F2E);
  static const Color border = Color(0xFF1E3048);
  static const Color borderActive = Color(0xFF00E5CC);
  static const Color cyan = Color(0xFF00E5CC);
  static const Color cyanDark = Color(0xFF00B39E);
  static const Color green = Color(0xFF00FF88);
  static const Color red = Color(0xFFFF4466);
  static const Color yellow = Color(0xFFFFCC00);
  static const Color orange = Color(0xFFFF8844);
  static const Color purple = Color(0xFFAA66FF);
  static const Color blue = Color(0xFF4488FF);
  static const Color pink = Color(0xFFFF66AA);
  static const Color textPrimary = Color(0xFFE0E8F0);
  static const Color textSecondary = Color(0xFF6B8299);
  static const Color textDim = Color(0xFF3D5266);

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        fontFamily: 'FiraCode',
        colorScheme: const ColorScheme.dark(
          primary: cyan,
          secondary: green,
          surface: bgCard,
          error: red,
          onPrimary: bg,
          onSecondary: bg,
          onSurface: textPrimary,
          onError: bg,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: bg,
          foregroundColor: cyan,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontFamily: 'FiraCode',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: cyan,
            letterSpacing: 2,
          ),
        ),
        cardTheme: CardThemeData(
          color: bgCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: border, width: 1),
          ),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontFamily: 'FiraCode', fontSize: 18, fontWeight: FontWeight.bold, color: cyan, letterSpacing: 2),
          headlineMedium: TextStyle(fontFamily: 'FiraCode', fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary, letterSpacing: 1),
          headlineSmall: TextStyle(fontFamily: 'FiraCode', fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary),
          bodyLarge: TextStyle(fontFamily: 'FiraCode', fontSize: 12, color: textPrimary, height: 1.5),
          bodyMedium: TextStyle(fontFamily: 'FiraCode', fontSize: 11, color: textSecondary, height: 1.5),
          bodySmall: TextStyle(fontFamily: 'FiraCode', fontSize: 10, color: textDim, height: 1.4),
          labelLarge: TextStyle(fontFamily: 'FiraCode', fontSize: 11, fontWeight: FontWeight.bold, color: cyan, letterSpacing: 1),
        ),
        iconTheme: const IconThemeData(color: cyan, size: 18),
        dividerTheme: const DividerThemeData(color: border, thickness: 1),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: bg,
          selectedItemColor: cyan,
          unselectedItemColor: textDim,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: TextStyle(fontFamily: 'FiraCode', fontSize: 9, letterSpacing: 1),
          unselectedLabelStyle: TextStyle(fontFamily: 'FiraCode', fontSize: 9, letterSpacing: 1),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: bgElevated,
            foregroundColor: cyan,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: const BorderSide(color: border),
            ),
            textStyle: const TextStyle(fontFamily: 'FiraCode', fontSize: 11, letterSpacing: 1),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: cyan,
            side: const BorderSide(color: cyan, width: 1),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            textStyle: const TextStyle(fontFamily: 'FiraCode', fontSize: 11, letterSpacing: 1),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: bgCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: border),
          ),
          titleTextStyle: const TextStyle(fontFamily: 'FiraCode', fontSize: 14, fontWeight: FontWeight.bold, color: cyan, letterSpacing: 1),
          contentTextStyle: const TextStyle(fontFamily: 'FiraCode', fontSize: 11, color: textPrimary),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: bgElevated,
          contentTextStyle: TextStyle(fontFamily: 'FiraCode', fontSize: 11, color: textPrimary),
        ),
      );
}
