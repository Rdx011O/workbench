import 'package:flutter/material.dart';

/// Calibrated palette for Botanical Planner fresh UI.
/// Combines the crisp, calm pastel aesthetic with modern clean card architecture.
class BotanicalColors {
  // Light Theme (Clean Porcelain Lavender + Deep Slate Plum)
  static const Color lightBackground = Color(0xFFF6F5F9); // fresh lavender porcelain background
  static const Color lightPrimary = Color(0xFF2C2638); // rich dark slate aubergine for bold titles
  static const Color lightPrimaryPressed = Color(0xFF1E1A29);
  static const Color lightAccent = Color(0xFF7A6899); // soft purple accent
  static const Color lightTextPrimary = Color(0xFF221C2B); // high contrast primary text
  static const Color lightTextSecondary = Color(0xFF7D7789); // muted purple-gray secondary label
  static const Color lightSurface = Color(0xFFFFFFFF); // crisp white card surface
  static const Color lightSecondarySurface = Color(0xFFEEEAF4); // soft secondary container
  static const Color lightBorder = Color(0xFFE5E0ED); // subtle clean separator
  static const Color lightCompletedSurface = Color(0xFFE8F3EB); // completed wash
  static const Color lightCompletedText = Color(0xFF2E7D4E);
  static const Color lightReminderSurface = Color(0xFFFDF8E8);
  static const Color lightReminderText = Color(0xFF6B5820);
  static const Color lightError = Color(0xFFFF3B30); // Apple system red

  // Fresh UI Tokens (from screenshot)
  static const Color summaryCardLight = Color(0xFFEBE7F3); // soft lavender summary card
  static const Color summaryCardDark = Color(0xFF242031);
  static const Color taskBadgeLight = Color(0xFFB8B0CF); // purple pill badge
  static const Color taskBadgeDark = Color(0xFF4A4160);
  static const Color taskBadgeText = Color(0xFF2C233C);
  static const Color reminderBadgeLight = Color(0xFFCFDD91); // olive/lime pill badge
  static const Color reminderBadgeDark = Color(0xFF455423);
  static const Color reminderBadgeText = Color(0xFF333E17);
  static const Color alertRed = Color(0xFFB03A48); // red alert circular icon
  static const Color alertRedTitle = Color(0xFF9E2C3A); // reddish alert headline
  static const Color navBarLight = Color(0xFFF4F2F8); // floating nav bar surface
  static const Color navBarBorder = Color(0xFFE5E0ED);

  // Dark Theme (Deep Midnight Slate + Luminous Violet Sage)
  static const Color darkBackground = Color(0xFF13111A); // deep night background
  static const Color darkPrimary = Color(0xFFD4CBE5); // light lilac primary
  static const Color darkPrimaryPressed = Color(0xFFB8AFD0);
  static const Color darkAccent = Color(0xFFA592C7);
  static const Color darkTextPrimary = Color(0xFFF4F2F8);
  static const Color darkTextSecondary = Color(0xFFA49EB2);
  static const Color darkSurface = Color(0xFF1E1A27); // dark card surface
  static const Color darkSecondarySurface = Color(0xFF292435);
  static const Color darkBorder = Color(0xFF332E41);
  static const Color darkCompletedSurface = Color(0xFF1B2E24);
  static const Color darkCompletedText = Color(0xFF67D89A);
  static const Color darkReminderSurface = Color(0xFF322A1E);
  static const Color darkReminderText = Color(0xFFE5C596);
  static const Color darkError = Color(0xFFFF453A);

  // Category tags (pill tokens)
  static const Color tagWork = Color(0xFF6E5E8A);
  static const Color tagPersonal = Color(0xFF8A6E5E);
  static const Color tagHealth = Color(0xFF3B8266);
  static const Color tagReading = Color(0xFF5E758A);
  static const Color tagHome = Color(0xFF7B7280);
}
