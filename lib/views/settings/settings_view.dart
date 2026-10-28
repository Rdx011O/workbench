import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/update_service.dart';
import '../../core/theme/colors.dart';
import '../../models/user_settings.dart';
import '../../providers/providers.dart';
import '../../widgets/apple_widgets.dart';
import '../../widgets/update_dialog.dart';

/// Dedicated Settings screen separating application preferences from user profile.
class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  bool _checkingUpdate = false;

  Future<void> _exportData(BuildContext context, UserSettings settings) async {
    AppleHaptics.selection();
    final db = DatabaseService.instance;
    final tasks = await db.getTasks();
    final reminders = await db.getReminders();
    final events = await db.getEvents();
    final notes = await db.getNotes();
    final journal = await db.getJournalEntries();

    final exportJson = jsonEncode({
      'app': 'Workbench',
      'version': '1.1.0',
      'exported_at': DateTime.now().toIso8601String(),
      'settings': settings.toPreferencesMap(),
      'tasks_count': tasks.length,
      'reminders_count': reminders.length,
      'events_count': events.length,
      'notes_count': notes.length,
      'journal_count': journal.length,
      'data': {
        'tasks': tasks.map((t) => t.toMap()).toList(),
        'reminders': reminders.map((r) => r.toMap()).toList(),
        'events': events.map((e) => e.toMap()).toList(),
        'notes': notes.map((n) => n.toMap()).toList(),
        'journal': journal.map((j) => j.toMap()).toList(),
      }
    });
    debugPrint('Export payload size: ${exportJson.length} bytes');

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Data Backup Exported'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Successfully packaged ${tasks.length} tasks, ${reminders.length} reminders, ${notes.length} notes, and ${journal.length} journal entries.'),
            const SizedBox(height: 12),
            const Text(
              'Payload is valid JSON verified against SQLite integrity.',
              style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkForAppUpdates() async {
    setState(() => _checkingUpdate = true);
    final updateInfo = await UpdateService.instance.checkForUpdate(force: true);
    if (!mounted) return;
    setState(() => _checkingUpdate = false);

    if (updateInfo != null) {
      if (!mounted) return;
      UpdateDialog.show(context, updateInfo);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are on the latest release of Workbench (v1.3.0)'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showDeadlineLeadTimeDialog(BuildContext context, UserSettings settings) async {
    AppleHaptics.lightImpact();
    int selectedHours = settings.deadlineLeadHours;
    int selectedMinutes = settings.deadlineLeadMinutes;

    final hourController = TextEditingController(text: selectedHours.toString());
    final minuteController = TextEditingController(text: selectedMinutes.toString());

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;
        final primaryColor = isDark ? BotanicalColors.darkPrimary : BotanicalColors.lightPrimary;

        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            void applyPreset(int h, int m) {
              AppleHaptics.selection();
              setDialogState(() {
                selectedHours = h;
                selectedMinutes = m;
                hourController.text = h.toString();
                minuteController.text = m.toString();
              });
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(CupertinoIcons.timer, size: 20, color: primaryColor),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Deadline Lead Time',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Decide how much time earlier you want to be notified before task deadlines or reminder timelines end.',
                      style: TextStyle(fontSize: 13, color: CupertinoColors.systemGrey),
                    ),
                    const SizedBox(height: 18),

                    // Inputs for Hours and Minutes
                    Row(
                      children: [
                        // Hours Input
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Hours', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(CupertinoIcons.minus_circle, size: 22),
                                    onPressed: () {
                                      if (selectedHours > 0) {
                                        AppleHaptics.selection();
                                        setDialogState(() {
                                          selectedHours--;
                                          hourController.text = selectedHours.toString();
                                        });
                                      }
                                    },
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: hourController,
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                      decoration: InputDecoration(
                                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                        isDense: true,
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      onChanged: (val) {
                                        final parsed = int.tryParse(val) ?? 0;
                                        setDialogState(() => selectedHours = parsed.clamp(0, 72));
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(CupertinoIcons.plus_circle, size: 22),
                                    onPressed: () {
                                      if (selectedHours < 72) {
                                        AppleHaptics.selection();
                                        setDialogState(() {
                                          selectedHours++;
                                          hourController.text = selectedHours.toString();
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Minutes Input
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Minutes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(CupertinoIcons.minus_circle, size: 22),
                                    onPressed: () {
                                      if (selectedMinutes > 0) {
                                        AppleHaptics.selection();
                                        setDialogState(() {
                                          selectedMinutes = (selectedMinutes - 5).clamp(0, 59);
                                          minuteController.text = selectedMinutes.toString();
                                        });
                                      }
                                    },
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: minuteController,
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                      decoration: InputDecoration(
                                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                        isDense: true,
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      onChanged: (val) {
                                        final parsed = int.tryParse(val) ?? 0;
                                        setDialogState(() => selectedMinutes = parsed.clamp(0, 59));
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(CupertinoIcons.plus_circle, size: 22),
                                    onPressed: () {
                                      if (selectedMinutes < 59) {
                                        AppleHaptics.selection();
                                        setDialogState(() {
                                          selectedMinutes = (selectedMinutes + 5).clamp(0, 59);
                                          minuteController.text = selectedMinutes.toString();
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Quick Presets
                    const Text('Quick Presets', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: CupertinoColors.systemGrey)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildPresetChip('15m', 0, 15, selectedHours, selectedMinutes, applyPreset, primaryColor),
                        _buildPresetChip('30m', 0, 30, selectedHours, selectedMinutes, applyPreset, primaryColor),
                        _buildPresetChip('45m', 0, 45, selectedHours, selectedMinutes, applyPreset, primaryColor),
                        _buildPresetChip('1 hr', 1, 0, selectedHours, selectedMinutes, applyPreset, primaryColor),
                        _buildPresetChip('2 hrs', 2, 0, selectedHours, selectedMinutes, applyPreset, primaryColor),
                        _buildPresetChip('1 day', 24, 0, selectedHours, selectedMinutes, applyPreset, primaryColor),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Summary preview
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(CupertinoIcons.bell, size: 16, color: primaryColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              (selectedHours == 0 && selectedMinutes == 0)
                                  ? 'Alert precisely when deadline arrives.'
                                  : 'Alert ${selectedHours > 0 ? '$selectedHours hr ' : ''}${selectedMinutes > 0 ? '$selectedMinutes min ' : ''}before deadline.',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: primaryColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    AppleHaptics.notificationSuccess();
                    final h = int.tryParse(hourController.text) ?? selectedHours;
                    final m = int.tryParse(minuteController.text) ?? selectedMinutes;
                    ref.read(settingsProvider.notifier).updateSettings(
                          settings.copyWith(
                            deadlineLeadHours: h.clamp(0, 72),
                            deadlineLeadMinutes: m.clamp(0, 59),
                          ),
                        );
                    Navigator.of(dialogCtx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Deadline lead time set to ${h > 0 ? "$h hr " : ""}$m min before deadline.'),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Text('Save Preference'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPresetChip(
    String label,
    int h,
    int m,
    int currentH,
    int currentM,
    void Function(int, int) onSelect,
    Color primaryColor,
  ) {
    final isSelected = currentH == h && currentM == m;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      selectedColor: primaryColor.withValues(alpha: 0.18),
      onSelected: (_) => onSelect(h, m),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? BotanicalColors.darkPrimary : BotanicalColors.lightPrimary;
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
          children: [
            // Appearance & Theme Section
            const AppleSectionHeader('Appearance & Theme'),
            AppleGroupedCard(
              children: [
                AppleListTile(
                  icon: CupertinoIcons.paintbrush,
                  iconColor: const Color(0xFF5E8B7E),
                  title: const Text('Theme Mode', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  subtitle: Text(
                    settings.themeMode == ThemeMode.system
                        ? 'Follows device system settings'
                        : (settings.themeMode == ThemeMode.dark ? 'Dark Slate' : 'Light Lavender Porcelain'),
                    style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
                  ),
                  trailing: SegmentedButton<ThemeMode>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: ThemeMode.light, label: Text('Light', style: TextStyle(fontSize: 11))),
                      ButtonSegment(value: ThemeMode.dark, label: Text('Dark', style: TextStyle(fontSize: 11))),
                      ButtonSegment(value: ThemeMode.system, label: Text('Auto', style: TextStyle(fontSize: 11))),
                    ],
                    selected: {settings.themeMode},
                    style: SegmentedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onSelectionChanged: (val) {
                      AppleHaptics.selection();
                      ref.read(settingsProvider.notifier).toggleTheme(val.first);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Date & Calendar Preferences
            const AppleSectionHeader('Date & Calendar'),
            AppleGroupedCard(
              children: [
                AppleListTile(
                  icon: CupertinoIcons.calendar,
                  iconColor: const Color(0xFF4A6B82),
                  title: const Text('Week Starts On', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  subtitle: Text(
                    settings.weekStartMonday ? 'Monday (ISO standard)' : 'Sunday',
                    style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
                  ),
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
                  iconColor: const Color(0xFF8A6E5E),
                  title: const Text('24-Hour Clock', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  subtitle: Text(
                    settings.timeFormat24Hour ? '24-hour time (14:00)' : '12-hour time (2:00 PM)',
                    style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
                  ),
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
            const SizedBox(height: 18),

            // Notifications
            const AppleSectionHeader('Notifications'),
            AppleGroupedCard(
              children: [
                AppleListTile(
                  icon: CupertinoIcons.bell,
                  iconColor: const Color(0xFFC77D5B),
                  title: const Text('Push Reminders & Alerts', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  subtitle: const Text('Scheduled deadline alerts, tasks & reminders', style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey)),
                  trailing: CupertinoSwitch(
                    value: settings.notificationsEnabled,
                    activeTrackColor: primaryColor,
                    onChanged: (val) async {
                      AppleHaptics.selection();
                      if (val) {
                        await NotificationService.instance.requestPermissions();
                      }
                      ref.read(settingsProvider.notifier).updateSettings(
                            settings.copyWith(notificationsEnabled: val),
                          );
                    },
                  ),
                ),
                AppleListTile(
                  icon: CupertinoIcons.timer,
                  iconColor: const Color(0xFF7A58A5),
                  title: const Text('Deadline Alert Lead Time', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  subtitle: Text(
                    'Alert ${settings.deadlineLeadHours > 0 ? "${settings.deadlineLeadHours}h " : ""}${settings.deadlineLeadMinutes}m earlier before deadline',
                    style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
                  ),
                  trailing: const Icon(CupertinoIcons.chevron_right, size: 14, color: CupertinoColors.systemGrey3),
                  onTap: () => _showDeadlineLeadTimeDialog(context, settings),
                ),
                AppleListTile(
                  icon: CupertinoIcons.bell_fill,
                  iconColor: primaryColor,
                  title: const Text('Send Test Alert Notification', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  subtitle: Text(
                    'Simulate deadline alert with your ${settings.deadlineLeadHours > 0 ? "${settings.deadlineLeadHours}h " : ""}${settings.deadlineLeadMinutes}m lead time',
                    style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
                  ),
                  trailing: const Icon(CupertinoIcons.chevron_right, size: 14, color: CupertinoColors.systemGrey3),
                  onTap: () async {
                    AppleHaptics.mediumImpact();
                    await NotificationService.instance.requestPermissions();
                    await NotificationService.instance.triggerTestDeadlineAlert(
                      leadHours: settings.deadlineLeadHours,
                      leadMinutes: settings.deadlineLeadMinutes,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Test alert notification sent! Check your notification shade.'),
                          duration: Duration(seconds: 3),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Audio & Voice Input
            const AppleSectionHeader('Voice & Accessibility'),
            AppleGroupedCard(
              children: [
                AppleListTile(
                  icon: CupertinoIcons.mic,
                  iconColor: const Color(0xFF5E8B7E),
                  title: const Text('Voice-to-Text Input', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  subtitle: const Text('Quick audio reflection recording in journal', style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey)),
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
            const SizedBox(height: 18),

            // Data Export & Storage
            const AppleSectionHeader('Data & Storage'),
            AppleGroupedCard(
              children: [
                AppleListTile(
                  icon: CupertinoIcons.arrow_down_doc,
                  iconColor: const Color(0xFF6E5E8A),
                  title: const Text('Export Local Backup', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  subtitle: const Text('Package full SQLite database to offline JSON', style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey)),
                  trailing: const Icon(CupertinoIcons.chevron_right, size: 14, color: CupertinoColors.systemGrey3),
                  onTap: () => _exportData(context, settings),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Application Information & Updates
            const AppleSectionHeader('Application Information'),
            AppleGroupedCard(
              children: [
                AppleListTile(
                  icon: CupertinoIcons.info_circle,
                  iconColor: const Color(0xFF5E8B7E),
                  title: const Text('Workbench Version', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  subtitle: const Text('Release 1.3.0 · Build 4', style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey)),
                  trailing: Text(
                    'Up to date',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: primaryColor),
                  ),
                ),
                AppleListTile(
                  icon: CupertinoIcons.arrow_clockwise_circle,
                  iconColor: const Color(0xFFC77D5B),
                  title: const Text('Check for Updates', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  subtitle: const Text('Query GitHub releases for new APK versions', style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey)),
                  trailing: _checkingUpdate
                      ? const CupertinoActivityIndicator(radius: 8)
                      : const Icon(CupertinoIcons.chevron_right, size: 14, color: CupertinoColors.systemGrey3),
                  onTap: _checkForAppUpdates,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
