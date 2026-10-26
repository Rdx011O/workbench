import 'package:flutter/material.dart';

/// Complete Color Specification for Botanical Planner.
/// Implements exact 20-token Light and Dark palette as defined in the specification.
class BotanicalColors {
  // 1. App background
  static const Color lightBackground = Color(0xFFF2F0F5);
  static const Color darkBackground = Color(0xFF25232D);

  // 2. Main containers
  static const Color lightMainContainer = Color(0xFFFFFFFF);
  static const Color darkMainContainer = Color(0xFF302D38);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color darkSurface = Color(0xFF302D38);

  // 3. Secondary containers
  static const Color lightSecondaryContainer = Color(0xFFE5E0EA);
  static const Color darkSecondaryContainer = Color(0xFF35313D);
  static const Color lightSecondarySurface = Color(0xFFE5E0EA);
  static const Color darkSecondarySurface = Color(0xFF35313D);

  // 4. Primary buttons
  static const Color lightPrimaryButton = Color(0xFF685580);
  static const Color darkPrimaryButton = Color(0xFFC8B8DF);
  static const Color lightPrimary = Color(0xFF685580);
  static const Color darkPrimary = Color(0xFFC8B8DF);

  // 5. Primary button text
  static const Color lightPrimaryButtonText = Color(0xFFFFFFFF);
  static const Color darkPrimaryButtonText = Color(0xFF292630);
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color darkOnPrimary = Color(0xFF292630);

  // 6. Secondary buttons
  static const Color lightSecondaryButton = Color(0xFFE5E0EA);
  static const Color darkSecondaryButton = Color(0xFF403749);

  // 7. Secondary button text
  static const Color lightSecondaryButtonText = Color(0xFF554368);
  static const Color darkSecondaryButtonText = Color(0xFFE3D9EF);

  // 8. Main text
  static const Color lightMainText = Color(0xFF292630);
  static const Color darkMainText = Color(0xFFF2EFF6);
  static const Color lightTextPrimary = Color(0xFF292630);
  static const Color darkTextPrimary = Color(0xFFF2EFF6);

  // 9. Secondary text
  static const Color lightSecondaryText = Color(0xFF625B6C);
  static const Color darkSecondaryText = Color(0xFFB4ACBF);
  static const Color lightTextSecondary = Color(0xFF625B6C);
  static const Color darkTextSecondary = Color(0xFFB4ACBF);

  // 10. Borders and dividers
  static const Color lightBorder = Color(0xFFDCD6E4);
  static const Color darkBorder = Color(0xFF494451);
  static const Color lightDivider = Color(0xFFDCD6E4);
  static const Color darkDivider = Color(0xFF494451);

  // 11. Selected navigation
  static const Color lightSelectedNav = Color(0xFF685580);
  static const Color darkSelectedNav = Color(0xFFC8B8DF);

  // 12. Selected date
  static const Color lightSelectedDate = Color(0xFFE1D9ED);
  static const Color darkSelectedDate = Color(0xFF403749);

  // 13. Input background
  static const Color lightInputBackground = Color(0xFFFFFFFF);
  static const Color darkInputBackground = Color(0xFF302D38);

  // 14. Input border
  static const Color lightInputBorder = Color(0xFFDCD6E4);
  static const Color darkInputBorder = Color(0xFF494451);

  // 15. Input placeholder
  static const Color lightInputPlaceholder = Color(0xFF777180);
  static const Color darkInputPlaceholder = Color(0xFFA69DB2);

  // 16. Completed task
  static const Color lightCompletedTask = Color(0xFFE8E6EC);
  static const Color darkCompletedTask = Color(0xFF35313D);
  static const Color lightCompletedSurface = Color(0xFFE8E6EC);
  static const Color darkCompletedSurface = Color(0xFF35313D);
  static const Color lightCompletedText = Color(0xFF456B5B);
  static const Color darkCompletedText = Color(0xFFA7CCB6);

  // 17. Success
  static const Color lightSuccess = Color(0xFF456B5B);
  static const Color darkSuccess = Color(0xFFA7CCB6);

  // 18. Reminder
  static const Color lightReminder = Color(0xFFF0E5D6);
  static const Color darkReminder = Color(0xFFD8B98E);
  static const Color lightReminderSurface = Color(0xFFF0E5D6);
  static const Color darkReminderSurface = Color(0xFFD8B98E);
  static const Color lightReminderText = Color(0xFF554368);
  static const Color darkReminderText = Color(0xFF292630);

  // 19. Error
  static const Color lightError = Color(0xFFA34D58);
  static const Color darkError = Color(0xFFF0A0AB);

  // 20. Disabled button
  static const Color lightDisabledButton = Color(0xFFE5E2E9);
  static const Color darkDisabledButton = Color(0xFF393641);

  // --- UI Convenience Tokens & Aliases ---
  static const Color lightAccent = Color(0xFF685580);
  static const Color darkAccent = Color(0xFFC8B8DF);
  static const Color lightPrimaryPressed = Color(0xFF554368);
  static const Color darkPrimaryPressed = Color(0xFFB4ACBF);

  static const Color summaryCardLight = Color(0xFFE5E0EA); // secondary container
  static const Color summaryCardDark = Color(0xFF35313D);

  static const Color taskBadgeLight = Color(0xFFE1D9ED); // selected date / lilac wash
  static const Color taskBadgeDark = Color(0xFF403749);
  static const Color taskBadgeText = Color(0xFF554368); // secondary button text

  static const Color reminderBadgeLight = Color(0xFFF0E5D6); // reminder surface
  static const Color reminderBadgeDark = Color(0xFF403749);
  static const Color reminderBadgeText = Color(0xFF554368);

  static const Color alertRed = Color(0xFFA34D58); // error
  static const Color alertRedTitle = Color(0xFFA34D58);

  static const Color navBarLight = Color(0xFFFFFFFF);
  static const Color navBarBorder = Color(0xFFDCD6E4);

  // Category tags (pill tokens)
  static const Color tagWork = Color(0xFF685580);
  static const Color tagPersonal = Color(0xFF456B5B);
  static const Color tagHealth = Color(0xFF456B5B);
  static const Color tagReading = Color(0xFF554368);
  static const Color tagHome = Color(0xFF625B6C);
}
