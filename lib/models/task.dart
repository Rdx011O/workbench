import 'package:flutter/material.dart';

enum TaskPriority {
  low,
  medium,
  high;

  String get label {
    switch (this) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
    }
  }

  Color get color {
    switch (this) {
      case TaskPriority.low:
        return const Color(0xFF747A72);
      case TaskPriority.medium:
        return const Color(0xFF5E8B7E);
      case TaskPriority.high:
        return const Color(0xFFC77D5B); // Terracotta for high priority
    }
  }
}

class Subtask {
  final String id;
  final String taskId;
  final String title;
  final bool isCompleted;
  final int sortOrder;

  Subtask({
    required this.id,
    required this.taskId,
    required this.title,
    this.isCompleted = false,
    this.sortOrder = 0,
  });

  Subtask copyWith({
    String? id,
    String? taskId,
    String? title,
    bool? isCompleted,
    int? sortOrder,
  }) {
    return Subtask(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task_id': taskId,
      'title': title,
      'is_completed': isCompleted ? 1 : 0,
      'sort_order': sortOrder,
    };
  }

  factory Subtask.fromMap(Map<String, dynamic> map) {
    return Subtask(
      id: map['id'] as String,
      taskId: map['task_id'] as String,
      title: map['title'] as String,
      isCompleted: (map['is_completed'] as int) == 1,
      sortOrder: map['sort_order'] as int? ?? 0,
    );
  }
}

class Task {
  final String id;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final TimeOfDay? dueTime;
  final TaskPriority priority;
  final String category;
  final bool isCompleted;
  final DateTime? completedAt;
  final bool isRecurring;
  final String? recurrenceRule; // daily, weekly, monthly
  final DateTime createdAt;
  final DateTime updatedAt;
  final int sortOrder;
  final List<Subtask> subtasks;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.dueTime,
    this.priority = TaskPriority.medium,
    this.category = 'Personal',
    this.isCompleted = false,
    this.completedAt,
    this.isRecurring = false,
    this.recurrenceRule,
    required this.createdAt,
    required this.updatedAt,
    this.sortOrder = 0,
    this.subtasks = const [],
  });

  DateTime? get deadlineDateTime {
    if (dueDate == null) return null;
    return DateTime(
      dueDate!.year,
      dueDate!.month,
      dueDate!.day,
      dueTime?.hour ?? 23,
      dueTime?.minute ?? 59,
    );
  }

  bool get isOverdue {
    if (isCompleted || dueDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    if (taskDate.isBefore(today)) return true;
    if (taskDate.isAtSameMomentAs(today) && dueTime != null) {
      final taskTime = DateTime(now.year, now.month, now.day, dueTime!.hour, dueTime!.minute);
      return now.isAfter(taskTime);
    }
    return false;
  }

  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year && dueDate!.month == now.month && dueDate!.day == now.day;
  }

  bool get isUpcoming {
    if (isCompleted || dueDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return taskDate.isAfter(today);
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    TimeOfDay? dueTime,
    TaskPriority? priority,
    String? category,
    bool? isCompleted,
    DateTime? completedAt,
    bool? isRecurring,
    String? recurrenceRule,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? sortOrder,
    List<Subtask>? subtasks,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sortOrder: sortOrder ?? this.sortOrder,
      subtasks: subtasks ?? this.subtasks,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'due_date': dueDate?.toIso8601String(),
      'due_time_hour': dueTime?.hour,
      'due_time_minute': dueTime?.minute,
      'priority': priority.index,
      'category': category,
      'is_completed': isCompleted ? 1 : 0,
      'completed_at': completedAt?.toIso8601String(),
      'is_recurring': isRecurring ? 1 : 0,
      'recurrence_rule': recurrenceRule,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'sort_order': sortOrder,
      if (subtasks.isNotEmpty) 'subtasks': subtasks.map((s) => s.toMap()).toList(),
    };
  }

  Map<String, dynamic> toDbMap() {
    final map = toMap();
    map.remove('subtasks');
    return map;
  }

  factory Task.fromMap(Map<String, dynamic> map, {List<Subtask>? subtasks}) {
    List<Subtask> parsedSubtasks = subtasks ?? [];
    if (parsedSubtasks.isEmpty && map['subtasks'] != null && map['subtasks'] is List) {
      parsedSubtasks = (map['subtasks'] as List)
          .map((s) => Subtask.fromMap(s as Map<String, dynamic>))
          .toList();
    }

    return Task(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date'] as String) : null,
      dueTime: (map['due_time_hour'] != null && map['due_time_minute'] != null)
          ? TimeOfDay(hour: map['due_time_hour'] as int, minute: map['due_time_minute'] as int)
          : null,
      priority: TaskPriority.values[map['priority'] as int? ?? 1],
      category: map['category'] as String? ?? 'Personal',
      isCompleted: (map['is_completed'] as int) == 1,
      completedAt: map['completed_at'] != null ? DateTime.parse(map['completed_at'] as String) : null,
      isRecurring: (map['is_recurring'] as int? ?? 0) == 1,
      recurrenceRule: map['recurrence_rule'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      sortOrder: map['sort_order'] as int? ?? 0,
      subtasks: parsedSubtasks,
    );
  }
}
