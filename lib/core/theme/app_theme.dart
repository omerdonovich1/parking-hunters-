import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ── Cyber-hunter palette — 2026 game aesthetic ─────────────────────────────
  // Primary: electric cyan — radar, scan, info HUD, map badges
  static const Color orange      = Color(0xFF00D4FF);  // electric cyan (legacy name kept)
  static const Color orangeGlow  = Color(0xFF60EEFF);  // lighter cyan highlight

  // Hunter action: hot magenta — CTAs, Hunt button, I Parked Here
  static const Color energy      = Color(0xFFFF2D78);
  static const Color energyGlow  = Color(0xFFFF6FAC);

  // Status neons
  static const Color neonGreen   = Color(0xFF00FF88);  // available — electric lime
  static const Color neonYellow  = Color(0xFFFFD700);  // soon — gold
  static const Color neonRed     = Color(0xFFFF3366);  // danger — hot red

  // ── Deep space surfaces ────────────────────────────────────────────────────
  static const Color bg          = Color(0xFF030814);  // abyss navy
  static const Color surface     = Color(0xFF071020);
  static const Color card        = Color(0xFF0C1A30);
  static const Color cardBorder  = Color(0xFF1C3558);
  static const Color divider     = Color(0xFF0F2038);

  // ── Light surfaces ─────────────────────────────────────────────────────────
  static const Color bgLight     = Color(0xFFF0F4FF);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight   = Color(0xFFFFFFFF);

  // keep backward compat
  static const Color primaryColor   = orange;
  static const Color secondaryColor = neonGreen;
  static const Color surfaceDark    = bg;
  static const Color cardDark       = card;

  // ── P3 compat aliases ──────────────────────────────────────────────────────
  static const Color blue           = Color(0xFF1DA1F2);
  static const Color blueDark       = Color(0xFF0D8AD6);
  static const Color blueLight      = Color(0xFFE8F5FE);
  static const Color textDark       = Color(0xFF0F172A);
  static const Color textMuted      = Color(0xFF64748B);
  static const Color dividerLight   = Color(0xFFE2E8F0);

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

  // Action gradient — magenta (primary CTAs)
  static BoxDecoration orangeGradient({double radius = 16}) => BoxDecoration(
    gradient: const LinearGradient(
      colors: [energy, Color(0xFFBB0055)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(radius),
    boxShadow: [
      BoxShadow(color: energy.withValues(alpha: 0.5), blurRadius: 22, offset: const Offset(0, 8)),
    ],
  );

  // Cyan gradient — scan / navigate
  static BoxDecoration cyanGradient({double radius = 16}) => BoxDecoration(
    gradient: const LinearGradient(
      colors: [orange, Color(0xFF007799)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(radius),
    boxShadow: [
      BoxShadow(color: orange.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8)),
    ],
  );

  // ── Dark theme ─────────────────────────────────────────────────────────────
  // ── Status chip decoration — glow pill ────────────────────────────────────
  static BoxDecoration statusChip(Color color, {bool selected = false}) =>
      BoxDecoration(
        color: selected ? color.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: selected ? color.withValues(alpha: 0.55) : Colors.white.withValues(alpha: 0.08),
          width: 1.2,
        ),
        boxShadow: selected
            ? [BoxShadow(color: color.withValues(alpha: 0.30), blurRadius: 14, spreadRadius: 0)]
            : [],
      );

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      // Heebo covers Hebrew + Latin — single font for the whole app
      fontFamily: GoogleFonts.heebo().fontFamily,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(
        primary: orange,
        secondary: neonGreen,
        surface: surface,
        onSurface: Colors.white,
        onPrimary: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: energy,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: orange,
          side: const BorderSide(color: orange, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
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
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: orange, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: orange,
        unselectedItemColor: Color(0xFF2A4A6A),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: TextStyle(fontSize: 11),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: energy,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: CircleBorder(),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: card,
        selectedColor: orange.withValues(alpha: 0.18),
        side: const BorderSide(color: cardBorder),
        labelStyle: const TextStyle(fontSize: 12, color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
      dividerTheme: const DividerThemeData(color: divider, thickness: 1, space: 1),
      textTheme: GoogleFonts.heeboTextTheme(
        const TextTheme(
          displayLarge:  TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
          displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.3),
          headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
          headlineMedium:TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
          titleLarge:    TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
          titleMedium:   TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
          bodyLarge:     TextStyle(fontSize: 15, color: Color(0xFFCBD5E1)),
          bodyMedium:    TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          labelLarge:    TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: orange, letterSpacing: 0.3),
          labelSmall:    TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B), letterSpacing: 0.5),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: GoogleFonts.heebo(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  // ── Light theme ────────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: GoogleFonts.heebo().fontFamily,
      scaffoldBackgroundColor: bgLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: energy,
        secondary: neonGreen,
        brightness: Brightness.light,
        surface: surfaceLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFF0D1117),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0D1117), letterSpacing: 0.3),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: energy,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: cardLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: orange, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey.shade100,
        selectedColor: orange.withValues(alpha: 0.12),
        labelStyle: const TextStyle(fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: energy,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: CircleBorder(),
      ),
      textTheme: GoogleFonts.heeboTextTheme(
        const TextTheme(
          displayLarge:  TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Color(0xFF080B14)),
          headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF080B14)),
          headlineMedium:TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF080B14)),
          titleLarge:    TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF0D1117)),
          bodyLarge:     TextStyle(fontSize: 15, color: Color(0xFF374151)),
          bodyMedium:    TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          labelLarge:    TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: energy),
        ),
      ),
    );
  }
}
