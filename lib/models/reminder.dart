class Reminder {
  final String id;
  final String title;
  final DateTime scheduledAt;
  final bool isRecurring;
  final String? recurrenceRule; // daily, weekdays, weekly
  final bool isCompleted;
  final DateTime? snoozedUntil;
  final DateTime createdAt;

  Reminder({
    required this.id,
    required this.title,
    required this.scheduledAt,
    this.isRecurring = false,
    this.recurrenceRule,
    this.isCompleted = false,
    this.snoozedUntil,
    required this.createdAt,
  });

  DateTime get effectiveDueTime => snoozedUntil ?? scheduledAt;

  bool get isDueToday {
    final effectiveTime = snoozedUntil ?? scheduledAt;
    final now = DateTime.now();
    return effectiveTime.year == now.year &&
        effectiveTime.month == now.month &&
        effectiveTime.day == now.day;
  }

  bool get isUpcoming {
    final effectiveTime = snoozedUntil ?? scheduledAt;
    return !isCompleted && effectiveTime.isAfter(DateTime.now());
  }

  bool get isOverdue {
    final effectiveTime = snoozedUntil ?? scheduledAt;
    return !isCompleted && effectiveTime.isBefore(DateTime.now());
  }

  Reminder copyWith({
    String? id,
    String? title,
    DateTime? scheduledAt,
    bool? isRecurring,
    String? recurrenceRule,
    bool? isCompleted,
    DateTime? snoozedUntil,
    DateTime? createdAt,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      isCompleted: isCompleted ?? this.isCompleted,
      snoozedUntil: snoozedUntil ?? this.snoozedUntil,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'scheduled_at': scheduledAt.toIso8601String(),
      'is_recurring': isRecurring ? 1 : 0,
      'recurrence_rule': recurrenceRule,
      'is_completed': isCompleted ? 1 : 0,
      'snoozed_until': snoozedUntil?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'] as String,
      title: map['title'] as String,
      scheduledAt: DateTime.parse(map['scheduled_at'] as String),
      isRecurring: (map['is_recurring'] as int? ?? 0) == 1,
      recurrenceRule: map['recurrence_rule'] as String?,
      isCompleted: (map['is_completed'] as int) == 1,
      snoozedUntil: map['snoozed_until'] != null ? DateTime.parse(map['snoozed_until'] as String) : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
