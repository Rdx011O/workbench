import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database_service.dart';
import '../../core/services/update_service.dart';
import '../../core/theme/colors.dart';
import '../../providers/providers.dart';
import '../../widgets/apple_widgets.dart';
import '../../widgets/botanical_icons.dart';
import '../../widgets/update_dialog.dart';
import '../../widgets/workspace_sheet.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? BotanicalColors.darkPrimary : BotanicalColors.lightPrimary;
    final settings = ref.watch(settingsProvider);
    final activeWorkspace = ref.watch(activeWorkspaceProvider);
    final workspaces = ref.watch(workspacesProvider);
    final activity = ref.watch(activitySummaryProvider);
    final notes = ref.watch(notesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
          children: [
            // User Profile Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? BotanicalColors.darkSurface : BotanicalColors.lightSurface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? BotanicalColors.darkBorder : BotanicalColors.lightBorder,
                  width: 0.75,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Avatar matching screenshot
                      Stack(
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Color(0xFFFFD180), Color(0xFFFFAB40), Color(0xFFFF8A80)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Center(
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3F51B5),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(
                                  CupertinoIcons.person_fill,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: isDark ? BotanicalColors.darkPrimary : BotanicalColors.lightPrimary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark ? BotanicalColors.darkSurface : Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(CupertinoIcons.checkmark, size: 10, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              settings.userName,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 22,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${settings.userName.toLowerCase().replaceAll(' ', '')}@botanical.space',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? BotanicalColors.darkTextSecondary : BotanicalColors.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? BotanicalColors.darkSecondarySurface
                                    : BotanicalColors.summaryCardLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(CupertinoIcons.tray_fill, size: 13, color: primaryColor),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Active: $activeWorkspace',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(CupertinoIcons.pencil_circle_fill, size: 28),
                        tooltip: 'Edit Name',
                        color: primaryColor,
                        onPressed: () => _showEditNameDialog(context, ref, settings.userName),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Workspaces Section (Explicit user requirement: "in profile we also can see the workspace")
            AppleSectionHeader('Workspaces ($activeWorkspace)'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? BotanicalColors.darkSurface : BotanicalColors.lightSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? BotanicalColors.darkBorder : BotanicalColors.lightBorder,
                  width: 0.75,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Your Workspaces',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      TextButton.icon(
                        icon: const Icon(CupertinoIcons.plus, size: 15),
                        label: const Text('New Space', style: TextStyle(fontSize: 13)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => WorkspaceSheet.show(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: workspaces.map((ws) {
                      final isSelected = ws == activeWorkspace;
                      return ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              ws == 'Queue' ? CupertinoIcons.tray_fill : CupertinoIcons.folder_fill,
                              size: 14,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? BotanicalColors.darkTextSecondary : BotanicalColors.lightTextSecondary),
                            ),
                            const SizedBox(width: 6),
                            Text(ws),
                          ],
                        ),
                        selected: isSelected,
                        selectedColor: isDark ? BotanicalColors.darkPrimary : BotanicalColors.lightPrimary,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : null,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 13,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            AppleHaptics.selection();
                            ref.read(settingsProvider.notifier).setActiveWorkspace(ws);
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Productivity Metrics Overview
            const AppleSectionHeader('Productivity & Rhythm'),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Current Streak',
                    value: '${activity.currentStreakDays} days',
                    icon: CupertinoIcons.flame_fill,
                    iconColor: const Color(0xFFFF9500),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Done Today',
                    value: '${activity.completedTasksToday}',
                    icon: CupertinoIcons.checkmark_seal_fill,
                    iconColor: const Color(0xFF34C759),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Notes & Log',
                    value: '${notes.length}',
                    icon: CupertinoIcons.book_fill,
                    iconColor: const Color(0xFF5856D6),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Appearance & Themes
            const AppleSectionHeader('Appearance & Styling'),
            AppleGroupedCard(
              children: [
                AppleListTile(
                  icon: BotanicalIcons.lightMode,
                  iconColor: const Color(0xFFFF9500),
                  iconBackgroundColor: const Color(0xFFFF9500).withValues(alpha: 0.15),
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
                  onTap: () => _showThemeModeDialog(context, ref, settings.themeMode),
                ),
                AppleListTile(
                  icon: CupertinoIcons.color_filter,
                  iconColor: const Color(0xFF5856D6),
                  iconBackgroundColor: const Color(0xFF5856D6).withValues(alpha: 0.15),
                  title: const Text('Accent Color', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                  trailing: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Color(int.parse('0xFF${settings.accentColorHex}')),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  onTap: () => _showAccentColorDialog(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Calendar & Timing Preferences
            const AppleSectionHeader('Preferences & Timing'),
            AppleGroupedCard(
              children: [
                AppleListTile(
                  icon: BotanicalIcons.reminder,
                  iconColor: const Color(0xFFFF2D55),
                  iconBackgroundColor: const Color(0xFFFF2D55).withValues(alpha: 0.15),
                  title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                  trailing: CupertinoSwitch(
                    value: settings.notificationsEnabled,
                    activeTrackColor: primaryColor,
                    onChanged: (val) {
                      AppleHaptics.selection();
                      ref.read(settingsProvider.notifier).updateSettings(
                            settings.copyWith(notificationsEnabled: val),
                          );
                    },
                  ),
                ),
                AppleListTile(
                  icon: BotanicalIcons.calendar,
                  iconColor: const Color(0xFF328A6E),
                  iconBackgroundColor: const Color(0xFF328A6E).withValues(alpha: 0.15),
                  title: const Text('Week Starts on Monday', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
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
                  icon: CupertinoIcons.clock,
                  iconColor: const Color(0xFF007AFF),
                  iconBackgroundColor: const Color(0xFF007AFF).withValues(alpha: 0.15),
                  title: const Text('24-Hour Time Format', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
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
                AppleListTile(
                  icon: CupertinoIcons.mic,
                  iconColor: const Color(0xFFAF52DE),
                  iconBackgroundColor: const Color(0xFFAF52DE).withValues(alpha: 0.15),
                  title: const Text('Voice Journaling', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
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
            const SizedBox(height: 20),

            // Data & System Actions
            const AppleSectionHeader('Data & Storage'),
            AppleGroupedCard(
              children: [
                AppleListTile(
                  icon: CupertinoIcons.arrow_down_doc,
                  iconColor: const Color(0xFF34C759),
                  iconBackgroundColor: const Color(0xFF34C759).withValues(alpha: 0.15),
                  title: const Text('Export JSON Backup', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                  trailing: const Icon(CupertinoIcons.chevron_right, size: 14, color: CupertinoColors.systemGrey2),
                  onTap: () => _exportData(context),
                ),
                AppleListTile(
                  icon: CupertinoIcons.arrow_counterclockwise,
                  iconColor: const Color(0xFFFF9500),
                  iconBackgroundColor: const Color(0xFFFF9500).withValues(alpha: 0.15),
                  title: const Text('Reset to Initial Demo Data', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                  trailing: const Icon(CupertinoIcons.chevron_right, size: 14, color: CupertinoColors.systemGrey2),
                  onTap: () => _confirmReset(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // App Updates & Version
            const AppleSectionHeader('About & Updates'),
            AppleGroupedCard(
              children: [
                AppleListTile(
                  icon: CupertinoIcons.sparkles,
                  iconColor: primaryColor,
                  iconBackgroundColor: primaryColor.withValues(alpha: 0.15),
                  title: const Text('Check for Updates', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                  trailing: const Icon(CupertinoIcons.chevron_right, size: 14, color: CupertinoColors.systemGrey2),
                  onTap: () => _checkForAppUpdate(context),
                ),
                const AppleListTile(
                  showDivider: false,
                  icon: CupertinoIcons.info,
                  iconColor: CupertinoColors.systemGrey,
                  title: Text('App Version', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                  trailing: Text('1.0.0 (Fresh UI)', style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 15)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? BotanicalColors.darkSurface : BotanicalColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? BotanicalColors.darkBorder : BotanicalColors.lightBorder,
          width: 0.75,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? BotanicalColors.darkTextSecondary : BotanicalColors.lightTextSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditNameDialog(BuildContext context, WidgetRef ref, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Name', style: TextStyle(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Your Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = controller.text.trim();
              if (val.isNotEmpty) {
                ref.read(settingsProvider.notifier).updateUserName(val);
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showThemeModeDialog(BuildContext context, WidgetRef ref, ThemeMode current) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Appearance Mode'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              ref.read(settingsProvider.notifier).toggleTheme(ThemeMode.light);
              Navigator.of(ctx).pop();
            },
            child: const Text('Light'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              ref.read(settingsProvider.notifier).toggleTheme(ThemeMode.dark);
              Navigator.of(ctx).pop();
            },
            child: const Text('Dark'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              ref.read(settingsProvider.notifier).toggleTheme(ThemeMode.system);
              Navigator.of(ctx).pop();
            },
            child: const Text('System Default'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showAccentColorDialog(BuildContext context, WidgetRef ref) {
    final colors = [
      {'hex': '2C2638', 'name': 'Slate Aubergine'},
      {'hex': '1E6B47', 'name': 'Botanical Emerald'},
      {'hex': 'C46B3B', 'name': 'Terracotta'},
      {'hex': '5856D6', 'name': 'Iris Violet'},
      {'hex': '007AFF', 'name': 'Apple Azure'},
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Accent Color', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              ...colors.map((c) => ListTile(
                    leading: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Color(int.parse('0xFF${c['hex']}')),
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(c['name']!, style: const TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () {
                      ref.read(settingsProvider.notifier).setAccentColor(c['hex']!);
                      Navigator.of(ctx).pop();
                    },
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    final data = await DatabaseService.instance.exportAllData();
    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Backup Exported', style: TextStyle(fontWeight: FontWeight.w700)),
          content: SizedBox(
            width: double.maxFinite,
            height: 250,
            child: SingleChildScrollView(
              child: SelectableText(jsonStr, style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    }
  }

  void _confirmReset(BuildContext context, WidgetRef ref) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Reset to Initial Data?'),
        content: const Text('This will reload the initial demo tasks, reminders, and events.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.of(ctx).pop();
              await DatabaseService.instance.resetToDemoData();
              ref.read(tasksProvider.notifier).loadTasks();
              ref.read(remindersProvider.notifier).loadReminders();
              ref.read(eventsProvider.notifier).loadEvents();
              ref.read(notesProvider.notifier).loadNotes();
              ref.read(journalProvider.notifier).loadEntries();
              ref.read(settingsProvider.notifier).loadSettings();
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkForAppUpdate(BuildContext context) async {
    final release = await UpdateService.instance.checkForUpdate();
    if (context.mounted) {
      if (release != null) {
        UpdateDialog.show(context, release);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You are on the latest version!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
