import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/update_service.dart';
import '../../core/theme/colors.dart';
import '../../providers/providers.dart';
import '../../widgets/apple_widgets.dart';
import '../../widgets/botanical_icons.dart';
import '../../widgets/update_dialog.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? BotanicalColors.darkPrimary : BotanicalColors.lightPrimary;

    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 60),
          children: [
            // Apple Profile Card
            AppleGroupedCard(
              children: [
                AppleListTile(
                  showDivider: false,
                  leading: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        settings.userName.isNotEmpty ? settings.userName.substring(0, 1).toUpperCase() : 'B',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    settings.userName,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Botanical Personal Organizer · Offline-first',
                    style: TextStyle(fontSize: 13, color: CupertinoColors.systemGrey),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Edit',
                      style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                  onTap: () => _showEditNameDialog(context, ref, settings.userName),
                ),
              ],
            ),

            // Section 1: Appearance & Theme
            const AppleSectionHeader('Appearance & Theme'),
            AppleGroupedCard(
              children: [
                AppleListTile(
                  icon: BotanicalIcons.lightMode,
                  iconColor: const Color(0xFFFF9500),
                  iconBackgroundColor: const Color(0xFFFF9500).withOpacity(0.15),
                  title: const Text('Appearance', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        settings.themeMode == ThemeMode.light
                            ? 'Light'
                            : settings.themeMode == ThemeMode.dark
                                ? 'Dark'
                                : 'System',
                        style: const TextStyle(fontSize: 15, color: CupertinoColors.systemGrey),
                      ),
                      const SizedBox(width: 6),
                      const Icon(CupertinoIcons.chevron_right, size: 14, color: CupertinoColors.systemGrey2),
                    ],
                  ),
                  onTap: () => _showThemeSelectionSheet(context, ref, settings.themeMode),
                ),
                AppleListTile(
                  showDivider: false,
                  icon: BotanicalIcons.spark,
                  iconColor: const Color(0xFFAF52DE),
                  iconBackgroundColor: const Color(0xFFAF52DE).withOpacity(0.15),
                  title: const Text('Botanical Accent', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildColorDot(context, ref, '1E6B47', settings.accentColorHex),
                      const SizedBox(width: 8),
                      _buildColorDot(context, ref, 'C46B3B', settings.accentColorHex),
                      const SizedBox(width: 8),
                      _buildColorDot(context, ref, '328A6E', settings.accentColorHex),
                      const SizedBox(width: 8),
                      _buildColorDot(context, ref, '8A6C48', settings.accentColorHex),
                    ],
                  ),
                ),
              ],
            ),

            // Section 2: Calendar & Timing
            const AppleSectionHeader('Calendar & Timing'),
            AppleGroupedCard(
              children: [
                AppleListTile(
                  icon: BotanicalIcons.calendar,
                  iconColor: const Color(0xFFFF3B30),
                  iconBackgroundColor: const Color(0xFFFF3B30).withOpacity(0.15),
                  title: const Text('Start Week on Monday', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                  trailing: CupertinoSwitch(
                    value: settings.weekStartMonday,
                    activeTrackColor: primaryColor,
                    onChanged: (val) {
                      AppleHaptics.selection();
                      ref.read(settingsProvider.notifier).updateSettings(
                            settings.copyWith(weekStartMonday: val),
                          );
                    },
                  ),
                ),
                AppleListTile(
                  showDivider: false,
                  icon: BotanicalIcons.time,
                  iconColor: const Color(0xFF007AFF),
                  iconBackgroundColor: const Color(0xFF007AFF).withOpacity(0.15),
                  title: const Text('24-Hour Time', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                  trailing: CupertinoSwitch(
                    value: settings.timeFormat24Hour,
                    activeTrackColor: primaryColor,
                    onChanged: (val) {
                      AppleHaptics.selection();
                      ref.read(settingsProvider.notifier).updateSettings(
                            settings.copyWith(timeFormat24Hour: val),
                          );
                    },
                  ),
                ),
              ],
            ),

            // Section 3: Notifications & Inputs
            const AppleSectionHeader('Notifications & Input'),
            AppleGroupedCard(
              children: [
                AppleListTile(
                  icon: BotanicalIcons.reminder,
                  iconColor: const Color(0xFFFF2D55),
                  iconBackgroundColor: const Color(0xFFFF2D55).withOpacity(0.15),
                  title: const Text('Scheduled Reminders', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                  trailing: CupertinoSwitch(
                    value: settings.notificationsEnabled,
                    activeTrackColor: primaryColor,
                    onChanged: (val) async {
                      AppleHaptics.selection();
                      if (val) {
                        final granted = await NotificationService.instance.requestPermissions();
                        if (!granted && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Notification permissions were not granted by the OS.'),
                            ),
                          );
                        }
                      }
                      ref.read(settingsProvider.notifier).updateSettings(
                            settings.copyWith(notificationsEnabled: val),
                          );
                    },
                  ),
                ),
                AppleListTile(
                  showDivider: false,
                  icon: BotanicalIcons.microphone,
                  iconColor: const Color(0xFF5856D6),
                  iconBackgroundColor: const Color(0xFF5856D6).withOpacity(0.15),
                  title: const Text('Voice Reflections', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                  trailing: CupertinoSwitch(
                    value: settings.voiceInputEnabled,
                    activeTrackColor: primaryColor,
                    onChanged: (val) {
                      AppleHaptics.selection();
                      ref.read(settingsProvider.notifier).updateSettings(
                            settings.copyWith(voiceInputEnabled: val),
                          );
                    },
                  ),
                ),
              ],
            ),

            // Section 4: Data & Local Storage
            const AppleSectionHeader('Data & Privacy (Offline-First)'),
            AppleGroupedCard(
              children: [
                AppleListTile(
                  icon: BotanicalIcons.backup,
                  iconColor: const Color(0xFF34C759),
                  iconBackgroundColor: const Color(0xFF34C759).withOpacity(0.15),
                  title: const Text('Export JSON Backup', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                  subtitle: const Text('Save your entire notebook & schedule', style: TextStyle(fontSize: 13)),
                  onTap: () => _exportData(context),
                ),
                AppleListTile(
                  icon: BotanicalIcons.restart,
                  iconColor: const Color(0xFFFF9500),
                  iconBackgroundColor: const Color(0xFFFF9500).withOpacity(0.15),
                  title: const Text('Restore Sample Data', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                  onTap: () => _confirmReset(context, ref),
                ),
                const AppleListTile(
                  showDivider: false,
                  icon: BotanicalIcons.privacy,
                  iconColor: Color(0xFF8E8E93),
                  iconBackgroundColor: Color(0x208E8E93),
                  title: Text('Privacy Guaranteed', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                  subtitle: Text('100% offline SQLite storage. No remote tracking.', style: TextStyle(fontSize: 13)),
                  trailing: SizedBox.shrink(),
                ),
              ],
            ),

            // Section 5: App Updates & Release Logs
            const AppleSectionHeader('Updates & Release Logs'),
            AppleGroupedCard(
              children: [
                AppleListTile(
                  icon: CupertinoIcons.arrow_down_circle,
                  iconColor: const Color(0xFF007AFF),
                  iconBackgroundColor: const Color(0xFF007AFF).withOpacity(0.15),
                  title: const Text('Check for Updates', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                  subtitle: const Text('Search for new release package & logs', style: TextStyle(fontSize: 13)),
                  trailing: const Icon(CupertinoIcons.chevron_right, size: 14, color: CupertinoColors.systemGrey2),
                  onTap: () => _checkForUpdates(context),
                ),
                AppleListTile(
                  showDivider: false,
                  icon: CupertinoIcons.doc_plaintext,
                  iconColor: const Color(0xFF34C759),
                  iconBackgroundColor: const Color(0xFF34C759).withOpacity(0.15),
                  title: const Text('What\'s New & Changelogs', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                  subtitle: const Text('View recent feature additions & fixes', style: TextStyle(fontSize: 13)),
                  trailing: const Icon(CupertinoIcons.chevron_right, size: 14, color: CupertinoColors.systemGrey2),
                  onTap: () => _showChangelog(context),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Apple Minimal Footer
            Center(
              child: Column(
                children: [
                  Text(
                    'Botanical Planner',
                    style: TextStyle(
                      fontFamily: 'DM Serif Display',
                      fontSize: 16,
                      color: isDark ? BotanicalColors.darkTextSecondary : BotanicalColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Designed with Apple Craft & Care · Version 1.0.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? BotanicalColors.darkTextSecondary.withOpacity(0.7) : BotanicalColors.lightTextSecondary.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeSelectionSheet(BuildContext context, WidgetRef ref, ThemeMode current) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Appearance'),
        message: const Text('Choose your preferred color appearance'),
        actions: [
          CupertinoActionSheetAction(
            isDefaultAction: current == ThemeMode.light,
            onPressed: () {
              AppleHaptics.selection();
              ref.read(settingsProvider.notifier).toggleTheme(ThemeMode.light);
              Navigator.of(ctx).pop();
            },
            child: const Text('Light'),
          ),
          CupertinoActionSheetAction(
            isDefaultAction: current == ThemeMode.dark,
            onPressed: () {
              AppleHaptics.selection();
              ref.read(settingsProvider.notifier).toggleTheme(ThemeMode.dark);
              Navigator.of(ctx).pop();
            },
            child: const Text('Dark'),
          ),
          CupertinoActionSheetAction(
            isDefaultAction: current == ThemeMode.system,
            onPressed: () {
              AppleHaptics.selection();
              ref.read(settingsProvider.notifier).toggleTheme(ThemeMode.system);
              Navigator.of(ctx).pop();
            },
            child: const Text('System'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Widget _buildColorDot(BuildContext context, WidgetRef ref, String hex, String current) {
    final color = Color(int.parse('FF$hex', radix: 16));
    final isSelected = hex.toLowerCase() == current.toLowerCase();

    return GestureDetector(
      onTap: () {
        AppleHaptics.selection();
        ref.read(settingsProvider.notifier).setAccentColor(hex);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: isSelected ? 6 : 2,
            ),
          ],
        ),
      ),
    );
  }

  void _showEditNameDialog(BuildContext context, WidgetRef ref, String currentName) {
    final controller = TextEditingController(text: currentName);
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Display Name'),
        content: Padding(
          padding: const EdgeInsets.only(top: 14),
          child: CupertinoTextField(
            controller: controller,
            placeholder: 'Your Name',
            autofocus: true,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              AppleHaptics.lightImpact();
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                ref.read(settingsProvider.notifier).updateUserName(newName);
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _exportData(BuildContext context) async {
    AppleHaptics.lightImpact();
    final data = await DatabaseService.instance.exportAllData();

    if (context.mounted) {
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Backup Exported'),
          content: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text('${data.keys.length} tables exported to local JSON storage.'),
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _confirmReset(BuildContext context, WidgetRef ref) {
    AppleHaptics.mediumImpact();
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Restore Sample Data?'),
        content: const Text('This will restore all showcase botanical planner tasks, calendar events, and reflections.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              AppleHaptics.selection();
              await DatabaseService.instance.resetToDemoData();
              ref.invalidate(tasksProvider);
              ref.invalidate(remindersProvider);
              ref.invalidate(eventsProvider);
              ref.invalidate(notesProvider);
              ref.invalidate(journalProvider);
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  void _checkForUpdates(BuildContext context) async {
    AppleHaptics.lightImpact();

    // Show Cupertino loading indicator
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CupertinoActivityIndicator(radius: 16),
      ),
    );

    final release = await UpdateService.instance.checkForUpdate();

    if (context.mounted) {
      Navigator.of(context).pop(); // dismiss loading indicator

      if (release != null) {
        UpdateDialog.show(context, release);
      } else {
        // App is up to date
        final info = await UpdateService.instance.getPackageInfo();
        if (context.mounted) {
          showCupertinoDialog(
            context: context,
            builder: (ctx) => CupertinoAlertDialog(
              title: const Text('You\'re Up to Date'),
              content: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text('Botanical Planner v${info.version} (Build ${info.buildNumber}) is the latest available version.'),
              ),
              actions: [
                CupertinoDialogAction(
                  isDefaultAction: true,
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  void _showChangelog(BuildContext context) async {
    AppleHaptics.lightImpact();
    final info = await UpdateService.instance.getPackageInfo();

    final currentRelease = AppReleaseInfo(
      version: info.version.isNotEmpty ? info.version : '1.1.0',
      versionCode: int.tryParse(info.buildNumber) ?? 2,
      releaseTitle: 'Apple Liquid Glass & Tactile Haptics Edition',
      releaseDate: 'October 2026',
      changelog: [
        '🍎 Converted complete interface to Apple Human Interface Guidelines (HIG)',
        '🪟 Translucent Liquid Glass floating tab bar with dynamic backdrop blur',
        '📱 Apple Inset Grouped cards, custom switches, and squircle components',
        '⚡ Tactile haptic feedback across checkboxes, tabs, and buttons',
        '🔄 In-App OTA Update System: Updates install directly without data loss or uninstalling',
        '📅 Upgraded Apple Calendar with Month, Week, and Day segmented navigation',
        '🔍 iOS Scope Bar with instant search filtering for tasks, notes, and events',
      ],
      downloadUrl: '',
    );

    if (context.mounted) {
      UpdateDialog.show(context, currentRelease);
    }
  }
}
