import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/colors.dart';
import '../../models/reminder.dart';
import '../../providers/providers.dart';
import '../../widgets/apple_widgets.dart';
import '../../widgets/circular_checkbox.dart';
import '../../widgets/quick_add_sheet.dart';
import '../../widgets/reminder_editor_sheet.dart';
import '../../widgets/task_editor_sheet.dart';
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
    // Periodic ticker for live countdown in alerts
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? BotanicalColors.darkPrimary : BotanicalColors.lightPrimary;
    final activeWorkspace = ref.watch(activeWorkspaceProvider);
    final tasks = ref.watch(tasksProvider);
    final reminders = ref.watch(remindersProvider);

    final now = DateTime.now();
    final todayTasks = tasks.where((t) => t.isDueToday || !t.isCompleted).take(3).toList();
    final pendingTasksToday = tasks.where((t) => !t.isCompleted).length;
    final pendingRemindersCount = reminders.where((r) => !r.isCompleted).length;

    // Filter reminders for alerts: due today & not completed
    final alertReminders = reminders.where((r) => !r.isCompleted).toList();
    // Sort by effective due time
    alertReminders.sort((a, b) => a.effectiveDueTime.compareTo(b.effectiveDueTime));

    return Scaffold(
      backgroundColor: isDark ? BotanicalColors.darkBackground : BotanicalColors.lightBackground,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
          children: [
            // Top Bar: [Queue ⇅]  [Search] [Profile Avatar]
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Workspace Selector & Date
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      AppleHaptics.lightImpact();
                      WorkspaceSheet.show(context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  activeWorkspace,
                                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.8,
                                        color: isDark ? BotanicalColors.darkTextPrimary : BotanicalColors.lightPrimary,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    CupertinoIcons.chevron_up,
                                    size: 11,
                                    color: isDark ? BotanicalColors.darkTextSecondary : BotanicalColors.lightTextSecondary,
                                  ),
                                  Icon(
                                    CupertinoIcons.chevron_down,
                                    size: 11,
                                    color: isDark ? BotanicalColors.darkTextSecondary : BotanicalColors.lightTextSecondary,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('E d MMM').format(now),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? BotanicalColors.darkTextSecondary : const Color(0xFF2B2538),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Search Capsule Button
                InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () {
                    AppleHaptics.lightImpact();
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchView()));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                          color: isDark ? BotanicalColors.darkTextSecondary : const Color(0xFF6E687A),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'search',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark ? BotanicalColors.darkTextSecondary : const Color(0xFF6E687A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Profile Avatar Button
                InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () {
                    AppleHaptics.lightImpact();
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileView()));
                  },
                  child: Container(
                    width: 42,
                    height: 42,
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
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3F51B5),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const Icon(
                          CupertinoIcons.person_fill,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Summary Card (from screenshot: ✨ Summary, [X tasks] along with [Y reminder])
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
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
                  // ✨ Summary Pill Button
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

                  // "you had [ 3 tasks ] along with [ 1 reminder ]"
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'you had  ',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: isDark ? BotanicalColors.darkTextPrimary : const Color(0xFF2C243C),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: isDark ? BotanicalColors.taskBadgeDark : BotanicalColors.taskBadgeLight,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '$pendingTasksToday tasks',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : BotanicalColors.taskBadgeText,
                          ),
                        ),
                      ),
                      Text(
                        '  along with  ',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: isDark ? BotanicalColors.darkTextPrimary : const Color(0xFF2C243C),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: isDark ? BotanicalColors.reminderBadgeDark : BotanicalColors.reminderBadgeLight,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '$pendingRemindersCount reminder${pendingRemindersCount == 1 ? '' : 's'}',
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
            Text(
              'Alerts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? BotanicalColors.darkTextPrimary : const Color(0xFF2C243C),
              ),
            ),
            const SizedBox(height: 14),

            // Alert Cards matching screenshot
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
              const SizedBox(height: 10),

              // "See all ->" link button
              Center(
                child: TextButton.icon(
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(CupertinoIcons.arrow_right, size: 16),
                  label: const Text(
                    'See all',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: isDark ? BotanicalColors.darkAccent : const Color(0xFF5A4D78),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            const SizedBox(height: 24),

            // Today's Focus Checklist
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Today’s Focus',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? BotanicalColors.darkTextPrimary : const Color(0xFF2C243C),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  child: Row(
                    children: [
                      CircularCheckbox(
                        value: task.isCompleted,
                        onChanged: (_) {
                          AppleHaptics.selection();
                          ref.read(tasksProvider.notifier).toggleTaskCompletion(task.id);
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
                );
              }),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        elevation: 4,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        tooltip: 'Quick Create',
        onPressed: () {
          AppleHaptics.lightImpact();
          QuickAddSheet.show(context);
        },
        child: const Icon(CupertinoIcons.plus, size: 24),
      ),
    );
  }

  Widget _buildAlertCard(BuildContext context, Reminder reminder, bool isDark) {
    final effectiveTime = reminder.effectiveDueTime;
    final timeStr = DateFormat('h a').format(effectiveTime); // e.g. "1 PM"
    final timeLeftStr = _formatTimeLeft(effectiveTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
        onTap: () async {
          AppleHaptics.lightImpact();
          final updated = await ReminderEditorSheet.show(context, reminder: reminder);
          if (updated != null) {
            ref.read(remindersProvider.notifier).updateReminder(updated);
          }
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Circular Red Alert Icon (!)
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
          ],
        ),
      ),
    );
  }
}
