class JournalEntry {
  final String id;
  final String date; // YYYY-MM-DD
  final String thought;
  final String? audioPath;
  final String mood; // calm, productive, reflective, grateful, rested
  final String? prompt;
  final DateTime createdAt;
  final DateTime updatedAt;

  JournalEntry({
    required this.id,
    required this.date,
    required this.thought,
    this.audioPath,
    this.mood = 'calm',
    this.prompt,
    required this.createdAt,
    required this.updatedAt,
  });

  JournalEntry copyWith({
    String? id,
    String? date,
    String? thought,
    String? audioPath,
    String? mood,
    String? prompt,
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
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    return JournalEntry(
      id: map['id'] as String,
      date: map['date'] as String,
      thought: map['thought'] as String,
      audioPath: map['audio_path'] as String?,
      mood: map['mood'] as String? ?? 'calm',
      prompt: map['prompt'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
