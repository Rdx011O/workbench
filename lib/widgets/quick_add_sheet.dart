import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/colors.dart';
import '../providers/providers.dart';
import 'apple_widgets.dart';
import 'botanical_icons.dart';
import 'event_editor_sheet.dart';
import 'note_editor_sheet.dart';
import 'reminder_editor_sheet.dart';
import 'task_editor_sheet.dart';

enum QuickAddType {
  task,
  reminder,
  event,
  note,
  reflection,
}

class QuickAddSheet extends ConsumerWidget {
  final DateTime? prefilledDate;

  const QuickAddSheet({super.key, this.prefilledDate});

  static Future<void> show(BuildContext context, {DateTime? prefilledDate}) {
    AppleHaptics.lightImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QuickAddSheet(prefilledDate: prefilledDate),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? BotanicalColors.darkSurface : BotanicalColors.lightSurface;
    final primaryColor = isDark ? BotanicalColors.darkPrimary : BotanicalColors.lightPrimary;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Apple Grabber Handle
            Center(
              child: Container(
                width: 36,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF3A443E) : const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 36),
                Text(
                  'Quick Create',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontFamily: 'DM Serif Display',
                        fontSize: 20,
                      ),
                  textAlign: TextAlign.center,
                ),
                IconButton(
                  icon: const Icon(CupertinoIcons.xmark_circle_fill, size: 24, color: CupertinoColors.systemGrey3),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Inset Grouped Quick Actions
            AppleGroupedCard(
              children: [
                AppleListTile(
                  icon: BotanicalIcons.tasks,
                  iconColor: primaryColor,
                  iconBackgroundColor: primaryColor.withValues(alpha: 0.12),
                  title: const Text('New Task', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  subtitle: const Text('Add to daily to-do or schedule for later', style: TextStyle(fontSize: 13)),
                  onTap: () async {
                    Navigator.of(context).pop();
                    final task = await TaskEditorSheet.show(context, prefilledDate: prefilledDate);
                    if (task != null) {
                      ref.read(tasksProvider.notifier).addTask(task);
                    }
                  },
                ),
                AppleListTile(
                  icon: BotanicalIcons.reminder,
                  iconColor: BotanicalColors.lightAccent,
                  iconBackgroundColor: BotanicalColors.lightAccent.withValues(alpha: 0.12),
                  title: const Text('New Reminder', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  subtitle: const Text('Set a timed prompt or gentle recurring habit', style: TextStyle(fontSize: 13)),
                  onTap: () async {
                    Navigator.of(context).pop();
                    final reminder = await ReminderEditorSheet.show(context, prefilledDate: prefilledDate);
                    if (reminder != null) {
                      ref.read(remindersProvider.notifier).addReminder(reminder);
                    }
                  },
                ),
                AppleListTile(
                  icon: BotanicalIcons.calendar,
                  iconColor: const Color(0xFF328A6E),
                  iconBackgroundColor: const Color(0xFF328A6E).withValues(alpha: 0.12),
                  title: const Text('New Calendar Event', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  subtitle: const Text('Schedule meeting, appointment, or focus block', style: TextStyle(fontSize: 13)),
                  onTap: () async {
                    Navigator.of(context).pop();
                    final event = await EventEditorSheet.show(context, prefilledDate: prefilledDate);
                    if (event != null) {
                      ref.read(eventsProvider.notifier).addEvent(event);
                    }
                  },
                ),
                AppleListTile(
                  showDivider: false,
                  icon: BotanicalIcons.notes,
                  iconColor: const Color(0xFF8A6C48),
                  iconBackgroundColor: const Color(0xFF8A6C48).withValues(alpha: 0.12),
                  title: const Text('New Note', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  subtitle: const Text('Capture ideas, checklist, or long-form thought', style: TextStyle(fontSize: 13)),
                  onTap: () async {
                    Navigator.of(context).pop();
                    final note = await NoteEditorSheet.show(context);
                    if (note != null) {
                      ref.read(notesProvider.notifier).addNote(note);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
