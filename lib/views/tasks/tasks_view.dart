import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/colors.dart';
import '../../models/task.dart';
import '../../providers/providers.dart';
import '../../widgets/apple_widgets.dart';
import '../../widgets/circular_checkbox.dart';
import '../../widgets/task_editor_sheet.dart';

enum TaskFilter { all, week, today, upcoming, overdue, completed }

enum TaskSort { dueDate, priority, title }

class TasksView extends ConsumerStatefulWidget {
  const TasksView({super.key});

  @override
  ConsumerState<TasksView> createState() => _TasksViewState();
}

class _TasksViewState extends ConsumerState<TasksView> {
  TaskFilter _filter = TaskFilter.week;
  TaskPriority? _priorityFilter;
  TaskSort _sort = TaskSort.dueDate;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isInCurrentWeek(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    final d = DateTime(date.year, date.month, date.day);
    final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final end = DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day);
    return !d.isBefore(start) && !d.isAfter(end);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? BotanicalColors.darkPrimary : BotanicalColors.lightPrimary;
    final borderColor = isDark ? BotanicalColors.darkBorder : BotanicalColors.lightBorder;
    final surfaceColor = isDark ? BotanicalColors.darkSurface : BotanicalColors.lightSurface;

    final allTasks = ref.watch(tasksProvider);

    // Apply filtering
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

      switch (_filter) {
        case TaskFilter.week:
          return (_isInCurrentWeek(task.dueDate) || (task.dueDate == null && _isInCurrentWeek(task.createdAt))) && !task.isCompleted;
        case TaskFilter.today:
          return task.isDueToday;
        case TaskFilter.upcoming:
          return task.isUpcoming;
        case TaskFilter.overdue:
          return task.isOverdue;
        case TaskFilter.completed:
          return task.isCompleted && _isInCurrentWeek(task.completedAt ?? task.dueDate ?? task.updatedAt);
        case TaskFilter.all:
          return true;
      }
    }).toList();

    // Apply sorting
    filtered.sort((a, b) {
      switch (_sort) {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.plus_circle_fill, size: 24),
            tooltip: 'New Task',
            onPressed: () async {
              AppleHaptics.lightImpact();
              final task = await TaskEditorSheet.show(context);
              if (task != null) {
                ref.read(tasksProvider.notifier).addTask(task);
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Apple Search Field
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: AppleSearchField(
                controller: _searchController,
                placeholder: 'Filter tasks...',
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                onClear: () => setState(() => _searchQuery = ''),
              ),
            ),

            // Apple Scope Filter Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  _buildFilterPill('This Week', TaskFilter.week),
                  const SizedBox(width: 8),
                  _buildFilterPill('Today', TaskFilter.today),
                  const SizedBox(width: 8),
                  _buildFilterPill('Upcoming', TaskFilter.upcoming),
                  const SizedBox(width: 8),
                  _buildFilterPill('Overdue', TaskFilter.overdue),
                  const SizedBox(width: 8),
                  _buildFilterPill('Completed (Week)', TaskFilter.completed),
                  const SizedBox(width: 8),
                  _buildFilterPill('All', TaskFilter.all),
                ],
              ),
            ),

            // Secondary Filter Controls (Sort & Priority)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Text('Priority: ', style: Theme.of(context).textTheme.labelSmall),
                  DropdownButton<TaskPriority?>(
                    value: _priorityFilter,
                    underline: const SizedBox.shrink(),
                    style: Theme.of(context).textTheme.labelSmall,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All')),
                      ...TaskPriority.values.map(
                        (p) => DropdownMenuItem(value: p, child: Text(p.label)),
                      ),
                    ],
                    onChanged: (val) {
                      AppleHaptics.selection();
                      setState(() => _priorityFilter = val);
                    },
                  ),
                  const Spacer(),
                  Text('Sort: ', style: Theme.of(context).textTheme.labelSmall),
                  DropdownButton<TaskSort>(
                    value: _sort,
                    underline: const SizedBox.shrink(),
                    style: Theme.of(context).textTheme.labelSmall,
                    items: const [
                      DropdownMenuItem(value: TaskSort.dueDate, child: Text('Due Date')),
                      DropdownMenuItem(value: TaskSort.priority, child: Text('Priority')),
                      DropdownMenuItem(value: TaskSort.title, child: Text('Title')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        AppleHaptics.selection();
                        setState(() => _sort = val);
                      }
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 0.5),

            // Task List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(CupertinoIcons.checkmark_circle, size: 42, color: CupertinoColors.systemGrey3),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isNotEmpty ? 'No tasks matching your search' : 'No tasks in this view',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(color: CupertinoColors.systemGrey),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final task = filtered[index];
                        return _buildTaskItem(context, task, isDark, primaryColor, borderColor, surfaceColor);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill(String label, TaskFilter filter) {
    final isSelected = _filter == filter;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? BotanicalColors.darkPrimary : BotanicalColors.lightPrimary;

    return Semantics(
      selected: isSelected,
      child: InkWell(
        onTap: () {
          AppleHaptics.selection();
          setState(() => _filter = filter);
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor
                : (isDark ? BotanicalColors.darkSecondarySurface : BotanicalColors.lightSecondarySurface),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : (isDark ? BotanicalColors.darkTextPrimary : BotanicalColors.lightTextPrimary),
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskItem(
    BuildContext context,
    Task task,
    bool isDark,
    Color primaryColor,
    Color borderColor,
    Color surfaceColor,
  ) {
    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: BotanicalColors.lightError.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(CupertinoIcons.trash, color: BotanicalColors.lightError, size: 22),
      ),
      confirmDismiss: (dir) async {
        return await showCupertinoDialog<bool>(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('Delete Task?'),
            content: Text('Are you sure you want to remove "${task.title}"?'),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        AppleHaptics.lightImpact();
        ref.read(tasksProvider.notifier).deleteTask(task.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: task.isCompleted
              ? (isDark ? BotanicalColors.darkCompletedSurface : BotanicalColors.lightCompletedSurface)
              : surfaceColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 0.75),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.transparent : const Color(0x06000000),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
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
              child: InkWell(
                onTap: () async {
                  AppleHaptics.selection();
                  final updated = await TaskEditorSheet.show(context, task: task);
                  if (updated != null) {
                    ref.read(tasksProvider.notifier).updateTask(updated);
                  }
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                            color: task.isCompleted ? CupertinoColors.systemGrey : null,
                            fontWeight: task.isCompleted ? FontWeight.normal : FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (task.dueDate != null) ...[
                          Icon(CupertinoIcons.calendar, size: 12, color: isDark ? BotanicalColors.darkTextSecondary : BotanicalColors.lightTextSecondary),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('d MMM').format(task.dueDate!),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: task.isOverdue ? BotanicalColors.lightError : null,
                                ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: task.priority.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            task.priority.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: task.priority.color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '· ${task.category}',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(CupertinoIcons.pencil, size: 18),
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
      ),
    );
  }
}
