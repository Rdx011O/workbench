import 'package:flutter/material.dart';

/// Calibrated Apple Human Interface Guidelines palette for Botanical Planner.
/// Combines Apple's crisp, accessible system contrast rules with a distinctive botanical craft identity.
class BotanicalColors {
  // Light Theme (Apple iOS Grouped + Calm Botanical Ink)
  static const Color lightBackground = Color(0xFFF4F5F2); // crisp Apple grouped background with subtle organic warmth
  static const Color lightPrimary = Color(0xFF1E6B47); // rich Apple botanical emerald (5.5:1 contrast against white)
  static const Color lightPrimaryPressed = Color(0xFF155034); // pressed emerald
  static const Color lightAccent = Color(0xFFC46B3B); // warm Apple terracotta
  static const Color lightTextPrimary = Color(0xFF1C1C1E); // Apple system primary label
  static const Color lightTextSecondary = Color(0xFF6E7570); // Apple system secondary label (4.6:1 contrast)
  static const Color lightSurface = Color(0xFFFFFFFF); // crisp pure Apple card surface
  static const Color lightSecondarySurface = Color(0xFFEAECE7); // subtle secondary grouped stone
  static const Color lightBorder = Color(0xFFE0E3DD); // Apple hairline separator (0.5 - 1px)
  static const Color lightCompletedSurface = Color(0xFFE2F0E7); // soft completed green wash
  static const Color lightCompletedText = Color(0xFF1C6B47);
  static const Color lightReminderSurface = Color(0xFFF7EEDF); // warm parchment accent
  static const Color lightReminderText = Color(0xFF684925);
  static const Color lightError = Color(0xFFFF3B30); // Apple system red

  // Dark Theme (Apple OLED Forest Charcoal + Vibrant Sage)
  static const Color darkBackground = Color(0xFF0E1311); // deep Apple OLED dark background
  static const Color darkPrimary = Color(0xFF42BA78); // Apple vibrant botanical green for dark mode
  static const Color darkPrimaryPressed = Color(0xFF339861);
  static const Color darkAccent = Color(0xFFE88A58); // warm terracotta
  static const Color darkTextPrimary = Color(0xFFF2F4F2); // Apple crisp dark text
  static const Color darkTextSecondary = Color(0xFF9AA59E); // Apple muted sage label
  static const Color darkSurface = Color(0xFF1A221E); // Apple dark grouped card surface
  static const Color darkSecondarySurface = Color(0xFF232D28); // deep moss gray
  static const Color darkBorder = Color(0xFF2A3630); // subtle dark hairline
  static const Color darkCompletedSurface = Color(0xFF1B2E23); // deep emerald completed
  static const Color darkCompletedText = Color(0xFF66D899);
  static const Color darkReminderSurface = Color(0xFF33291B);
  static const Color darkReminderText = Color(0xFFE6C697);
  static const Color darkError = Color(0xFFFF453A); // Apple dark system red

  // Category tags (Apple pill tokens)
  static const Color tagWork = Color(0xFF1E6B47);
  static const Color tagPersonal = Color(0xFFC46B3B);
  static const Color tagHealth = Color(0xFF328A6E);
  static const Color tagReading = Color(0xFF8A6C48);
  static const Color tagHome = Color(0xFF5E6E82);
}
