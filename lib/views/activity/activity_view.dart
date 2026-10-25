import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/colors.dart';
import '../../providers/providers.dart';
import '../../widgets/apple_widgets.dart';
import '../../widgets/botanical_icons.dart';

class ActivityView extends ConsumerWidget {
  const ActivityView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? BotanicalColors.darkPrimary : BotanicalColors.lightPrimary;
    final borderColor = isDark ? BotanicalColors.darkBorder : BotanicalColors.lightBorder;
    final surfaceColor = isDark ? BotanicalColors.darkSurface : BotanicalColors.lightSurface;

    final activity = ref.watch(activitySummaryProvider);
    final tasks = ref.watch(tasksProvider);
    final notes = ref.watch(notesProvider);

    final recentDoneTasks = tasks.where((t) => t.isCompleted && t.completedAt != null).toList()
      ..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));

    final recentNotes = List.from(notes)..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity & Consistency'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 60),
          children: [
            // Apple Fitness / Health Style Metric Grid
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor, width: 0.75),
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? Colors.transparent : const Color(0x06000000),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('DONE TODAY', style: Theme.of(context).textTheme.labelSmall),
                            Icon(CupertinoIcons.checkmark_alt_circle_fill, size: 16, color: primaryColor),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${activity.completedTasksToday}',
                          style: TextStyle(
                            fontFamily: 'DM Serif Display',
                            fontSize: 32,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('of ${activity.totalTasksToday} planned tasks', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor, width: 0.75),
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? Colors.transparent : const Color(0x06000000),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('NOTES LOGGED', style: Theme.of(context).textTheme.labelSmall),
                            const Icon(CupertinoIcons.book_fill, size: 16, color: BotanicalColors.lightAccent),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${activity.notesCreatedToday}',
                          style: const TextStyle(
                            fontFamily: 'DM Serif Display',
                            fontSize: 32,
                            color: BotanicalColors.lightAccent,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('thoughts & ideas', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 7-day Rhythm Trend Card (Apple Activity Rings / Bars style)
            const AppleSectionHeader('7-Day Completion Rhythm'),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor, width: 0.75),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.transparent : const Color(0x06000000),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(CupertinoIcons.flame_fill, size: 18, color: BotanicalColors.lightAccent),
                          const SizedBox(width: 8),
                          Text(
                            '${activity.currentStreakDays} Day Streak',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${(activity.completionRateToday * 100).round()}% Today',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // 7-day Bars
                  SizedBox(
                    height: 110,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(activity.past7DaysCompletions.length, (index) {
                        final count = activity.past7DaysCompletions[index];
                        final dayDate = DateTime.now().subtract(Duration(days: 6 - index));
                        final maxVal = activity.past7DaysCompletions.fold<int>(1, (max, v) => v > max ? v : max);
                        final fraction = (count / maxVal).clamp(0.08, 1.0);
                        final isToday = index == 6;

                        return Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              count > 0 ? '$count' : '',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isToday ? primaryColor : CupertinoColors.systemGrey,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: 14,
                              height: 65 * fraction,
                              decoration: BoxDecoration(
                                color: isToday
                                    ? primaryColor
                                    : (count > 0 ? primaryColor.withValues(alpha: 0.35) : borderColor),
                                borderRadius: BorderRadius.circular(7),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              DateFormat('E').format(dayDate).substring(0, 1),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                                color: isToday ? primaryColor : CupertinoColors.systemGrey,
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Inset Grouped Recent Completed Tasks
            if (recentDoneTasks.isNotEmpty) ...[
              const AppleSectionHeader('Recent Completions'),
              AppleGroupedCard(
                children: recentDoneTasks.take(5).map((t) {
                  return AppleListTile(
                    icon: BotanicalIcons.tasksFilled,
                    iconColor: primaryColor,
                    iconBackgroundColor: primaryColor.withValues(alpha: 0.12),
                    title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                    subtitle: t.completedAt != null
                        ? Text(
                            'Completed ${DateFormat('d MMM, h:mm a').format(t.completedAt!)}',
                            style: const TextStyle(fontSize: 12),
                          )
                        : null,
                    trailing: const SizedBox.shrink(),
                  );
                }).toList(),
              ),
            ],

            // Inset Grouped Recent Notes
            if (recentNotes.isNotEmpty) ...[
              const AppleSectionHeader('Latest Notes'),
              AppleGroupedCard(
                children: recentNotes.take(4).map((n) {
                  return AppleListTile(
                    icon: BotanicalIcons.notes,
                    iconColor: const Color(0xFF8A6C48),
                    iconBackgroundColor: const Color(0xFF8A6C48).withValues(alpha: 0.12),
                    title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                    subtitle: Text(n.content, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                    trailing: const Icon(CupertinoIcons.chevron_right, size: 14, color: CupertinoColors.systemGrey2),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
