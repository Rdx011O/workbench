import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/services/speech_service.dart';
import '../../core/theme/colors.dart';
import '../../models/journal_entry.dart';
import '../../models/task.dart';
import '../../providers/providers.dart';
import '../../widgets/apple_widgets.dart';
import '../../widgets/botanical_icons.dart';
import '../../widgets/circular_checkbox.dart';
import '../../widgets/quick_add_sheet.dart';
import '../../widgets/task_editor_sheet.dart';

class TodayView extends ConsumerStatefulWidget {
  const TodayView({super.key});

  @override
  ConsumerState<TodayView> createState() => _TodayViewState();
}

class _TodayViewState extends ConsumerState<TodayView> {
  final TextEditingController _thoughtController = TextEditingController();
  bool _isListening = false;
  bool _isSpeechAvailable = false;
  bool _isSavingThought = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _loadExistingThought();
  }

  Future<void> _initSpeech() async {
    final available = await SpeechService.instance.initialize();
    if (mounted) {
      setState(() => _isSpeechAvailable = available);
    }
  }

  void _loadExistingThought() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final today = DateTime.now();
      final existing = ref.read(journalProvider.notifier).getEntryForDate(today);
      if (existing != null && _thoughtController.text.isEmpty) {
        _thoughtController.text = existing.thought;
      }
    });
  }

  @override
  void dispose() {
    _thoughtController.dispose();
    super.dispose();
  }

  void _toggleListening() async {
    AppleHaptics.lightImpact();
    if (_isListening) {
      await SpeechService.instance.stopListening();
      setState(() => _isListening = false);
    } else {
      if (!_isSpeechAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Speech recognition is not available or permitted on this device.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      await SpeechService.instance.startListening(
        onResult: (words) {
          setState(() {
            _thoughtController.text = words;
          });
        },
        onStatusChange: (listening) {
          setState(() => _isListening = listening);
        },
      );
    }
  }

  Future<void> _saveThought() async {
    AppleHaptics.selection();
    final text = _thoughtController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSavingThought = true);
    final now = DateTime.now();
    final dateString = "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final entry = JournalEntry(
      id: const Uuid().v4(),
      date: dateString,
      thought: text,
      mood: 'calm',
      createdAt: now,
      updatedAt: now,
    );

    await ref.read(journalProvider.notifier).saveEntry(entry);
    if (mounted) {
      setState(() => _isSavingThought = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Reflection saved to your notebook.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? BotanicalColors.darkPrimary
              : BotanicalColors.lightPrimary,
        ),
      );
    }
  }

  void _showPastReflections() {
    AppleHaptics.lightImpact();
    final journal = ref.read(journalProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey4,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Past Reflections',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontFamily: 'DM Serif Display',
                        ),
                  ),
                  IconButton(
                    icon: const Icon(CupertinoIcons.xmark_circle_fill, size: 22, color: CupertinoColors.systemGrey3),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: journal.isEmpty
                    ? Center(
                        child: Text(
                          'No reflections recorded yet.\nWrite your first thought today.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: CupertinoColors.systemGrey,
                              ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: journal.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = journal[index];
                          DateTime entryDate;
                          try {
                            entryDate = DateTime.parse(item.date);
                          } catch (_) {
                            entryDate = item.createdAt;
                          }
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardTheme.color,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline,
                                width: 0.75,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      DateFormat('d MMMM yyyy').format(entryDate),
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                            color: BotanicalColors.lightAccent,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: BotanicalColors.lightSecondarySurface,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        item.mood,
                                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                              color: BotanicalColors.lightTextSecondary,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  item.thought,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        height: 1.45,
                                      ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getGreeting(String userName) {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning, $userName.';
    if (hour < 17) return 'Good afternoon, $userName.';
    return 'Good evening, $userName.';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? BotanicalColors.darkPrimary : BotanicalColors.lightPrimary;
    final borderColor = isDark ? BotanicalColors.darkBorder : BotanicalColors.lightBorder;
    final surfaceColor = isDark ? BotanicalColors.darkSurface : BotanicalColors.lightSurface;

    final tasks = ref.watch(tasksProvider);
    final activity = ref.watch(activitySummaryProvider);
    final settings = ref.watch(settingsProvider);

    final now = DateTime.now();
    final dayNum = now.day.toString().padLeft(2, '0');
    final monthShort = DateFormat('MMM').format(now).toUpperCase();
    final weekdayName = DateFormat('EEEE').format(now);

    // Group tasks
    final overdueTasks = tasks.where((t) => t.isOverdue).toList();
    final todayTasks = tasks.where((t) => t.isDueToday && !t.isCompleted).toList();
    final upcomingTasks = tasks.where((t) => t.isUpcoming).toList();
    final completedTasks = tasks.where((t) => t.isCompleted && t.isDueToday).toList();

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Apple Header with Editorial Date Display
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '$dayNum $monthShort',
                              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                    fontWeight: FontWeight.normal,
                                    letterSpacing: -0.6,
                                  ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              weekdayName,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: isDark ? BotanicalColors.darkTextSecondary : BotanicalColors.lightTextSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(CupertinoIcons.plus_circle_fill, size: 28),
                          tooltip: 'Quick Create',
                          color: primaryColor,
                          onPressed: () {
                            AppleHaptics.lightImpact();
                            QuickAddSheet.show(context);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Personalized greeting
                    Text(
                      _getGreeting(settings.userName),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isDark ? BotanicalColors.darkTextSecondary : BotanicalColors.lightTextSecondary,
                            fontSize: 15,
                          ),
                    ),
                    const SizedBox(height: 12),

                    // Inline Apple Badges
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildBadge(
                          context,
                          icon: BotanicalIcons.tasks,
                          label: '${activity.pendingTasksToday} tasks due',
                          color: primaryColor,
                        ),
                        _buildBadge(
                          context,
                          icon: BotanicalIcons.reminder,
                          label: '${activity.upcomingRemindersToday} reminders',
                          color: BotanicalColors.lightAccent,
                        ),
                        if (activity.notesCreatedToday > 0)
                          _buildBadge(
                            context,
                            icon: BotanicalIcons.notes,
                            label: '${activity.notesCreatedToday} notes today',
                            color: const Color(0xFF328A6E),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Daily Progress Summary Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor, width: 0.75),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.transparent : const Color(0x06000000),
                        blurRadius: 10,
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
                          Text(
                            'Daily Rhythm',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${activity.completedTasksToday} of ${activity.totalTasksToday} completed',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: isDark ? BotanicalColors.darkTextSecondary : BotanicalColors.lightTextSecondary,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: activity.totalTasksToday > 0 ? activity.completionRateToday : 0.0,
                          minHeight: 6,
                          backgroundColor: isDark
                              ? BotanicalColors.darkSecondarySurface
                              : BotanicalColors.lightSecondarySurface,
                          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Overdue Tasks Section
            if (overdueTasks.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: AppleSectionHeader(
                  'Overdue (${overdueTasks.length})',
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildTaskRow(context, overdueTasks[index]),
                    childCount: overdueTasks.length,
                  ),
                ),
              ),
            ],

            // Today's Tasks Section
            SliverToBoxAdapter(
              child: AppleSectionHeader(
                'Today (${todayTasks.length})',
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                trailing: CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 30,
                  onPressed: () async {
                    AppleHaptics.lightImpact();
                    final task = await TaskEditorSheet.show(context, prefilledDate: DateTime.now());
                    if (task != null) {
                      ref.read(tasksProvider.notifier).addTask(task);
                    }
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.add, size: 14, color: primaryColor),
                      const SizedBox(width: 4),
                      Text('Add Task', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: primaryColor)),
                    ],
                  ),
                ),
              ),
            ),

            if (todayTasks.isEmpty && completedTasks.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: borderColor, width: 0.75),
                    ),
                    child: Column(
                      children: [
                        Icon(CupertinoIcons.checkmark_seal, size: 36, color: primaryColor.withOpacity(0.5)),
                        const SizedBox(height: 12),
                        Text(
                          'No tasks remaining for today',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Enjoy your calm space, or add your first task below.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          icon: const Icon(CupertinoIcons.add, size: 16),
                          label: const Text('Add Task'),
                          onPressed: () async {
                            AppleHaptics.lightImpact();
                            final task = await TaskEditorSheet.show(context, prefilledDate: DateTime.now());
                            if (task != null) {
                              ref.read(tasksProvider.notifier).addTask(task);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildTaskRow(context, todayTasks[index]),
                    childCount: todayTasks.length,
                  ),
                ),
              ),

            // Completed Tasks Section
            if (completedTasks.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: AppleSectionHeader(
                  'Completed (${completedTasks.length})',
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildTaskRow(context, completedTasks[index]),
                    childCount: completedTasks.length,
                  ),
                ),
              ),
            ],

            // Upcoming Tasks Section
            if (upcomingTasks.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: AppleSectionHeader(
                  'Upcoming (${upcomingTasks.length})',
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildTaskRow(context, upcomingTasks[index]),
                    childCount: upcomingTasks.length,
                  ),
                ),
              ),
            ],

            // Daily Reflection Widget at Bottom (with 110 bottom scroll clearance)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 110),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor, width: 0.75),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(BotanicalIcons.journal, size: 18, color: primaryColor),
                              const SizedBox(width: 8),
                              Text(
                                'Daily Reflection',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontFamily: 'DM Serif Display',
                                      fontSize: 17,
                                    ),
                              ),
                            ],
                          ),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            minSize: 30,
                            onPressed: _showPastReflections,
                            child: Text(
                              'History',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: primaryColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _thoughtController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'A quiet thought for today…',
                          filled: true,
                          fillColor: isDark
                              ? BotanicalColors.darkSecondarySurface
                              : BotanicalColors.lightSecondarySurface.withOpacity(0.6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: primaryColor, width: 1.2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(
                              _isListening ? CupertinoIcons.mic_fill : CupertinoIcons.mic,
                              color: _isListening ? BotanicalColors.lightError : primaryColor,
                            ),
                            onPressed: _toggleListening,
                          ),
                          ElevatedButton.icon(
                            icon: _isSavingThought
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(CupertinoIcons.checkmark_alt, size: 16),
                            label: const Text('Save Reflection'),
                            onPressed: _isSavingThought ? null : _saveThought,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? BotanicalColors.darkBorder : BotanicalColors.lightBorder;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 0.75),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }

  Widget _buildTaskRow(BuildContext context, Task task) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? BotanicalColors.darkBorder : BotanicalColors.lightBorder;
    final surfaceColor = task.isCompleted
        ? (isDark ? BotanicalColors.darkCompletedSurface : BotanicalColors.lightCompletedSurface)
        : Theme.of(context).cardTheme.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: surfaceColor,
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () async {
            AppleHaptics.selection();
            final updated = await TaskEditorSheet.show(context, task: task);
            if (updated != null) {
              ref.read(tasksProvider.notifier).updateTask(updated);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                CircularCheckbox(
                  value: task.isCompleted,
                  onChanged: (val) {
                    ref.read(tasksProvider.notifier).toggleTaskCompletion(task.id);
                    if (val) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Completed "${task.title}"'),
                          action: SnackBarAction(
                            label: 'Undo',
                            textColor: BotanicalColors.lightAccent,
                            onPressed: () {
                              AppleHaptics.selection();
                              ref.read(tasksProvider.notifier).undoLastCompletion();
                            },
                          ),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                              color: task.isCompleted
                                  ? (isDark ? BotanicalColors.darkTextSecondary : BotanicalColors.lightTextSecondary)
                                  : null,
                              fontWeight: task.isCompleted ? FontWeight.normal : FontWeight.w500,
                            ),
                      ),
                      if (task.description != null && task.description!.isNotEmpty && !task.isCompleted) ...[
                        const SizedBox(height: 2),
                        Text(
                          task.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                if (task.dueTime != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark
                          ? BotanicalColors.darkSecondarySurface
                          : BotanicalColors.lightSecondarySurface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      task.dueTime!.format(context),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: isDark ? BotanicalColors.darkTextSecondary : BotanicalColors.lightTextSecondary,
                          ),
                    ),
                  ),
                ],
                if (task.priority == TaskPriority.high && !task.isCompleted) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: BotanicalColors.lightError,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
