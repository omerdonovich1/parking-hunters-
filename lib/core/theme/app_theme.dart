import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  AppTheme._();

  // ── Brand palette ──────────────────────────────────────────────────────────
  static const Color blue        = Color(0xFF1DA1F2);  // primary
  static const Color blueDark    = Color(0xFF0D8AD6);
  static const Color blueLight   = Color(0xFFE8F5FE);
  static const Color orange      = Color(0xFFFF6B35);  // kept for gamification
  static const Color orangeGlow  = Color(0xFFFF8C5A);
  static const Color neonGreen   = Color(0xFF00C853);
  static const Color neonYellow  = Color(0xFFFFD600);
  static const Color neonRed     = Color(0xFFFF1744);

  // ── Light surfaces ─────────────────────────────────────────────────────────
  static const Color bgLight      = Color(0xFFF5F8FF);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight    = Color(0xFFFFFFFF);
  static const Color textDark     = Color(0xFF0F172A);
  static const Color textMuted    = Color(0xFF64748B);
  static const Color dividerLight = Color(0xFFE2E8F0);

  // ── Dark surfaces ──────────────────────────────────────────────────────────
  static const Color bg          = Color(0xFF080B14);
  static const Color surface     = Color(0xFF0D1117);
  static const Color card        = Color(0xFF111827);
  static const Color cardBorder  = Color(0xFF1F2937);
  static const Color divider     = Color(0xFF1A2236);

  // keep backward compat
  static const Color primaryColor   = blue;
  static const Color secondaryColor = neonGreen;
  static const Color surfaceDark    = bg;
  static const Color cardDark       = card;

  // ── Card shadow (light mode) ───────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0xFF1DA1F2).withValues(alpha: 0.07),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  // ── Glassmorphism helpers ──────────────────────────────────────────────────
  static BoxDecoration glassCard({double opacity = 0.06, double radius = 20}) =>
      BoxDecoration(
        color: Colors.white.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
      );

  static BoxDecoration glassCardDark({double opacity = 0.5, double radius = 20}) =>
      BoxDecoration(
        color: card.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: cardBorder, width: 1),
      );

  static BoxDecoration blueGradient({double radius = 20}) => BoxDecoration(
    gradient: const LinearGradient(
      colors: [blue, blueDark],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(radius),
    boxShadow: [
      BoxShadow(
          color: blue.withValues(alpha: 0.35),
          blurRadius: 20,
          offset: const Offset(0, 8)),
    ],
  );

  static BoxDecoration orangeGradient({double radius = 16}) => BoxDecoration(
    gradient: const LinearGradient(
      colors: [orange, Color(0xFFFF3D00)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(radius),
    boxShadow: [
      BoxShadow(
          color: orange.withValues(alpha: 0.4),
          blurRadius: 20,
          offset: const Offset(0, 8)),
    ],
  );

  // ── Light theme ────────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgLight,
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.fromSeed(
        seedColor: blue,
        primary: blue,
        secondary: neonGreen,
        brightness: Brightness.light,
        surface: surfaceLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textDark,
          letterSpacing: 0.2,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: blue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          padding:
              const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          textStyle: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: blue,
          side: const BorderSide(color: blue, width: 1.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          padding:
              const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: cardLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        shadowColor: blue.withValues(alpha: 0.1),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F5FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: dividerLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: blue, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle:
            TextStyle(color: textMuted.withValues(alpha: 0.6), fontSize: 14),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: blue,
        unselectedItemColor: Color(0xFF94A3B8),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle:
            TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: TextStyle(fontSize: 11),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: blue,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: CircleBorder(),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: blueLight,
        selectedColor: blue.withValues(alpha: 0.15),
        side: BorderSide.none,
        labelStyle:
            const TextStyle(fontSize: 12, color: textDark),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      dividerTheme: const DividerThemeData(
          color: dividerLight, thickness: 1, space: 1),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            color: textDark,
            letterSpacing: -0.5),
        displayMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: textDark,
            letterSpacing: -0.3),
        headlineLarge: TextStyle(
            fontSize: 24, fontWeight: FontWeight.w800, color: textDark),
        headlineMedium: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w700, color: textDark),
        titleLarge: TextStyle(
            fontSize: 17, fontWeight: FontWeight.w700, color: textDark),
        titleMedium: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w600, color: textDark),
        bodyLarge:
            TextStyle(fontSize: 15, color: Color(0xFF334155)),
        bodyMedium:
            TextStyle(fontSize: 13, color: textMuted),
        labelLarge: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: blue,
            letterSpacing: 0.3),
        labelSmall: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: textMuted,
            letterSpacing: 0.8),
      ),
    );
  }

  // ── Dark theme ─────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      fontFamily: 'Roboto',
      colorScheme: const ColorScheme.dark(
        primary: blue,
        secondary: neonGreen,
        surface: surface,
        onSurface: Colors.white,
        onPrimary: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 0.3,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: blue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          padding:
              const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          textStyle: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: blue,
          side: const BorderSide(color: blue, width: 1.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          padding:
              const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: cardBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF111827),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: blue, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
        labelStyle:
            TextStyle(color: Colors.white.withValues(alpha: 0.5)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: blue,
        unselectedItemColor: Color(0xFF4B5563),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle:
            TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: TextStyle(fontSize: 11),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: blue,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: CircleBorder(),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: card,
        selectedColor: blue.withValues(alpha: 0.15),
        side: const BorderSide(color: cardBorder),
        labelStyle:
            const TextStyle(fontSize: 12, color: Colors.white),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
      dividerTheme:
          const DividerThemeData(color: divider, thickness: 1, space: 1),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -0.5),
        displayMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.3),
        headlineLarge: TextStyle(
            fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
        headlineMedium: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
        titleLarge: TextStyle(
            fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
        titleMedium: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
        bodyLarge:
            TextStyle(fontSize: 15, color: Color(0xFFCBD5E1)),
        bodyMedium:
            TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
        labelLarge: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: blue,
            letterSpacing: 0.3),
        labelSmall: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
            letterSpacing: 0.5),
      ),
    );
  }
}
