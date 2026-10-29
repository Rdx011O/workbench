import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

/// Typography aligned with Queue's design system:
/// Plus Jakarta Sans for functional interface text,
/// and Lora selectively for dates and journal headings.
class WorkbenchTypography {
  static TextTheme createTextTheme({required bool isDark}) {
    final primaryTextColor = isDark ? BotanicalColors.darkTextPrimary : BotanicalColors.lightTextPrimary;
    final secondaryTextColor = isDark ? BotanicalColors.darkTextSecondary : BotanicalColors.lightTextSecondary;

    return TextTheme(
      // Editorial Display (Lora for large dates, headings, and journal moments)
      displayLarge: GoogleFonts.lora(
        fontSize: 34,
        fontWeight: FontWeight.w600,
        color: primaryTextColor,
        letterSpacing: -0.6,
        height: 1.15,
      ),
      displayMedium: GoogleFonts.lora(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: primaryTextColor,
        letterSpacing: -0.4,
        height: 1.18,
      ),
      displaySmall: GoogleFonts.lora(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: primaryTextColor,
        letterSpacing: -0.2,
      ),

      // Plus Jakarta Sans Headings
      headlineLarge: GoogleFonts.plusJakartaSans(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: primaryTextColor,
        letterSpacing: -0.5,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: primaryTextColor,
        letterSpacing: -0.4,
      ),
      headlineSmall: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: primaryTextColor,
        letterSpacing: -0.3,
      ),

      // Navigation & Section Titles
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: primaryTextColor,
        letterSpacing: -0.2,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: primaryTextColor,
        letterSpacing: -0.1,
      ),
      titleSmall: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: primaryTextColor,
      ),

      // Functional Body Hierarchy
      bodyLarge: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: primaryTextColor,
        height: 1.45,
        letterSpacing: -0.1,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: primaryTextColor,
        height: 1.4,
        letterSpacing: -0.1,
      ),
      bodySmall: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: secondaryTextColor,
        height: 1.35,
      ),

      // Labels, Badges & Timestamps
      labelLarge: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: primaryTextColor,
      ),
      labelMedium: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: secondaryTextColor,
      ),
      labelSmall: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: secondaryTextColor,
        letterSpacing: 0.3,
      ),
    );
  }

  /// Lora font styling for date representations
  static TextStyle dateStyle({
    required bool isDark,
    double fontSize = 15,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return GoogleFonts.lora(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: isDark ? BotanicalColors.darkTextSecondary : BotanicalColors.lightTextSecondary,
      letterSpacing: -0.2,
    );
  }

  /// Lora font styling for journal entry reflection content & headings
  static TextStyle journalHeadingStyle({
    required bool isDark,
    double fontSize = 20,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return GoogleFonts.lora(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: isDark ? BotanicalColors.darkTextPrimary : BotanicalColors.lightTextPrimary,
      letterSpacing: -0.2,
    );
  }
}

/// Backward-compatible alias
typedef BotanicalTypography = WorkbenchTypography;
