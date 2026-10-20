import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Cosmic Prism: Background & Surfaces ──
  static const Color voidBlack = Color(0xFF05070D); // #05070D Base Canvas
  static const Color midnightNavy = Color(0xFF0A1020); // #0A1020
  static const Color glassSurface = Color(0xFF11182A); // #11182A Glass Panels
  static const Color elevatedSurface = Color(0xFF192238); // #192238 Elevated Cards

  // Core backgrounds & surfaces mapped to system
  static const Color background = voidBlack;
  static const Color backgroundDim = voidBlack;
  static const Color surfaceSecondary = midnightNavy;
  static const Color cardSurface = glassSurface;
  static const Color inputBackground = Color(0xFF090E1B);
  static const Color surfaceVariant = elevatedSurface;
  static const Color surfaceBright = Color(0xFF232D47);

  // ── Cosmic Prism: Neon Accents ──
  static const Color laserCyan = Color(0xFF00D9FF); // #00D9FF
  static const Color electricBlue = Color(0xFF3867FF); // #3867FF
  static const Color neonViolet = Color(0xFF813BFF); // #813BFF
  static const Color prismMagenta = Color(0xFFD946EF); // #D946EF
  static const Color neonPink = Color(0xFFFF5DA8); // #FF5DA8
  static const Color warmGlow = Color(0xFFFFAD73); // #FFAD73

  // Aliases for cosmic accent tokens
  static const Color accentCyan = laserCyan;
  static const Color accentBlue = electricBlue;
  static const Color cardSurfaceElevated = elevatedSurface;

  // Brand accents mapped to design tokens
  static const Color primary = laserCyan; // Primary luminous neon accent
  static const Color onPrimary = Color(0xFF05070D);
  static const Color primaryContainer = electricBlue;
  static const Color onPrimaryContainer = Color(0xFFFFFFFF);

  static const Color secondary = prismMagenta; // Secondary prism magenta
  static const Color onSecondary = Color(0xFF05070D);
  static const Color secondaryContainer = neonViolet;
  static const Color onSecondaryContainer = Color(0xFFFFFFFF);

  // ── Semantic & Status Colors ──
  static const Color success = Color(0xFF42E6A4); // #42E6A4 Active / Emerald
  static const Color warning = Color(0xFFFFB454); // #FFB454 Approaching Expiry
  static const Color error = Color(0xFFFF6174); // #FF6174 Semantic Error
  static const Color onError = Color(0xFF400007);
  static const Color errorContainer = Color(0xFF6B111E);
  static const Color onErrorContainer = Color(0xFFFFD9DD);

  static const Color tertiary = success;
  static const Color onTertiary = Color(0xFF05070D);
  static const Color tertiaryContainer = Color(0xFF0E5C3E);
  static const Color onTertiaryContainer = Color(0xFFD1FAE5);

  // ── Typography & Outlines ──
  static const Color onSurface = Color(0xFFF6F7FF); // Primary text #F6F7FF
  static const Color onSurfaceVariant = Color(0xFFA3ADC4); // Secondary text #A3ADC4
  static const Color outline = Color(0xFF7686A8); // Disabled #7686A8
  static const Color outlineVariant = Color(0xFF253352); // Glass border accent
  static const Color disabled = Color(0xFF7686A8);

  static const Color primaryFixed = Color(0xFFD0F4FF);
  static const Color primaryFixedDim = laserCyan;
  static const Color onPrimaryFixed = Color(0xFF001F29);
  static const Color onPrimaryFixedVariant = electricBlue;
  
  static const Color secondaryFixed = Color(0xFFFCE7FE);
  static const Color secondaryFixedDim = prismMagenta;
  static const Color onSecondaryFixed = Color(0xFF33003B);
  static const Color onSecondaryFixedVariant = neonViolet;

  static const Color tertiaryFixed = Color(0xFFD1FAE5);
  static const Color tertiaryFixedDim = success;
  static const Color onTertiaryFixed = Color(0xFF002113);
  static const Color onTertiaryFixedVariant = Color(0xFF0E5C3E);
}

class AppGradients {
  AppGradients._();

  // Cosmic Electric Blue -> Neon Violet -> Magenta (Primary Action & Hero Buttons)
  static const LinearGradient primaryBlueViolet = LinearGradient(
    colors: [Color(0xFF3867FF), Color(0xFF813BFF), Color(0xFFD946EF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Laser Cyan to Electric Blue (Accent Gradient)
  static const LinearGradient laserCyanBlue = LinearGradient(
    colors: [Color(0xFF00D9FF), Color(0xFF3867FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Holographic Prism Gradient (Cyan -> Violet -> Magenta -> Warm Glow)
  static const LinearGradient cosmicPrism = LinearGradient(
    colors: [
      Color(0xFF00D9FF),
      Color(0xFF813BFF),
      Color(0xFFD946EF),
      Color(0xFFFFAD73),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // AI Gradient (Neon Violet -> Prism Magenta -> Neon Pink)
  static const LinearGradient purpleAI = LinearGradient(
    colors: [Color(0xFF813BFF), Color(0xFFD946EF), Color(0xFFFF5DA8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Warm Aurora Ribbon (Neon Pink -> Warm Glow)
  static const LinearGradient warmAurora = LinearGradient(
    colors: [Color(0xFFFF5DA8), Color(0xFFFFAD73)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Liquid Scan Brackets Gradient (Laser Cyan -> Prism Magenta)
  static const LinearGradient scanBrackets = LinearGradient(
    colors: [Color(0xFF00D9FF), Color(0xFFD946EF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Standard aliases for seamless backward compatibility across all screens
  static const LinearGradient primaryBlueCyan = primaryBlueViolet;
  static const LinearGradient accentBlueCyan = laserCyanBlue;
}

class AppSpacing {
  AppSpacing._();

  static const double base = 8.0;
  static const double xs = 4.0;
  static const double sm = 12.0;
  static const double md = 24.0;
  static const double lg = 40.0;
  static const double xl = 64.0;
  static const double containerMax = 1200.0;
  static const double gutter = 24.0;
}

class AppRadius {
  AppRadius._();

  static const double smVal = 6.0;
  static const double defaultVal = 10.0;
  static const double mdVal = 14.0; // Buttons, inputs
  static const double lgVal = 22.0; // Glass cards (18–24 px specification)

  static final BorderRadius sm = BorderRadius.circular(smVal);
  static final BorderRadius defaultValue = BorderRadius.circular(defaultVal);
  static final BorderRadius md = BorderRadius.circular(mdVal);
  static final BorderRadius lg = BorderRadius.circular(lgVal);
  static final BorderRadius full = BorderRadius.circular(9999.0);
}
