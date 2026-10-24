class CalendarEvent {
  final String id;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final bool isAllDay;
  final String? location;
  final String? recurrenceRule; // daily, weekly, monthly
  final String colorTag; // work, personal, health, reading, home
  final DateTime createdAt;

  CalendarEvent({
    required this.id,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    this.isAllDay = false,
    this.location,
    this.recurrenceRule,
    this.colorTag = 'work',
    required this.createdAt,
  });

  bool occursOn(DateTime date) {
    final startDay = DateTime(startTime.year, startTime.month, startTime.day);
    final endDay = DateTime(endTime.year, endTime.month, endTime.day);
    final targetDay = DateTime(date.year, date.month, date.day);
    return !targetDay.isBefore(startDay) && !targetDay.isAfter(endDay);
  }

  CalendarEvent copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    bool? isAllDay,
    String? location,
    String? recurrenceRule,
    String? colorTag,
    DateTime? createdAt,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isAllDay: isAllDay ?? this.isAllDay,
      location: location ?? this.location,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      colorTag: colorTag ?? this.colorTag,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'is_all_day': isAllDay ? 1 : 0,
      'location': location,
      'recurrence_rule': recurrenceRule,
      'color_tag': colorTag,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CalendarEvent.fromMap(Map<String, dynamic> map) {
    return CalendarEvent(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: DateTime.parse(map['end_time'] as String),
      isAllDay: (map['is_all_day'] as int) == 1,
      location: map['location'] as String?,
      recurrenceRule: map['recurrence_rule'] as String?,
      colorTag: map['color_tag'] as String? ?? 'work',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
