import 'package:flutter/material.dart';

/// GO4 Design System — Calm Forest-Green Theme
///
/// HCI-compliant palette inspired by MongoDB Atlas and GitHub dark mode:
/// · Deep neutral dark backgrounds for reduced eye strain
/// · Forest green primary — natural, accessible, non-fatiguing
/// · Warm amber accent for prices and highlights (WCAG AA contrast)
/// · All interactive targets are ≥ 48 dp (WCAG 2.5.5 AAA touch)
class AppTheme {
  const AppTheme._();

  // ── Core colours ─────────────────────────────────────────────────────────────
  static const Color primary      = Color(0xFF2DA44E); // forest green (GitHub green)
  static const Color primaryLight = Color(0xFF3FB465); // lighter green
  static const Color background   = Color(0xFF0D1117); // near-black
  static const Color surface      = Color(0xFF161B22); // dark card
  static const Color surfaceHigh  = Color(0xFF21262D); // elevated card
  static const Color surfaceBorder= Color(0xFF30363D); // subtle borders
  static const Color onSurface    = Color(0xFFE6EDF3); // near-white text
  static const Color onSurfaceMid = Color(0xFF8B949E); // muted text
  static const Color accent       = Color(0xFFE8912D); // warm amber (prices)
  static const Color accentLight  = Color(0xFFF0A732); // brighter amber
  static const Color tagChipBg    = Color(0xFF2D333B); // chip background
  static const Color error        = Color(0xFFF85149); // soft red

  // ── Semantic aliases (for readability) ───────────────────────────────────────
  static const Color success = Color(0xFF3FB950); // green check
  static const Color warning = Color(0xFFD29922); // amber warning

  // ── Gradients ────────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2DA44E), Color(0xFF1A7F37)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient subtleGradient = LinearGradient(
    colors: [Color(0xFF2DA44E), Color(0xFF3FB465)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const RadialGradient centerGlow = RadialGradient(
    colors: [Color(0x282DA44E), Color(0x000D1117)],
    radius: 0.7,
  );

  // ── Shadows ──────────────────────────────────────────────────────────────────
  static List<BoxShadow> get primaryGlow => [
        BoxShadow(
          color: primary.withValues(alpha: 0.28),
          blurRadius: 20,
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> get accentGlow => [
        BoxShadow(
          color: accent.withValues(alpha: 0.22),
          blurRadius: 16,
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  // ── Theme ────────────────────────────────────────────────────────────────────
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
        // Typography — clean hierarchy, legible weights
        textTheme: const TextTheme(
          displayLarge:  TextStyle(color: onSurface, fontWeight: FontWeight.w800, letterSpacing: -1.0),
          displayMedium: TextStyle(color: onSurface, fontWeight: FontWeight.w700, letterSpacing: -0.5),
          titleLarge:    TextStyle(color: onSurface, fontWeight: FontWeight.w700),
          titleMedium:   TextStyle(color: onSurface, fontWeight: FontWeight.w600),
          bodyLarge:     TextStyle(color: onSurface),
          bodyMedium:    TextStyle(color: onSurfaceMid),
          bodySmall:     TextStyle(color: onSurfaceMid),
          labelLarge:    TextStyle(color: onSurface, fontWeight: FontWeight.w600),
        ),
        // AppBar — minimal, no shadow
        appBarTheme: const AppBarTheme(
          backgroundColor:  background,
          elevation:        0,
          scrolledUnderElevation: 0,
          centerTitle:      true,
          titleTextStyle:   TextStyle(
            fontSize:    18,
            fontWeight:  FontWeight.w700,
            color:       onSurface,
            letterSpacing: -0.2,
          ),
          iconTheme: IconThemeData(color: onSurface),
        ),
        // Cards — flat, border-defined
        cardTheme: CardThemeData(
          color:     surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
          ),
        ),
        // Chips — compact, readable
        chipTheme: const ChipThemeData(
          backgroundColor:  tagChipBg,
          labelStyle:       TextStyle(color: onSurface, fontSize: 12),
          shape:            StadiumBorder(),
          padding:          EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          side:             BorderSide.none,
        ),
        // Input — clear affordance, 14px border-radius
        inputDecorationTheme: InputDecorationTheme(
          filled:     true,
          fillColor:  surfaceHigh,
          hintStyle:  const TextStyle(color: Color(0xFF484F58)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:   BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: surfaceBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: primary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        // Progress
        progressIndicatorTheme: const ProgressIndicatorThemeData(color: primary),
        // Snack bars
        snackBarTheme: SnackBarThemeData(
          backgroundColor: surfaceHigh,
          contentTextStyle: const TextStyle(color: onSurface),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 4,
        ),
        // Elevated buttons — large touch target (≥ 48dp), accessible green
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor:  primary,
            foregroundColor:  Colors.white,
            elevation:        0,
            shadowColor:      Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            textStyle: const TextStyle(
              fontSize:   15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ),
        // Divider
        dividerTheme: DividerThemeData(
          color:     Colors.white.withValues(alpha: 0.07),
          thickness: 1,
          space:     1,
        ),
        // Icon buttons
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(foregroundColor: onSurface),
        ),
        // PopupMenuButton
        popupMenuTheme: PopupMenuThemeData(
          color: surfaceHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: surfaceBorder),
          ),
          textStyle: const TextStyle(color: onSurface, fontSize: 14),
        ),
      );
}
