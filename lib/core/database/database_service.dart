import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

import '../../models/event.dart';
import '../../models/journal_entry.dart';
import '../../models/note.dart';
import '../../models/reminder.dart';
import '../../models/task.dart';
import '../../models/user_settings.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  static Database? _database;
  final Uuid _uuid = const Uuid();

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = join(docsDir.path, 'botanical_planner.db');

    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        due_date TEXT,
        due_time_hour INTEGER,
        due_time_minute INTEGER,
        priority INTEGER NOT NULL,
        category TEXT NOT NULL,
        is_completed INTEGER NOT NULL,
        completed_at TEXT,
        is_recurring INTEGER NOT NULL,
        recurrence_rule TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sort_order INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE subtasks (
        id TEXT PRIMARY KEY,
        task_id TEXT NOT NULL,
        title TEXT NOT NULL,
        is_completed INTEGER NOT NULL,
        sort_order INTEGER NOT NULL,
        FOREIGN KEY (task_id) REFERENCES tasks (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE reminders (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        scheduled_at TEXT NOT NULL,
        is_recurring INTEGER NOT NULL,
        recurrence_rule TEXT,
        is_completed INTEGER NOT NULL,
        snoozed_until TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE events (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        is_all_day INTEGER NOT NULL,
        location TEXT,
        recurrence_rule TEXT,
        color_tag TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE notes (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        tags TEXT NOT NULL,
        is_pinned INTEGER NOT NULL,
        is_archived INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE journal_entries (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL UNIQUE,
        thought TEXT NOT NULL,
        audio_path TEXT,
        mood TEXT NOT NULL,
        prompt TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE preferences (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await _seedInitialData(db);
  }

  Future<void> _seedInitialData(Database db) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final tomorrow = today.add(const Duration(days: 1));

    // Seed Tasks
    final sampleTasks = [
      Task(
        id: _uuid.v4(),
        title: 'Review botanical design system tokens',
        description: 'Verify 24-32px radii, border contrasts, and touch targets across all screens.',
        dueDate: today,
        dueTime: const TimeOfDay(hour: 10, minute: 30),
        priority: TaskPriority.high,
        category: 'Work',
        isCompleted: true,
        completedAt: now.subtract(const Duration(hours: 2)),
        createdAt: yesterday,
        updatedAt: now,
        sortOrder: 0,
      ),
      Task(
        id: _uuid.v4(),
        title: 'Update monthly reflection journal',
        description: 'Log accomplishments and review quiet milestones from this week.',
        dueDate: today,
        dueTime: const TimeOfDay(hour: 14, minute: 0),
        priority: TaskPriority.medium,
        category: 'Personal',
        isCompleted: false,
        createdAt: yesterday,
        updatedAt: now,
        sortOrder: 1,
      ),
      Task(
        id: _uuid.v4(),
        title: 'Draft weekly client milestone summary',
        description: 'Prepare concise bullet points highlighting app performance and offline sync.',
        dueDate: today,
        dueTime: const TimeOfDay(hour: 16, minute: 30),
        priority: TaskPriority.high,
        category: 'Work',
        isCompleted: false,
        createdAt: yesterday,
        updatedAt: now,
        sortOrder: 2,
      ),
      Task(
        id: _uuid.v4(),
        title: 'Water patio ferns and indoor succulents',
        description: 'Check soil moisture before watering.',
        dueDate: today,
        dueTime: const TimeOfDay(hour: 18, minute: 0),
        priority: TaskPriority.low,
        category: 'Home',
        isCompleted: false,
        createdAt: yesterday,
        updatedAt: now,
        sortOrder: 3,
      ),
      Task(
        id: _uuid.v4(),
        title: 'Schedule quarterly dental checkup',
        description: 'Call Dr. Sarah clinic or book online appointment.',
        dueDate: yesterday,
        dueTime: const TimeOfDay(hour: 11, minute: 0),
        priority: TaskPriority.medium,
        category: 'Health',
        isCompleted: false,
        createdAt: yesterday.subtract(const Duration(days: 2)),
        updatedAt: yesterday,
        sortOrder: 4,
      ),
      Task(
        id: _uuid.v4(),
        title: 'Read chapter 4 of The Craftsman',
        description: 'Focus on material consciousness and rhythm of manual craft.',
        dueDate: tomorrow,
        dueTime: const TimeOfDay(hour: 20, minute: 0),
        priority: TaskPriority.low,
        category: 'Reading',
        isCompleted: false,
        createdAt: yesterday,
        updatedAt: now,
        sortOrder: 5,
      ),
    ];

    for (final task in sampleTasks) {
      await db.insert('tasks', task.toDbMap());
    }

    // Seed Reminders (Includes exact screenshot items)
    final sampleReminders = [
      Reminder(
        id: _uuid.v4(),
        title: 'UI system submission',
        scheduledAt: DateTime(now.year, now.month, now.day, 13, 0), // 1 PM
        isRecurring: false,
        createdAt: yesterday,
      ),
      Reminder(
        id: _uuid.v4(),
        title: 'Assignment submission',
        scheduledAt: DateTime(now.year, now.month, now.day, 21, 0), // 9 PM
        isRecurring: false,
        createdAt: yesterday,
      ),
      Reminder(
        id: _uuid.v4(),
        title: 'Midday posture check & 5 min eye rest',
        scheduledAt: DateTime(now.year, now.month, now.day, 14, 30),
        isRecurring: true,
        recurrenceRule: 'Daily',
        createdAt: yesterday,
      ),
      Reminder(
        id: _uuid.v4(),
        title: 'Prep herbal chamomile tea',
        scheduledAt: DateTime(now.year, now.month, now.day, 21, 30),
        isRecurring: true,
        recurrenceRule: 'Daily',
        createdAt: yesterday,
      ),
    ];

    for (final reminder in sampleReminders) {
      await db.insert('reminders', reminder.toMap());
    }

    // Seed Calendar Events
    final sampleEvents = [
      CalendarEvent(
        id: _uuid.v4(),
        title: 'Productivity Architecture & Design Sync',
        description: 'Review responsive layout and SQLite persistence benchmarks.',
        startTime: DateTime(now.year, now.month, now.day, 11, 0),
        endTime: DateTime(now.year, now.month, now.day, 12, 0),
        location: 'Studio / Virtual Room A',
        colorTag: 'work',
        createdAt: yesterday,
      ),
      CalendarEvent(
        id: _uuid.v4(),
        title: 'Focus Block: Deep Writing & Organizing',
        description: 'Uninterrupted deep work session without notifications.',
        startTime: DateTime(now.year, now.month, now.day, 14, 30),
        endTime: DateTime(now.year, now.month, now.day, 16, 0),
        location: 'Desk',
        colorTag: 'personal',
        createdAt: yesterday,
      ),
      CalendarEvent(
        id: _uuid.v4(),
        title: 'Evening Sunset Walk & Movement',
        description: '30-minute quiet walk in botanical garden.',
        startTime: DateTime(now.year, now.month, now.day, 18, 30),
        endTime: DateTime(now.year, now.month, now.day, 19, 15),
        location: 'City Greenbelt',
        colorTag: 'health',
        createdAt: yesterday,
      ),
    ];

    for (final event in sampleEvents) {
      await db.insert('events', event.toMap());
    }

    // Seed Notes
    final sampleNotes = [
      Note(
        id: _uuid.v4(),
        title: 'Principles for Calm Product Design',
        content: '1. Restrained color palettes feel tactile and enduring.\n2. Respect user attention; never generate artificial notification anxiety.\n3. Content-first layout with generous breathing room.\n4. Rounded, friendly shapes that feel warm like paper stationery.',
        tags: ['Design', 'Philosophy', 'Architecture'],
        isPinned: true,
        createdAt: yesterday.subtract(const Duration(days: 3)),
        updatedAt: yesterday,
      ),
      Note(
        id: _uuid.v4(),
        title: 'Books to read this autumn',
        content: '- The Craftsman by Richard Sennett\n- Four Thousand Weeks by Oliver Burkeman\n- In Praise of Shadows by Junichiro Tanizaki\n- The Design of Everyday Things by Don Norman',
        tags: ['Reading', 'Inspiration'],
        isPinned: false,
        createdAt: yesterday.subtract(const Duration(days: 1)),
        updatedAt: yesterday,
      ),
    ];

    for (final note in sampleNotes) {
      await db.insert('notes', note.toMap());
    }

    // Seed Today's Reflection
    final dateString = "${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    final sampleJournal = JournalEntry(
      id: _uuid.v4(),
      date: dateString,
      thought: 'Quiet focus brings clarity. Enjoying the tactile rhythm of intentional planning.',
      mood: 'calm',
      prompt: 'What brought you genuine focus today?',
      createdAt: now.subtract(const Duration(hours: 3)),
      updatedAt: now.subtract(const Duration(hours: 3)),
    );
    await db.insert('journal_entries', sampleJournal.toMap());

    // Seed Preferences
    final defaultSettings = UserSettings();
    for (final entry in defaultSettings.toPreferencesMap().entries) {
      await db.insert('preferences', {'key': entry.key, 'value': entry.value});
    }
  }

  // --- Task Methods ---
  Future<List<Task>> getTasks() async {
    final db = await database;
    final taskMaps = await db.query('tasks', orderBy: 'sort_order ASC, created_at DESC');
    final subtaskMaps = await db.query('subtasks', orderBy: 'sort_order ASC');

    final subtasksByTask = <String, List<Subtask>>{};
    for (final map in subtaskMaps) {
      final subtask = Subtask.fromMap(map);
      subtasksByTask.putIfAbsent(subtask.taskId, () => []).add(subtask);
    }

    return taskMaps.map((map) {
      final taskId = map['id'] as String;
      return Task.fromMap(map, subtasks: subtasksByTask[taskId] ?? []);
    }).toList();
  }

  Future<void> insertTask(Task task) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert('tasks', task.toDbMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      for (final subtask in task.subtasks) {
        await txn.insert('subtasks', subtask.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<void> updateTask(Task task) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update('tasks', task.toDbMap(), where: 'id = ?', whereArgs: [task.id]);
      await txn.delete('subtasks', where: 'task_id = ?', whereArgs: [task.id]);
      for (final subtask in task.subtasks) {
        await txn.insert('subtasks', subtask.toMap());
      }
    });
  }

  Future<void> deleteTask(String id) async {
    final db = await database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  // --- Reminder Methods ---
  Future<List<Reminder>> getReminders() async {
    final db = await database;
    final maps = await db.query('reminders', orderBy: 'scheduled_at ASC');
    return maps.map((map) => Reminder.fromMap(map)).toList();
  }

  Future<void> insertReminder(Reminder reminder) async {
    final db = await database;
    await db.insert('reminders', reminder.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateReminder(Reminder reminder) async {
    final db = await database;
    await db.update('reminders', reminder.toMap(), where: 'id = ?', whereArgs: [reminder.id]);
  }

  Future<void> deleteReminder(String id) async {
    final db = await database;
    await db.delete('reminders', where: 'id = ?', whereArgs: [id]);
  }

  // --- Calendar Event Methods ---
  Future<List<CalendarEvent>> getEvents() async {
    final db = await database;
    final maps = await db.query('events', orderBy: 'start_time ASC');
    return maps.map((map) => CalendarEvent.fromMap(map)).toList();
  }

  Future<void> insertEvent(CalendarEvent event) async {
    final db = await database;
    await db.insert('events', event.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateEvent(CalendarEvent event) async {
    final db = await database;
    await db.update('events', event.toMap(), where: 'id = ?', whereArgs: [event.id]);
  }

  Future<void> deleteEvent(String id) async {
    final db = await database;
    await db.delete('events', where: 'id = ?', whereArgs: [id]);
  }

  // --- Notes Methods ---
  Future<List<Note>> getNotes() async {
    final db = await database;
    final maps = await db.query('notes', orderBy: 'is_pinned DESC, updated_at DESC');
    return maps.map((map) => Note.fromMap(map)).toList();
  }

  Future<void> insertNote(Note note) async {
    final db = await database;
    await db.insert('notes', note.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateNote(Note note) async {
    final db = await database;
    await db.update('notes', note.toMap(), where: 'id = ?', whereArgs: [note.id]);
  }

  Future<void> deleteNote(String id) async {
    final db = await database;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  // --- Journal Methods ---
  Future<List<JournalEntry>> getJournalEntries() async {
    final db = await database;
    final maps = await db.query('journal_entries', orderBy: 'date DESC');
    return maps.map((map) => JournalEntry.fromMap(map)).toList();
  }

  Future<JournalEntry?> getJournalEntryForDate(String date) async {
    final db = await database;
    final maps = await db.query('journal_entries', where: 'date = ?', whereArgs: [date]);
    if (maps.isNotEmpty) {
      return JournalEntry.fromMap(maps.first);
    }
    return null;
  }

  Future<void> saveJournalEntry(JournalEntry entry) async {
    final db = await database;
    await db.insert('journal_entries', entry.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteJournalEntry(String id) async {
    final db = await database;
    await db.delete('journal_entries', where: 'id = ?', whereArgs: [id]);
  }

  // --- Preferences Methods ---
  Future<UserSettings> getUserSettings() async {
    final db = await database;
    final maps = await db.query('preferences');
    final prefMap = <String, String>{};
    for (final map in maps) {
      prefMap[map['key'] as String] = map['value'] as String;
    }
    return UserSettings.fromPreferencesMap(prefMap);
  }

  Future<void> saveUserSettings(UserSettings settings) async {
    final db = await database;
    final batch = db.batch();
    for (final entry in settings.toPreferencesMap().entries) {
      batch.insert('preferences', {'key': entry.key, 'value': entry.value}, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  // --- Backup & Export ---
  Future<Map<String, dynamic>> exportAllData() async {
    final tasks = await getTasks();
    final reminders = await getReminders();
    final events = await getEvents();
    final notes = await getNotes();
    final journal = await getJournalEntries();
    final settings = await getUserSettings();

    return {
      'exported_at': DateTime.now().toIso8601String(),
      'version': '1.0.0',
      'tasks': tasks.map((t) => t.toMap()).toList(),
      'reminders': reminders.map((r) => r.toMap()).toList(),
      'events': events.map((e) => e.toMap()).toList(),
      'notes': notes.map((n) => n.toMap()).toList(),
      'journal': journal.map((j) => j.toMap()).toList(),
      'settings': settings.toPreferencesMap(),
    };
  }

  Future<void> resetToDemoData() async {
    final db = await database;
    await db.delete('subtasks');
    await db.delete('tasks');
    await db.delete('reminders');
    await db.delete('events');
    await db.delete('notes');
    await db.delete('journal_entries');
    await db.delete('preferences');
    await _seedInitialData(db);
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('subtasks');
    await db.delete('tasks');
    await db.delete('reminders');
    await db.delete('events');
    await db.delete('notes');
    await db.delete('journal_entries');
  }
}
