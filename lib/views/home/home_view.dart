import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../models/reminder.dart';
import '../../models/task.dart';
import '../../providers/providers.dart';
import '../../widgets/apple_widgets.dart';
import '../../widgets/circular_checkbox.dart';
import '../../widgets/reminder_editor_sheet.dart';
import '../../widgets/task_editor_sheet.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/workspace_sheet.dart';
import '../profile/profile_view.dart';
import '../search/search_view.dart';
import '../tasks_reminders/tasks_reminders_view.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _formatTimeLeft(DateTime target) {
    final now = DateTime.now();
    final diff = target.difference(now);
    if (diff.isNegative) {
      return 'Past due';
    }
    if (diff.inHours > 0) {
      final hours = diff.inHours;
      final mins = diff.inMinutes % 60;
      final secs = diff.inSeconds % 60;
      return '$hours Hrs $mins Mins $secs sec';
    } else if (diff.inMinutes > 0) {
      final mins = diff.inMinutes;
      final secs = diff.inSeconds % 60;
      return '$mins Mins $secs sec';
    } else {
      return '${diff.inSeconds} sec';
    }
  }

  void _showTaskContextActions(BuildContext context, Task task) {
    AppleHaptics.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? BotanicalColors.darkSurface : BotanicalColors.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: isDark ? BotanicalColors.darkBorder : BotanicalColors.lightBorder,
            width: 0.8,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? BotanicalColors.darkBorder : BotanicalColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                task.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            const Divider(height: 16),
            ListTile(
              dense: true,
              leading: Icon(
                task.isCompleted ? CupertinoIcons.arrow_counterclockwise : CupertinoIcons.checkmark_circle_fill,
                color: isDark ? BotanicalColors.darkPrimary : BotanicalColors.lightPrimary,
              ),
              title: Text(
                task.isCompleted ? 'Mark as incomplete' : 'Mark as completed',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                ref.read(tasksProvider.notifier).toggleTaskCompletion(task.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(task.isCompleted ? 'Marked as incomplete' : 'Task completed'),
                    behavior: SnackBarBehavior.floating,
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () => ref.read(tasksProvider.notifier).undoLastCompletion(),
                    ),
                  ),
                );
              },
            ),
            ListTile(
              dense: true,
              leading: const Icon(CupertinoIcons.pencil, size: 20),
              title: const Text('Edit task details', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              onTap: () async {
                Navigator.of(ctx).pop();
                final updated = await TaskEditorSheet.show(context, task: task);
                if (updated != null) {
                  ref.read(tasksProvider.notifier).updateTask(updated);
                }
              },
            ),
            ListTile(
              dense: true,
              leading: const Icon(CupertinoIcons.trash, color: BotanicalColors.lightError, size: 20),
              title: const Text(
                'Delete task',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: BotanicalColors.lightError),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                ref.read(tasksProvider.notifier).deleteTask(task.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Task deleted'),
                    behavior: SnackBarBehavior.floating,
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () => ref.read(tasksProvider.notifier).undoLastCompletion(),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showReminderContextActions(BuildContext context, Reminder reminder) {
    AppleHaptics.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? BotanicalColors.darkSurface : BotanicalColors.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: isDark ? BotanicalColors.darkBorder : BotanicalColors.lightBorder,
            width: 0.8,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? BotanicalColors.darkBorder : BotanicalColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                reminder.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            const Divider(height: 16),
            ListTile(
              dense: true,
              leading: Icon(
                reminder.isCompleted ? CupertinoIcons.arrow_counterclockwise : CupertinoIcons.checkmark_circle_fill,
                color: isDark ? BotanicalColors.darkPrimary : BotanicalColors.lightPrimary,
              ),
              title: Text(
                reminder.isCompleted ? 'Mark as incomplete' : 'Mark as done',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                ref.read(remindersProvider.notifier).toggleReminderCompletion(reminder.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(reminder.isCompleted ? 'Reminder reopened' : 'Reminder completed'),
                    behavior: SnackBarBehavior.floating,
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () => ref.read(remindersProvider.notifier).undoLastCompletion(),
                    ),
                  ),
                );
              },
            ),
            ListTile(
              dense: true,
              leading: const Icon(CupertinoIcons.pencil, size: 20),
              title: const Text('Edit reminder', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              onTap: () async {
                Navigator.of(ctx).pop();
                final updated = await ReminderEditorSheet.show(context, reminder: reminder);
                if (updated != null) {
                  ref.read(remindersProvider.notifier).updateReminder(updated);
                }
              },
            ),
            ListTile(
              dense: true,
              leading: const Icon(CupertinoIcons.clock, size: 20),
              title: const Text('Snooze 1 hour', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              onTap: () {
                Navigator.of(ctx).pop();
                ref.read(remindersProvider.notifier).snoozeReminder(reminder.id, const Duration(hours: 1));
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? BotanicalColors.darkPrimary : BotanicalColors.lightPrimary;
    final settings = ref.watch(settingsProvider);
    final tasks = ref.watch(tasksProvider);
    final reminders = ref.watch(remindersProvider);

    final now = DateTime.now();
    final todayTasks = tasks.where((t) => t.isDueToday || !t.isCompleted).take(4).toList();
    final pendingTasksToday = tasks.where((t) => !t.isCompleted).length;
    final pendingRemindersCount = reminders.where((r) => !r.isCompleted).length;

    // Filter reminders for alerts: not completed
    final alertReminders = reminders.where((r) => !r.isCompleted).toList();
    alertReminders.sort((a, b) => a.effectiveDueTime.compareTo(b.effectiveDueTime));

    return Scaffold(
      backgroundColor: isDark ? BotanicalColors.darkBackground : BotanicalColors.lightBackground,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
          children: [
            // Top Bar: [Queue ⇕  Mon 6 Oct] [search pill] [Profile Avatar] (Screenshot 1)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left Side: "Queue" in bold + chevrons icon, and Weekday/Date below
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      AppleHaptics.lightImpact();
                      WorkspaceSheet.show(context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Queue',
                                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                      fontSize: 34,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -1.0,
                                      color: isDark ? BotanicalColors.darkTextPrimary : BotanicalColors.lightTextPrimary,
                                    ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                CupertinoIcons.chevron_up_chevron_down,
                                size: 18,
                                color: isDark ? BotanicalColors.darkPrimary : BotanicalColors.lightPrimary,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('E d MMM').format(now),
                            style: BotanicalTypography.dateStyle(
                              isDark: isDark,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Search Capsule Button (Pill matching Screenshot 1)
                InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () {
                    AppleHaptics.lightImpact();
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchView()));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      color: isDark ? BotanicalColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark ? BotanicalColors.darkBorder : BotanicalColors.lightBorder,
                        width: 0.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.search,
                          size: 16,
                          color: isDark ? BotanicalColors.darkPrimary : BotanicalColors.lightPrimary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'search',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? BotanicalColors.darkPrimary : BotanicalColors.lightPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Profile Avatar Button (Part F / Screenshot 1)
                UserAvatar(
                  name: settings.userName,
                  size: 42,
                  onTap: () {
                    AppleHaptics.lightImpact();
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileView()));
                  },
                ),
              ],
            ),
            const SizedBox(height: 22),

            // Summary Card (Exact Layout from Screenshot 2)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
              decoration: BoxDecoration(
                color: isDark ? BotanicalColors.summaryCardDark : BotanicalColors.summaryCardLight,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✨ Summary Pill Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? BotanicalColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.sparkles,
                          size: 15,
                          color: isDark ? BotanicalColors.darkAccent : const Color(0xFF5A4D78),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Summary',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? BotanicalColors.darkTextPrimary : const Color(0xFF2C243C),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Natural-Language Summary matching Screenshot 2
                  if (pendingTasksToday == 0 && pendingRemindersCount == 0)
                    Text(
                      'All caught up! No pending tasks or reminders for today. Clear sailing!',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: isDark ? BotanicalColors.darkTextPrimary : const Color(0xFF2C243C),
                        height: 1.4,
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Line 1: "you had   [ 4 tasks ]   along with"
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'you had  ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: isDark ? BotanicalColors.darkTextPrimary : const Color(0xFF2C243C),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                              decoration: BoxDecoration(
                                color: isDark ? BotanicalColors.taskBadgeDark : BotanicalColors.taskBadgeLight,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '$pendingTasksToday ${pendingTasksToday == 1 ? 'task' : 'tasks'}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : BotanicalColors.taskBadgeText,
                                ),
                              ),
                            ),
                            Text(
                              '   along with',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: isDark ? BotanicalColors.darkTextPrimary : const Color(0xFF2C243C),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Line 2: " [ 1 reminder ]"
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: isDark ? BotanicalColors.reminderBadgeDark : BotanicalColors.reminderBadgeLight,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '$pendingRemindersCount ${pendingRemindersCount == 1 ? 'reminder' : 'reminders'}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : BotanicalColors.reminderBadgeText,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Alerts Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Alerts',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? BotanicalColors.darkTextPrimary : BotanicalColors.lightTextPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(CupertinoIcons.plus_circle_fill, size: 24),
                  color: primaryColor,
                  tooltip: 'Add Reminder',
                  onPressed: () async {
                    AppleHaptics.lightImpact();
                    final reminder = await ReminderEditorSheet.show(context);
                    if (reminder != null) {
                      ref.read(remindersProvider.notifier).addReminder(reminder);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Alert Cards
            if (alertReminders.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? BotanicalColors.darkSurface : BotanicalColors.lightSurface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark ? BotanicalColors.darkBorder : BotanicalColors.lightBorder,
                    width: 0.75,
                  ),
                ),
                child: const Center(
                  child: Text(
                    'No urgent deadlines active today. Clear sailing!',
                    style: TextStyle(fontSize: 13, color: CupertinoColors.systemGrey),
                  ),
                ),
              )
            else ...[
              ...alertReminders.take(2).map((reminder) {
                return _buildAlertCard(context, reminder, isDark);
              }),
              const SizedBox(height: 6),
              Center(
                child: TextButton.icon(
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(CupertinoIcons.arrow_right, size: 16),
                  label: const Text(
                    'See all reminders',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  onPressed: () {
                    AppleHaptics.lightImpact();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const TasksAndRemindersView(initialTab: 1),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 22),

            // Today's Focus Checklist
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Today’s Focus',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? BotanicalColors.darkTextPrimary : BotanicalColors.lightTextPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(CupertinoIcons.plus_circle_fill, size: 24),
                  color: primaryColor,
                  tooltip: 'Add Task',
                  onPressed: () async {
                    AppleHaptics.lightImpact();
                    final task = await TaskEditorSheet.show(context);
                    if (task != null) {
                      ref.read(tasksProvider.notifier).addTask(task);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (todayTasks.isEmpty)
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: isDark ? BotanicalColors.darkSurface : BotanicalColors.lightSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? BotanicalColors.darkBorder : BotanicalColors.lightBorder,
                    width: 0.75,
                  ),
                ),
                child: const Center(
                  child: Text(
                    'All set! Tap + to add tasks to your daily rhythm.',
                    style: TextStyle(fontSize: 13, color: CupertinoColors.systemGrey),
                  ),
                ),
              )
            else
              ...todayTasks.map((task) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: task.isCompleted
                        ? (isDark ? BotanicalColors.darkCompletedTask : BotanicalColors.lightCompletedTask)
                        : (isDark ? BotanicalColors.darkSurface : BotanicalColors.lightSurface),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark ? BotanicalColors.darkBorder : BotanicalColors.lightBorder,
                      width: 0.75,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => _showTaskContextActions(context, task),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          CircularCheckbox(
                            value: task.isCompleted,
                            onChanged: (_) {
                              AppleHaptics.selection();
                              ref.read(tasksProvider.notifier).toggleTaskCompletion(task.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(task.isCompleted ? 'Task marked incomplete' : 'Task completed'),
                                  behavior: SnackBarBehavior.floating,
                                  action: SnackBarAction(
                                    label: 'Undo',
                                    onPressed: () => ref.read(tasksProvider.notifier).undoLastCompletion(),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task.title,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                    color: task.isCompleted
                                        ? CupertinoColors.systemGrey
                                        : (isDark ? BotanicalColors.darkTextPrimary : BotanicalColors.lightTextPrimary),
                                  ),
                                ),
                                if (task.dueTime != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 3),
                                    child: Text(
                                      'Due by ${task.dueTime!.hour}:${task.dueTime!.minute.toString().padLeft(2, '0')}',
                                      style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
                                    ),
                                  ),
                                if (task.subtasks.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Row(
                                      children: [
                                        const Icon(CupertinoIcons.list_bullet, size: 12, color: CupertinoColors.systemGrey),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${task.subtasks.where((s) => s.isCompleted).length}/${task.subtasks.length} subtasks',
                                          style: const TextStyle(fontSize: 11, color: CupertinoColors.systemGrey),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: task.priority.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              task.priority.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: task.priority.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(BuildContext context, Reminder reminder, bool isDark) {
    final effectiveTime = reminder.effectiveDueTime;
    final timeStr = DateFormat('h a').format(effectiveTime);
    final timeLeftStr = _formatTimeLeft(effectiveTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? BotanicalColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? BotanicalColors.darkBorder : BotanicalColors.lightBorder,
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _showReminderContextActions(context, reminder),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Circular Red Alert Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: BotanicalColors.alertRed,
                    width: 2.2,
                  ),
                ),
                child: const Center(
                  child: Text(
                    '!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: BotanicalColors.alertRed,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Content Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reminder deadline:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? BotanicalColors.darkTextSecondary : const Color(0xFF6E687A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      reminder.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: BotanicalColors.alertRedTitle,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 12,
                      children: [
                        Text(
                          'do it before: $timeStr',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? BotanicalColors.darkTextSecondary : const Color(0xFF3B3548),
                          ),
                        ),
                        Text(
                          'time left: $timeLeftStr',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? BotanicalColors.darkTextSecondary : const Color(0xFF3B3548),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action button to trigger quick options
              IconButton(
                icon: const Icon(CupertinoIcons.ellipsis_circle, size: 22),
                color: isDark ? BotanicalColors.darkTextSecondary : BotanicalColors.lightTextSecondary,
                onPressed: () => _showReminderContextActions(context, reminder),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
