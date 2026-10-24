import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../core/theme/colors.dart';
import '../models/task.dart';
import 'botanical_icons.dart';

class TaskEditorSheet extends StatefulWidget {
  final Task? initialTask;
  final DateTime? prefilledDate;

  const TaskEditorSheet({
    super.key,
    this.initialTask,
    this.prefilledDate,
  });

  static Future<Task?> show(BuildContext context, {Task? task, DateTime? prefilledDate}) {
    return showModalBottomSheet<Task>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => TaskEditorSheet(
        initialTask: task,
        prefilledDate: prefilledDate,
      ),
    );
  }

  @override
  State<TaskEditorSheet> createState() => _TaskEditorSheetState();
}

class _TaskEditorSheetState extends State<TaskEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _newSubtaskController;

  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  TaskPriority _priority = TaskPriority.medium;
  String _category = 'Personal';
  String? _recurrence;
  List<Subtask> _subtasks = [];

  final List<String> _categories = ['Personal', 'Work', 'Health', 'Reading', 'Home'];
  final List<String> _recurrenceOptions = ['None', 'Daily', 'Weekly', 'Monthly'];

  @override
  void initState() {
    super.initState();
    final task = widget.initialTask;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController = TextEditingController(text: task?.description ?? '');
    _newSubtaskController = TextEditingController();

    _dueDate = task?.dueDate ?? widget.prefilledDate ?? DateTime.now();
    _dueTime = task?.dueTime;
    _priority = task?.priority ?? TaskPriority.medium;
    _category = task?.category ?? 'Personal';
    _recurrence = task?.recurrenceRule;
    _subtasks = task != null ? List<Subtask>.from(task.subtasks) : [];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _newSubtaskController.dispose();
    super.dispose();
  }

  void _addSubtask() {
    final text = _newSubtaskController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _subtasks.add(
        Subtask(
          id: const Uuid().v4(),
          taskId: widget.initialTask?.id ?? '',
          title: text,
          isCompleted: false,
          sortOrder: _subtasks.length,
        ),
      );
      _newSubtaskController.clear();
    });
  }

  void _removeSubtask(int index) {
    setState(() {
      _subtasks.removeAt(index);
    });
  }

  void _saveTask() {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final task = Task(
      id: widget.initialTask?.id ?? const Uuid().v4(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      dueDate: _dueDate,
      dueTime: _dueTime,
      priority: _priority,
      category: _category,
      isCompleted: widget.initialTask?.isCompleted ?? false,
      completedAt: widget.initialTask?.completedAt,
      isRecurring: _recurrence != null && _recurrence != 'None',
      recurrenceRule: _recurrence == 'None' ? null : _recurrence,
      createdAt: widget.initialTask?.createdAt ?? now,
      updatedAt: now,
      sortOrder: widget.initialTask?.sortOrder ?? 0,
      subtasks: _subtasks,
    );

    Navigator.of(context).pop(task);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? BotanicalColors.darkPrimary : BotanicalColors.lightPrimary;
    final borderColor = isDark ? BotanicalColors.darkBorder : BotanicalColors.lightBorder;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header handle & title
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.initialTask == null ? 'New Task' : 'Edit Task',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontFamily: 'DM Serif Display',
                        ),
                  ),
                  IconButton(
                    icon: const Icon(BotanicalIcons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Scrollable content
              Expanded(
                child: ListView(
                  children: [
                    // Task Title Input
                    TextFormField(
                      controller: _titleController,
                      autofocus: widget.initialTask == null,
                      style: Theme.of(context).textTheme.titleMedium,
                      decoration: const InputDecoration(
                        labelText: 'Task Title',
                        hintText: 'What needs to be done?',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a task title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Description Input
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Notes or details (optional)',
                        hintText: 'Add context, links, or thoughts...',
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Date & Time pickers row
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _dueDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2035),
                              );
                              if (picked != null) {
                                setState(() => _dueDate = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: borderColor),
                              ),
                              child: Row(
                                children: [
                                  const Icon(BotanicalIcons.calendar, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _dueDate == null ? 'Set Date' : DateFormat('dd MMM yyyy').format(_dueDate!),
                                      style: Theme.of(context).textTheme.bodyMedium,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: _dueTime ?? const TimeOfDay(hour: 12, minute: 0),
                              );
                              if (picked != null) {
                                setState(() => _dueTime = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: borderColor),
                              ),
                              child: Row(
                                children: [
                                  const Icon(BotanicalIcons.time, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _dueTime == null ? 'Set Time' : _dueTime!.format(context),
                                      style: Theme.of(context).textTheme.bodyMedium,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Priority Selector
                    Text('Priority', style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 8),
                    Row(
                      children: TaskPriority.values.map((priority) {
                        final isSelected = _priority == priority;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: Text(priority.label),
                              selected: isSelected,
                              selectedColor: priority.color.withValues(alpha: 0.2),
                              labelStyle: TextStyle(
                                color: isSelected ? priority.color : null,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                              side: BorderSide(
                                color: isSelected ? priority.color : borderColor,
                                width: isSelected ? 1.5 : 1,
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              onSelected: (val) {
                                if (val) setState(() => _priority = priority);
                              },
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // Category Selector
                    Text('Category', style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _categories.map((cat) {
                        final isSelected = _category == cat;
                        return ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          selectedColor: primaryColor.withValues(alpha: 0.15),
                          labelStyle: TextStyle(
                            color: isSelected ? primaryColor : null,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                          side: BorderSide(
                            color: isSelected ? primaryColor : borderColor,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          onSelected: (val) {
                            if (val) setState(() => _category = cat);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // Recurrence
                    DropdownButtonFormField<String>(
                      initialValue: _recurrence ?? 'None',
                      decoration: const InputDecoration(
                        labelText: 'Recurrence',
                        prefixIcon: Icon(BotanicalIcons.repeat, size: 18),
                      ),
                      items: _recurrenceOptions.map((opt) {
                        return DropdownMenuItem(value: opt, child: Text(opt));
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _recurrence = val);
                      },
                    ),
                    const SizedBox(height: 20),

                    // Subtasks Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Subtasks (${_subtasks.length})', style: Theme.of(context).textTheme.labelMedium),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._subtasks.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final subtask = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.circle_outlined, size: 14),
                            const SizedBox(width: 10),
                            Expanded(child: Text(subtask.title, style: Theme.of(context).textTheme.bodyMedium)),
                            IconButton(
                              icon: const Icon(BotanicalIcons.close, size: 16),
                              onPressed: () => _removeSubtask(idx),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      );
                    }),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _newSubtaskController,
                            decoration: const InputDecoration(
                              hintText: 'Add subtask...',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                            onSubmitted: (_) => _addSubtask(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _addSubtask,
                          icon: const Icon(BotanicalIcons.add),
                          style: IconButton.styleFrom(
                            backgroundColor: primaryColor.withValues(alpha: 0.12),
                            foregroundColor: primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _saveTask,
                      child: Text(widget.initialTask == null ? 'Create Task' : 'Save Changes'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
