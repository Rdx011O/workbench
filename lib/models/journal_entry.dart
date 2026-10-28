class JournalEntry {
  final String id;
  final String date; // YYYY-MM-DD
  final String thought;
  final String? audioPath;
  final String mood; // bad, low, neutral, happy, super_happy (or calm, reflective, etc.)
  final String? prompt; // Used as title
  final List<String> tags;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  JournalEntry({
    required this.id,
    required this.date,
    required this.thought,
    this.audioPath,
    this.mood = 'neutral',
    this.prompt,
    this.tags = const [],
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
  });

  String get displayTitle =>
      (prompt != null && prompt!.trim().isNotEmpty) ? prompt!.trim() : 'Reflection';

  JournalEntry copyWith({
    String? id,
    String? date,
    String? thought,
    String? audioPath,
    String? mood,
    String? prompt,
    List<String>? tags,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      thought: thought ?? this.thought,
      audioPath: audioPath ?? this.audioPath,
      mood: mood ?? this.mood,
      prompt: prompt ?? this.prompt,
      tags: tags ?? this.tags,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'thought': thought,
      'audio_path': audioPath,
      'mood': mood,
      'prompt': prompt,
      'tags': tags.join('|||'),
      'is_archived': isArchived ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    final rawTags = map['tags'] as String?;
    final parsedTags = (rawTags != null && rawTags.isNotEmpty)
        ? rawTags.split('|||').where((t) => t.trim().isNotEmpty).toList()
        : <String>[];

    return JournalEntry(
      id: map['id'] as String,
      date: map['date'] as String,
      thought: map['thought'] as String,
      audioPath: map['audio_path'] as String?,
      mood: map['mood'] as String? ?? 'neutral',
      prompt: map['prompt'] as String?,
      tags: parsedTags,
      isArchived: (map['is_archived'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

