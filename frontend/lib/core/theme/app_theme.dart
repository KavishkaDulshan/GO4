import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  // ── Core colours ────────────────────────────────────────────────────────────
  static const Color primary     = Color(0xFF6C63FF); // indigo-purple
  static const Color primaryLight= Color(0xFF9B93FF); // lighter purple
  static const Color background  = Color(0xFF0A0A14); // near-black (deeper)
  static const Color surface     = Color(0xFF16162A); // dark card
  static const Color surfaceHigh = Color(0xFF1E1E35); // elevated card
  static const Color onSurface   = Color(0xFFF0F0F8);
  static const Color accent      = Color(0xFF00E5CC); // teal
  static const Color accentLight = Color(0xFF4FFFEA); // brighter teal
  static const Color tagChipBg   = Color(0xFF252540);
  static const Color error       = Color(0xFFFF5B70);

  // ── Gradients ───────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF00E5CC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGlow = LinearGradient(
    colors: [Color(0xFF8B7FFF), Color(0xFF6C63FF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const RadialGradient centerGlow = RadialGradient(
    colors: [Color(0x336C63FF), Color(0x0006030E)],
    radius: 0.7,
  );

  // ── Shadows & Glows ─────────────────────────────────────────────────────────
  static List<BoxShadow> get primaryGlow => [
        BoxShadow(
          color: primary.withValues(alpha: 0.35),
          blurRadius: 24,
          spreadRadius: 2,
        ),
      ];

  static List<BoxShadow> get accentGlow => [
        BoxShadow(
          color: accent.withValues(alpha: 0.30),
          blurRadius: 20,
          spreadRadius: 1,
        ),
      ];

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.40),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  // ── Theme ───────────────────────────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary:   primary,
          secondary: accent,
          surface:   surface,
          onSurface: onSurface,
          error:     error,
        ),
        // Typography
        textTheme: const TextTheme(
          displayLarge:  TextStyle(color: onSurface, fontWeight: FontWeight.w800, letterSpacing: -1.0),
          displayMedium: TextStyle(color: onSurface, fontWeight: FontWeight.w700, letterSpacing: -0.5),
          titleLarge:    TextStyle(color: onSurface, fontWeight: FontWeight.w700),
          titleMedium:   TextStyle(color: onSurface, fontWeight: FontWeight.w600),
          bodyLarge:     TextStyle(color: onSurface),
          bodyMedium:    TextStyle(color: Color(0xFFB8B8D0)),
          bodySmall:     TextStyle(color: Color(0xFF8888AA)),
          labelLarge:    TextStyle(color: onSurface, fontWeight: FontWeight.w600),
        ),
        // AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor:  background,
          elevation:        0,
          scrolledUnderElevation: 0,
          centerTitle:      true,
          titleTextStyle:   TextStyle(
            fontSize:    18,
            fontWeight:  FontWeight.w700,
            color:       onSurface,
            letterSpacing: -0.3,
          ),
          iconTheme: IconThemeData(color: onSurface),
        ),
        // Cards
        cardTheme: CardThemeData(
          color:     surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        // Chips
        chipTheme: const ChipThemeData(
          backgroundColor:  tagChipBg,
          labelStyle:       TextStyle(color: onSurface, fontSize: 12),
          shape:            StadiumBorder(),
          padding:          EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          side:             BorderSide.none,
        ),
        // Input / TextField
        inputDecorationTheme: InputDecorationTheme(
          filled:     true,
          fillColor:  surfaceHigh,
          hintStyle:  const TextStyle(color: Color(0xFF555577)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:   BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:   BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:   const BorderSide(color: primary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        // Progress indicators
        progressIndicatorTheme: const ProgressIndicatorThemeData(color: primary),
        // Snack bars
        snackBarTheme: SnackBarThemeData(
          backgroundColor: surfaceHigh,
          contentTextStyle: const TextStyle(color: onSurface),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 8,
        ),
        // Elevated buttons
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor:  primary,
            foregroundColor:  Colors.white,
            elevation:        0,
            shadowColor:      Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            textStyle: const TextStyle(
              fontSize:   15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
        // Divider
        dividerTheme: DividerThemeData(
          color:     Colors.white.withValues(alpha: 0.06),
          thickness: 1,
          space:     1,
        ),
        // Icon button
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(foregroundColor: onSurface),
        ),
      );
}
