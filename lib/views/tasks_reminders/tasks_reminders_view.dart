import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/colors.dart';
import '../../models/reminder.dart';
import '../../models/task.dart';
import '../../providers/providers.dart';
import '../../widgets/apple_widgets.dart';
import '../../widgets/circular_checkbox.dart';
import '../../widgets/reminder_editor_sheet.dart';
import '../../widgets/task_editor_sheet.dart';

enum TaskFilter { all, today, upcoming, overdue, completed }

enum TaskSort { dueDate, priority, title }

class TasksAndRemindersView extends ConsumerStatefulWidget {
  final int initialTab;
  const TasksAndRemindersView({super.key, this.initialTab = 0});

  @override
  ConsumerState<TasksAndRemindersView> createState() => _TasksAndRemindersViewState();
}

class _TasksAndRemindersViewState extends ConsumerState<TasksAndRemindersView> {
  late int _selectedTab; // 0: Tasks, 1: Reminders

  // Tasks filter states
  TaskFilter _taskFilter = TaskFilter.all;
  TaskPriority? _priorityFilter;
  TaskSort _taskSort = TaskSort.dueDate;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? BotanicalColors.darkPrimary : BotanicalColors.lightPrimary;

    return Scaffold(
      appBar: AppBar(
        title: CupertinoSlidingSegmentedControl<int>(
          groupValue: _selectedTab,
          backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
          thumbColor: isDark ? BotanicalColors.darkSurface : Colors.white,
          children: {
            0: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Text(
                'Tasks',
                style: TextStyle(
                  fontWeight: _selectedTab == 0 ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                  color: isDark ? BotanicalColors.darkTextPrimary : BotanicalColors.lightTextPrimary,
                ),
              ),
            ),
            1: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Text(
                'Reminders',
                style: TextStyle(
                  fontWeight: _selectedTab == 1 ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                  color: isDark ? BotanicalColors.darkTextPrimary : BotanicalColors.lightTextPrimary,
                ),
              ),
            ),
          },
          onValueChanged: (val) {
            if (val != null) {
              AppleHaptics.selection();
              setState(() => _selectedTab = val);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.plus_circle_fill, size: 26),
            color: primaryColor,
            tooltip: _selectedTab == 0 ? 'New Task' : 'New Reminder',
            onPressed: () async {
              AppleHaptics.lightImpact();
              if (_selectedTab == 0) {
                final task = await TaskEditorSheet.show(context);
                if (task != null) {
                  ref.read(tasksProvider.notifier).addTask(task);
                }
              } else {
                final reminder = await ReminderEditorSheet.show(context);
                if (reminder != null) {
                  ref.read(remindersProvider.notifier).addReminder(reminder);
                }
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: _selectedTab == 0 ? _buildTasksBody(context) : _buildRemindersBody(context),
      ),
    );
  }

  // --- Tasks Tab ---
  Widget _buildTasksBody(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? BotanicalColors.darkPrimary : BotanicalColors.lightPrimary;
    final allTasks = ref.watch(tasksProvider);

    List<Task> filtered = allTasks.where((task) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesTitle = task.title.toLowerCase().contains(q);
        final matchesDesc = task.description?.toLowerCase().contains(q) ?? false;
        final matchesCategory = task.category.toLowerCase().contains(q);
        if (!matchesTitle && !matchesDesc && !matchesCategory) return false;
      }
      if (_priorityFilter != null && task.priority != _priorityFilter) {
        return false;
      }
      switch (_taskFilter) {
        case TaskFilter.all:
          return true;
        case TaskFilter.today:
          return task.isDueToday;
        case TaskFilter.upcoming:
          return task.isUpcoming;
        case TaskFilter.overdue:
          return task.isOverdue;
        case TaskFilter.completed:
          return task.isCompleted;
      }
    }).toList();

    filtered.sort((a, b) {
      switch (_taskSort) {
        case TaskSort.dueDate:
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        case TaskSort.priority:
          return b.priority.index.compareTo(a.priority.index);
        case TaskSort.title:
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      }
    });

