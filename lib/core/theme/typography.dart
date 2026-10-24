import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

/// Apple HIG-aligned typography with optical sizes, Dynamic Type scaling,
/// and distinctive botanical editorial display fonts.
class BotanicalTypography {
  static TextTheme createTextTheme({required bool isDark}) {
    final primaryTextColor = isDark ? BotanicalColors.darkTextPrimary : BotanicalColors.lightTextPrimary;
    final secondaryTextColor = isDark ? BotanicalColors.darkTextSecondary : BotanicalColors.lightTextSecondary;

    return TextTheme(
      // Signature Editorial Display (used for large date displays & header moments)
      displayLarge: GoogleFonts.dmSerifDisplay(
        fontSize: 34,
        fontWeight: FontWeight.normal,
        color: primaryTextColor,
        letterSpacing: -0.6,
        height: 1.15,
      ),
      displayMedium: GoogleFonts.dmSerifDisplay(
        fontSize: 28,
        fontWeight: FontWeight.normal,
        color: primaryTextColor,
        letterSpacing: -0.4,
        height: 1.18,
      ),
      displaySmall: GoogleFonts.dmSerifDisplay(
        fontSize: 22,
        fontWeight: FontWeight.normal,
        color: primaryTextColor,
        letterSpacing: -0.2,
      ),

      // Apple SF-Style Interface Headings (Inter with Apple tracking)
      headlineLarge: GoogleFonts.inter(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: primaryTextColor,
        letterSpacing: -0.5,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: primaryTextColor,
        letterSpacing: -0.4,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: primaryTextColor,
        letterSpacing: -0.3,
      ),

      // Navigation & Card Section Titles
      titleLarge: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: primaryTextColor,
        letterSpacing: -0.2,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: primaryTextColor,
        letterSpacing: -0.1,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: primaryTextColor,
      ),

      // Apple Body Hierarchy (Default 17pt mobile standard per HIG Lens 1)
      bodyLarge: GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        color: primaryTextColor,
        height: 1.45,
        letterSpacing: -0.2,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: primaryTextColor,
        height: 1.4,
        letterSpacing: -0.15,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: secondaryTextColor,
        height: 1.35,
      ),

      // Metadata, Timestamps, Badges (Tabular figures for clean vertical alignment)
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: primaryTextColor,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: secondaryTextColor,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: secondaryTextColor,
        letterSpacing: 0.4,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
