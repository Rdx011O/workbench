import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/colors.dart';
import '../../models/event.dart';
import '../../models/task.dart';
import '../../providers/providers.dart';
import '../../widgets/apple_widgets.dart';
import '../../widgets/circular_checkbox.dart';
import '../../widgets/event_editor_sheet.dart';
import '../../widgets/task_editor_sheet.dart';

enum CalendarViewMode { month, week, day }

class CalendarView extends ConsumerStatefulWidget {
  const CalendarView({super.key});

  @override
  ConsumerState<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends ConsumerState<CalendarView> {
  late DateTime _displayedMonth;
  CalendarViewMode _viewMode = CalendarViewMode.month;

  @override
  void initState() {
    super.initState();
    final selected = ref.read(selectedDateProvider);
    _displayedMonth = DateTime(selected.year, selected.month, 1);
  }

  void _previousMonth() {
    AppleHaptics.selection();
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    AppleHaptics.selection();
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 1);
    });
  }

  void _goToToday() {
    AppleHaptics.selection();
    final now = DateTime.now();
    setState(() {
      _displayedMonth = DateTime(now.year, now.month, 1);
    });
    ref.read(selectedDateProvider.notifier).state = now;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? BotanicalColors.darkPrimary : BotanicalColors.lightPrimary;
    final borderColor = isDark ? BotanicalColors.darkBorder : BotanicalColors.lightBorder;
    final surfaceColor = isDark ? BotanicalColors.darkSurface : BotanicalColors.lightSurface;

    final selectedDate = ref.watch(selectedDateProvider);
    final events = ref.watch(eventsProvider);
    final tasks = ref.watch(tasksProvider);
    final reminders = ref.watch(remindersProvider);
    final settings = ref.watch(settingsProvider);

    final selectedEvents = events.where((e) => e.occursOn(selectedDate)).toList();
    final selectedTasks = tasks.where((t) {
      if (t.dueDate == null) return false;
      return t.dueDate!.year == selectedDate.year &&
          t.dueDate!.month == selectedDate.month &&
          t.dueDate!.day == selectedDate.day;
    }).toList();
    final selectedReminders = reminders.where((r) {
      final dt = r.snoozedUntil ?? r.scheduledAt;
      return dt.year == selectedDate.year && dt.month == selectedDate.month && dt.day == selectedDate.day;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          DateFormat('MMMM yyyy').format(_displayedMonth),
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
        ),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_left, size: 20),
          onPressed: _previousMonth,
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.chevron_right, size: 20),
            onPressed: _nextMonth,
          ),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            minSize: 34,
            onPressed: _goToToday,
            child: Text(
              'Today',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.plus_circle_fill, size: 24),
            tooltip: 'Add Event',
            onPressed: () async {
              AppleHaptics.lightImpact();
              final event = await EventEditorSheet.show(context, prefilledDate: selectedDate);
              if (event != null) {
                ref.read(eventsProvider.notifier).addEvent(event);
              }
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Apple Sliding Segmented Control for Month / Week / Day
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoSlidingSegmentedControl<CalendarViewMode>(
                  groupValue: _viewMode,
                  backgroundColor: isDark ? BotanicalColors.darkSecondarySurface : BotanicalColors.lightSecondarySurface,
                  thumbColor: isDark ? BotanicalColors.darkSurface : BotanicalColors.lightSurface,
                  children: {
                    CalendarViewMode.month: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text('Month', style: TextStyle(fontSize: 13, fontWeight: _viewMode == CalendarViewMode.month ? FontWeight.w600 : FontWeight.w500)),
                    ),
                    CalendarViewMode.week: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text('Week', style: TextStyle(fontSize: 13, fontWeight: _viewMode == CalendarViewMode.week ? FontWeight.w600 : FontWeight.w500)),
                    ),
                    CalendarViewMode.day: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text('Day', style: TextStyle(fontSize: 13, fontWeight: _viewMode == CalendarViewMode.day ? FontWeight.w600 : FontWeight.w500)),
                    ),
                  },
                  onValueChanged: (val) {
                    if (val != null) {
                      AppleHaptics.selection();
                      setState(() => _viewMode = val);
                    }
                  },
                ),
              ),
            ),
            const Divider(height: 0.5),

            // Calendar Scroll View
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                children: [
                  if (_viewMode == CalendarViewMode.month)
                    _buildMonthGrid(context, settings.weekStartMonday)
                  else if (_viewMode == CalendarViewMode.week)
                    _buildWeekGrid(context, settings.weekStartMonday)
                  else
                    _buildDayGrid(context),

                  const SizedBox(height: 18),

                  // Selected Day Section Header
                  AppleSectionHeader(
                    DateFormat('EEEE, d MMMM').format(selectedDate),
                    trailing: Text(
                      '${selectedEvents.length + selectedTasks.length + selectedReminders.length} items',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),

                  // Selected Day Agenda Items
                  if (selectedEvents.isEmpty && selectedTasks.isEmpty && selectedReminders.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: borderColor, width: 0.75),
                      ),
                      child: Center(
                        child: Text(
                          'No events or tasks scheduled for this day.\nTap + above to plan an event or reminder.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    )
                  else ...[
                    // Events
                    ...selectedEvents.map((event) => _buildEventCard(context, event, surfaceColor, borderColor, primaryColor)),
                    // Tasks
                    ...selectedTasks.map((task) => _buildTaskCard(context, task, surfaceColor, borderColor)),
                    // Reminders
                    ...selectedReminders.map((reminder) => _buildReminderCard(context, reminder, surfaceColor, borderColor)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthGrid(BuildContext context, bool weekStartMonday) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? BotanicalColors.darkPrimary : BotanicalColors.lightPrimary;
    final borderColor = isDark ? BotanicalColors.darkBorder : BotanicalColors.lightBorder;
    final surfaceColor = isDark ? BotanicalColors.darkSurface : BotanicalColors.lightSurface;
    final selectedDate = ref.watch(selectedDateProvider);
    final now = DateTime.now();

    final daysInMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;
    final firstWeekday = DateTime(_displayedMonth.year, _displayedMonth.month, 1).weekday;

    final offset = weekStartMonday ? (firstWeekday - 1) : (firstWeekday % 7);

    final weekdays = weekStartMonday
        ? ['M', 'T', 'W', 'T', 'F', 'S', 'S']
        : ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Container(
      padding: const EdgeInsets.all(14),
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
        children: [
          // Weekday header
          Row(
            children: weekdays.map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? BotanicalColors.darkTextSecondary : const Color(0xFF8E8E93),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),

          // 7-column calendar grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.05,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
            ),
            itemCount: 42,
            itemBuilder: (context, index) {
              final dayNumber = index - offset + 1;
              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const SizedBox.shrink();
              }

              final cellDate = DateTime(_displayedMonth.year, _displayedMonth.month, dayNumber);
              final isToday = cellDate.year == now.year && cellDate.month == now.month && cellDate.day == now.day;
              final isSelected = cellDate.year == selectedDate.year &&
                  cellDate.month == selectedDate.month &&
                  cellDate.day == selectedDate.day;

              final hasItems = ref.watch(eventsProvider).any((e) => e.occursOn(cellDate)) ||
                  ref.watch(tasksProvider).any((t) =>
                      t.dueDate?.year == cellDate.year &&
                      t.dueDate?.month == cellDate.month &&
                      t.dueDate?.day == cellDate.day);

              return Semantics(
                selected: isSelected,
                label: 'Day $dayNumber',
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    AppleHaptics.selection();
                    ref.read(selectedDateProvider.notifier).state = cellDate;
                  },
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isToday
                            ? primaryColor
                            : (isSelected
                                ? (isDark ? BotanicalColors.darkSecondarySurface : BotanicalColors.lightSecondarySurface)
                                : Colors.transparent),
                        border: isSelected && !isToday
                            ? Border.all(color: primaryColor, width: 1.5)
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$dayNumber',
                            style: TextStyle(
                              fontSize: 14,
                              color: isToday
                                  ? Colors.white
                                  : (isDark ? BotanicalColors.darkTextPrimary : BotanicalColors.lightTextPrimary),
                              fontWeight: (isToday || isSelected) ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                          if (hasItems)
                            Container(
                              margin: const EdgeInsets.only(top: 1),
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: isToday ? Colors.white : BotanicalColors.lightAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWeekGrid(BuildContext context, bool weekStartMonday) {
    final selectedDate = ref.watch(selectedDateProvider);
    final now = DateTime.now();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? BotanicalColors.darkPrimary : BotanicalColors.lightPrimary;
    final borderColor = isDark ? BotanicalColors.darkBorder : BotanicalColors.lightBorder;
    final surfaceColor = isDark ? BotanicalColors.darkSurface : BotanicalColors.lightSurface;

    final weekday = selectedDate.weekday;
    final daysToSubtract = weekStartMonday ? (weekday - 1) : (weekday % 7);
    final startOfWeek = selectedDate.subtract(Duration(days: daysToSubtract));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 0.75),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (index) {
          final day = startOfWeek.add(Duration(days: index));
          final isToday = day.year == now.year && day.month == now.month && day.day == now.day;
          final isSelected = day.year == selectedDate.year && day.month == selectedDate.month && day.day == selectedDate.day;

          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              AppleHaptics.selection();
              ref.read(selectedDateProvider.notifier).state = day;
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: isToday
                    ? primaryColor
                    : (isSelected
                        ? (isDark ? BotanicalColors.darkSecondarySurface : BotanicalColors.lightSecondarySurface)
                        : Colors.transparent),
                borderRadius: BorderRadius.circular(16),
                border: isSelected && !isToday ? Border.all(color: primaryColor, width: 1.2) : null,
              ),
              child: Column(
                children: [
                  Text(
                    DateFormat('E').format(day).substring(0, 1),
                    style: TextStyle(
                      color: isToday ? Colors.white : CupertinoColors.systemGrey,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      color: isToday
                          ? Colors.white
                          : (isDark ? BotanicalColors.darkTextPrimary : BotanicalColors.lightTextPrimary),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDayGrid(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? BotanicalColors.darkBorder : BotanicalColors.lightBorder;
    final surfaceColor = isDark ? BotanicalColors.darkSurface : BotanicalColors.lightSurface;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 0.75),
      ),
      child: Center(
        child: Column(
          children: [
            Text(
              DateFormat('EEEE').format(selectedDate),
              style: const TextStyle(
                color: BotanicalColors.lightAccent,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('d MMMM yyyy').format(selectedDate),
              style: const TextStyle(
                fontFamily: 'DM Serif Display',
                fontSize: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, CalendarEvent event, Color surfaceColor, Color borderColor, Color primaryColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 0.75),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(CupertinoIcons.clock, size: 12, color: CupertinoColors.systemGrey),
                    const SizedBox(width: 4),
                    Text(
                      event.isAllDay
                          ? 'All Day'
                          : '${DateFormat('h:mm a').format(event.startTime)} - ${DateFormat('h:mm a').format(event.endTime)}',
                      style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
                    ),
                    if (event.location != null) ...[
                      const SizedBox(width: 8),
                      const Icon(CupertinoIcons.location, size: 12, color: CupertinoColors.systemGrey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.location!,
                          style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.pencil, size: 16),
            onPressed: () async {
              AppleHaptics.selection();
              final updated = await EventEditorSheet.show(context, event: event);
              if (updated != null) {
                ref.read(eventsProvider.notifier).updateEvent(updated);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, Task task, Color surfaceColor, Color borderColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 0.75),
      ),
      child: Row(
        children: [
          CircularCheckbox(
            value: task.isCompleted,
            onChanged: (val) {
              ref.read(tasksProvider.notifier).toggleTaskCompletion(task.id);
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                    color: task.isCompleted ? CupertinoColors.systemGrey : null,
                  ),
                ),
                if (task.dueTime != null) ...[
                  const SizedBox(height: 2),
                  Text(task.dueTime!.format(context), style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey)),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.pencil, size: 16),
            onPressed: () async {
              AppleHaptics.selection();
              final updated = await TaskEditorSheet.show(context, task: task);
              if (updated != null) {
                ref.read(tasksProvider.notifier).updateTask(updated);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard(BuildContext context, dynamic reminder, Color surfaceColor, Color borderColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 0.75),
      ),
      child: Row(
        children: [
          const Icon(CupertinoIcons.bell, size: 18, color: BotanicalColors.lightAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              reminder.title as String,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