    return Column(
      children: [
        // Search & Sort bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search tasks...',
                      hintStyle: const TextStyle(fontSize: 13),
                      prefixIcon: const Icon(CupertinoIcons.search, size: 16),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                      filled: true,
                      fillColor: isDark ? BotanicalColors.darkSurface : BotanicalColors.lightSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? BotanicalColors.darkBorder : BotanicalColors.lightBorder,
                          width: 0.8,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<TaskSort>(
                icon: const Icon(CupertinoIcons.arrow_up_arrow_down, size: 18),
                tooltip: 'Sort tasks',
                onSelected: (sort) => setState(() => _taskSort = sort),
                itemBuilder: (ctx) => const [
                  PopupMenuItem(value: TaskSort.dueDate, child: Text('Sort by Due Date')),
                  PopupMenuItem(value: TaskSort.priority, child: Text('Sort by Priority')),
                  PopupMenuItem(value: TaskSort.title, child: Text('Sort by Title')),
                ],
              ),
            ],
          ),
        ),
        // Filter Chips row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              _buildFilterPill('All', TaskFilter.all),
              _buildFilterPill('Today', TaskFilter.today),
              _buildFilterPill('Upcoming', TaskFilter.upcoming),
              _buildFilterPill('Overdue', TaskFilter.overdue),
              _buildFilterPill('Done', TaskFilter.completed),
            ],
          ),
        ),

        // List
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState('No tasks found in this filter.')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 90),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final task = filtered[index];
                    return _buildTaskCard(task, isDark, primaryColor);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterPill(String label, TaskFilter filter) {
    final isSelected = _taskFilter == filter;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? BotanicalColors.darkPrimary : BotanicalColors.lightPrimary;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: primaryColor.withValues(alpha: 0.15),
        labelStyle: TextStyle(
          color: isSelected
              ? primaryColor
              : (isDark ? BotanicalColors.darkTextSecondary : BotanicalColors.lightTextSecondary),
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: BorderSide(
          color: isSelected ? primaryColor : Colors.transparent,
        ),
        onSelected: (_) {
          AppleHaptics.selection();
          setState(() => _taskFilter = filter);
        },
      ),
    );
  }

  Widget _buildTaskCard(Task task, bool isDark, Color primaryColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? BotanicalColors.darkSurface : BotanicalColors.lightSurface,
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
        onTap: () async {
          AppleHaptics.lightImpact();
          final updated = await TaskEditorSheet.show(context, task: task);
          if (updated != null) {
            ref.read(tasksProvider.notifier).updateTask(updated);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
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
                            ? (isDark ? Colors.white38 : Colors.black38)
                            : (isDark ? BotanicalColors.darkTextPrimary : BotanicalColors.lightTextPrimary),
                      ),
                    ),
                    if (task.description != null && task.description!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        task.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? BotanicalColors.darkTextSecondary : BotanicalColors.lightTextSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (task.dueDate != null) ...[
                          Icon(
                            CupertinoIcons.calendar,
                            size: 13,
                            color: task.isOverdue
                                ? BotanicalColors.alertRed
                                : (isDark ? BotanicalColors.darkTextSecondary : BotanicalColors.lightTextSecondary),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            task.isDueToday
                                ? 'Today'
                                : '${task.dueDate!.day}/${task.dueDate!.month}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: task.isOverdue
                                  ? BotanicalColors.alertRed
                                  : (isDark ? BotanicalColors.darkTextSecondary : BotanicalColors.lightTextSecondary),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: task.priority.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            task.priority.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: task.priority.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(CupertinoIcons.ellipsis, size: 18),
                color: isDark ? BotanicalColors.darkTextSecondary : BotanicalColors.lightTextSecondary,
                onPressed: () => _showTaskActions(task),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTaskActions(Task task) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(task.title),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final updated = await TaskEditorSheet.show(context, task: task);
              if (updated != null) {
                ref.read(tasksProvider.notifier).updateTask(updated);
              }
            },
            child: const Text('Edit Task'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(tasksProvider.notifier).deleteTask(task.id);
            },
            child: const Text('Delete Task'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  // --- Reminders Tab ---
  Widget _buildRemindersBody(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? BotanicalColors.darkPrimary : BotanicalColors.lightPrimary;
    final reminders = ref.watch(remindersProvider);

    final todayReminders = reminders.where((r) => r.isDueToday && !r.isCompleted).toList();
    final upcomingReminders = reminders.where((r) => !r.isDueToday && r.isUpcoming).toList();
    final completedReminders = reminders.where((r) => r.isCompleted).toList();

    if (reminders.isEmpty) {
      return _buildEmptyState('No reminders yet. Tap + to add one.');
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
      children: [
        if (todayReminders.isNotEmpty) ...[
          AppleSectionHeader('Today (${todayReminders.length})'),
          AppleGroupedCard(
            children: todayReminders.map((r) => _buildReminderTile(r, isDark, primaryColor)).toList(),
          ),
          const SizedBox(height: 16),
        ],
        if (upcomingReminders.isNotEmpty) ...[
          AppleSectionHeader('Upcoming (${upcomingReminders.length})'),
          AppleGroupedCard(
            children: upcomingReminders.map((r) => _buildReminderTile(r, isDark, primaryColor)).toList(),
          ),
          const SizedBox(height: 16),
        ],
        if (completedReminders.isNotEmpty) ...[
          AppleSectionHeader('Completed (${completedReminders.length})'),
          AppleGroupedCard(
            children: completedReminders.map((r) => _buildReminderTile(r, isDark, primaryColor)).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildReminderTile(Reminder reminder, bool isDark, Color primaryColor) {
    return AppleListTile(
      leading: CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        onPressed: () {
          AppleHaptics.selection();
          ref.read(remindersProvider.notifier).toggleReminderCompletion(reminder.id);
        },
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: reminder.isCompleted
                  ? primaryColor
                  : (isDark ? BotanicalColors.darkBorder : BotanicalColors.lightBorder),
              width: 1.5,
            ),
            color: reminder.isCompleted ? primaryColor : Colors.transparent,
          ),
          child: reminder.isCompleted
              ? const Center(child: Icon(CupertinoIcons.checkmark, size: 14, color: Colors.white))
              : null,
        ),
      ),
      title: Text(
        reminder.title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          decoration: reminder.isCompleted ? TextDecoration.lineThrough : null,
          color: reminder.isCompleted
              ? CupertinoColors.systemGrey
              : (isDark ? BotanicalColors.darkTextPrimary : BotanicalColors.lightTextPrimary),
        ),
      ),
      subtitle: Text(
        'Due ${reminder.effectiveDueTime.hour.toString().padLeft(2, '0')}:${reminder.effectiveDueTime.minute.toString().padLeft(2, '0')}${reminder.isRecurring ? ' · Repeating' : ''}',
        style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
      ),
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        onPressed: () async {
          AppleHaptics.lightImpact();
          final updated = await ReminderEditorSheet.show(context, reminder: reminder);
          if (updated != null) {
            ref.read(remindersProvider.notifier).updateReminder(updated);
          }
        },
        child: const Icon(CupertinoIcons.ellipsis, size: 18, color: CupertinoColors.systemGrey),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(CupertinoIcons.check_mark_circled, size: 48, color: CupertinoColors.systemGrey3),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(fontSize: 14, color: CupertinoColors.systemGrey),
          ),
        ],
      ),
    );
  }
}
