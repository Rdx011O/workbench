import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/colors.dart';
import '../../models/reminder.dart';
import '../../providers/providers.dart';
import '../../widgets/apple_widgets.dart';
import '../../widgets/reminder_editor_sheet.dart';

class RemindersView extends ConsumerWidget {
  const RemindersView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? BotanicalColors.darkPrimary : BotanicalColors.lightPrimary;

    final reminders = ref.watch(remindersProvider);

    final todayReminders = reminders.where((r) => r.isDueToday && !r.isCompleted).toList();
    final upcomingReminders = reminders.where((r) => !r.isDueToday && r.isUpcoming).toList();
    final completedReminders = reminders.where((r) => r.isCompleted).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.plus_circle_fill, size: 24),
            tooltip: 'New Reminder',
            onPressed: () async {
              AppleHaptics.lightImpact();
              final reminder = await ReminderEditorSheet.show(context);
              if (reminder != null) {
                ref.read(remindersProvider.notifier).addReminder(reminder);
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 60),
          children: [
            // Today's Reminders
            if (todayReminders.isNotEmpty) ...[
              AppleSectionHeader('Today (${todayReminders.length})'),
              AppleGroupedCard(
                children: todayReminders.map((r) => _buildReminderTile(context, ref, r, isDark, primaryColor)).toList(),
              ),
            ],

            // Upcoming Reminders
            if (upcomingReminders.isNotEmpty) ...[
              AppleSectionHeader('Upcoming (${upcomingReminders.length})'),
              AppleGroupedCard(
                children: upcomingReminders.map((r) => _buildReminderTile(context, ref, r, isDark, primaryColor)).toList(),
              ),
            ],

            // Completed Reminders
            if (completedReminders.isNotEmpty) ...[
              AppleSectionHeader('Completed (${completedReminders.length})'),
              AppleGroupedCard(
                children: completedReminders.map((r) => _buildReminderTile(context, ref, r, isDark, primaryColor)).toList(),
              ),
            ],

            if (reminders.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 80),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(CupertinoIcons.bell, size: 42, color: CupertinoColors.systemGrey3),
                      const SizedBox(height: 12),
                      Text(
                        'No Reminders',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(color: CupertinoColors.systemGrey),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Tap + to schedule your first reminder or habit.',
                        style: TextStyle(fontSize: 13, color: CupertinoColors.systemGrey2),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderTile(
    BuildContext context,
    WidgetRef ref,
    Reminder reminder,
    bool isDark,
    Color primaryColor,
  ) {
    return AppleListTile(
      leading: CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: const Size(44, 44),
        onPressed: () {
          AppleHaptics.mediumImpact();
          ref.read(remindersProvider.notifier).toggleReminderCompletion(reminder.id);
        },
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: reminder.isCompleted ? primaryColor : Colors.transparent,
            border: Border.all(
              color: reminder.isCompleted ? primaryColor : CupertinoColors.systemGrey3,
              width: 1.5,
            ),
          ),
          child: reminder.isCompleted
              ? const Icon(CupertinoIcons.checkmark, size: 13, color: Colors.white)
              : null,
        ),
      ),
      title: Text(
        reminder.title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          decoration: reminder.isCompleted ? TextDecoration.lineThrough : null,
          color: reminder.isCompleted ? CupertinoColors.systemGrey : null,
        ),
      ),
      subtitle: Row(
        children: [
          Icon(CupertinoIcons.clock, size: 12, color: isDark ? BotanicalColors.darkTextSecondary : BotanicalColors.lightTextSecondary),
          const SizedBox(width: 4),
          Text(
            DateFormat('d MMM, h:mm a').format(reminder.effectiveDueTime),
            style: const TextStyle(fontSize: 12),
          ),
          if (reminder.snoozedUntil != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: BotanicalColors.lightAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Snoozed',
                style: TextStyle(fontSize: 10, color: BotanicalColors.lightAccent, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!reminder.isCompleted)
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(32, 32),
              onPressed: () {
                AppleHaptics.selection();
                ref.read(remindersProvider.notifier).snoozeReminder(reminder.id, const Duration(minutes: 15));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Snoozed 15 minutes'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Icon(CupertinoIcons.alarm, size: 18, color: BotanicalColors.lightAccent),
            ),
          IconButton(
            icon: const Icon(CupertinoIcons.pencil, size: 16),
            onPressed: () async {
              AppleHaptics.selection();
              final updated = await ReminderEditorSheet.show(context, reminder: reminder);
              if (updated != null) {
                ref.read(remindersProvider.notifier).updateReminder(updated);
              }
            },
          ),
        ],
      ),
    );
  }
}
