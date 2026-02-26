import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const Color primary = Color(0xFF6C63FF); // indigo-purple
  static const Color background = Color(0xFF0F0F1A); // near-black
  static const Color surface = Color(0xFF1C1C2E); // dark card
  static const Color onSurface = Color(0xFFF0F0F5);
  static const Color accent = Color(0xFF00E5CC); // teal
  static const Color tagChipBg = Color(0xFF2A2A40);

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary: primary,
          secondary: accent,
          surface: surface,
          onSurface: onSurface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: background,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: onSurface,
          ),
          iconTheme: IconThemeData(color: onSurface),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: surface,
          selectedItemColor: primary,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
        cardTheme: CardThemeData(
          color: surface,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        chipTheme: const ChipThemeData(
          backgroundColor: tagChipBg,
          labelStyle: TextStyle(color: onSurface, fontSize: 13),
          shape: StadiumBorder(),
          padding: EdgeInsets.symmetric(horizontal: 4),
        ),
        progressIndicatorTheme:
            const ProgressIndicatorThemeData(color: primary),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: surface,
          contentTextStyle: const TextStyle(color: onSurface),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
}
