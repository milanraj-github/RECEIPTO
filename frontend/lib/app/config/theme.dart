import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:receipto/core/constants/constants.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      
      colorScheme: const ColorScheme.dark(
        surface: AppColors.cardSurface,
        onSurface: AppColors.onSurface,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.onSecondaryContainer,
        tertiary: AppColors.tertiary,
        onTertiary: AppColors.onTertiary,
        tertiaryContainer: AppColors.tertiaryContainer,
        onTertiaryContainer: AppColors.onTertiaryContainer,
        error: AppColors.error,
        onError: AppColors.onError,
        errorContainer: AppColors.errorContainer,
        onErrorContainer: AppColors.onErrorContainer,
      ),

      // Text Theme mapping to design system
      textTheme: TextTheme(
        // display-lg (Large financial totals)
        displayLarge: GoogleFonts.inter(
          fontSize: 44,
          fontWeight: FontWeight.w700,
          height: 52 / 44,
          letterSpacing: -0.02 * 44,
          color: AppColors.onSurface,
        ),
        // headline-lg
        headlineLarge: GoogleFonts.inter(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          height: 38 / 30,
          letterSpacing: -0.01 * 30,
          color: AppColors.onSurface,
        ),
        // headline-md
        headlineMedium: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          height: 28 / 22,
          color: AppColors.onSurface,
        ),
        // body-lg
        bodyLarge: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w400,
          height: 26 / 17,
          color: AppColors.onSurface,
        ),
        // body-md
        bodyMedium: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          height: 22 / 15,
          color: AppColors.onSurface,
        ),
        // label-md (Geist font fallback)
        labelLarge: AppFonts.geist(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 20 / 14,
          letterSpacing: 0.02 * 14,
          color: AppColors.onSurface,
        ),
        // code-sm (Geist font fallback)
        labelMedium: AppFonts.geist(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 16 / 12,
          color: AppColors.onSurfaceVariant,
        ),
      ),
      
      // Inputs styling: Dark translucent glass with subtle luminous borders
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputBackground.withValues(alpha: 0.85),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: GoogleFonts.inter(
          color: AppColors.onSurfaceVariant.withValues(alpha: 0.45),
          fontSize: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.md,
          borderSide: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.md,
          borderSide: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.md,
          borderSide: const BorderSide(color: AppColors.laserCyan, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.md,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.md,
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
    );
  }
}

class AppFonts {
  AppFonts._();

  static TextStyle geist({
    required double fontSize,
    required FontWeight fontWeight,
    required double height,
    double? letterSpacing,
    required Color color,
  }) {
    try {
      return GoogleFonts.getFont(
        'Geist',
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
        letterSpacing: letterSpacing,
        color: color,
      );
    } catch (_) {
      // Fallback monospaced font
      return GoogleFonts.firaCode(
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
        letterSpacing: letterSpacing,
        color: color,
      );
    }
  }
}

// Convenient Extension to easily read typography
extension AppTypography on TextTheme {
  TextStyle get displayLg => displayLarge!;
  TextStyle get headlineLg => headlineLarge!;
  TextStyle get headlineMd => headlineMedium!;
  TextStyle get bodyLg => bodyLarge!;
  TextStyle get bodyMd => bodyMedium!;
  TextStyle get labelMd => labelLarge!;
  TextStyle get codeSm => labelMedium!;
}
