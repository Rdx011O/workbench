import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:workbench/models/task.dart';
import 'package:workbench/models/reminder.dart';
import 'package:workbench/models/event.dart';
import 'package:workbench/models/note.dart';
import 'package:workbench/models/journal_entry.dart';
import 'package:workbench/models/user_settings.dart';
import 'package:workbench/widgets/user_avatar.dart';

void main() {
  group('Task Model & Priority Tests', () {
    test('Task creation and overdue/dueToday status calculation', () {
      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day, 14, 0);
      final yesterdayDate = todayDate.subtract(const Duration(days: 1));
      final tomorrowDate = todayDate.add(const Duration(days: 1));

      final overdueTask = Task(
        id: 't-1',
        title: 'Review herbarium specimen tags',
        priority: TaskPriority.high,
        dueDate: yesterdayDate,
        isCompleted: false,
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 1)),
      );

      final todayTask = Task(
        id: 't-2',
        title: 'Water morning seedlings',
        priority: TaskPriority.high,
        dueDate: todayDate,
        isCompleted: false,
        createdAt: now.subtract(const Duration(hours: 3)),
        updatedAt: now.subtract(const Duration(hours: 1)),
      );

      final upcomingTask = Task(
        id: 't-3',
        title: 'Prepare soil amendment',
        priority: TaskPriority.medium,
        dueDate: tomorrowDate,
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
      );

      expect(overdueTask.isOverdue, isTrue);
      expect(overdueTask.isDueToday, isFalse);

      expect(todayTask.isDueToday, isTrue);
      expect(todayTask.isOverdue, isFalse);

      expect(upcomingTask.isUpcoming, isTrue);
      expect(upcomingTask.isOverdue, isFalse);
      expect(upcomingTask.isDueToday, isFalse);
    });

    test('Task SQLite Map conversion roundtrip', () {
      final now = DateTime.now();
      final task = Task(
        id: 'roundtrip-1',
        title: 'Draft quarterly reflections',
        description: 'Focus on personal rhythm and creative output',
        priority: TaskPriority.high,
        dueDate: DateTime(2026, 6, 10, 9, 30),
        category: 'Personal',
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
        subtasks: [
          Subtask(id: 's-1', taskId: 'roundtrip-1', title: 'Outline key themes', isCompleted: true),
          Subtask(id: 's-2', taskId: 'roundtrip-1', title: 'Write closing summary', isCompleted: false),
        ],
      );

      final map = task.toMap();
      final restored = Task.fromMap(map);

      expect(restored.id, equals(task.id));
      expect(restored.title, equals(task.title));
      expect(restored.description, equals(task.description));
      expect(restored.priority, equals(TaskPriority.high));
      expect(restored.subtasks.length, equals(2));
      expect(restored.subtasks[0].title, equals('Outline key themes'));
      expect(restored.subtasks[0].isCompleted, isTrue);
      expect(restored.subtasks[1].isCompleted, isFalse);
    });
  });

  group('Calendar Event Date Matching Tests', () {
    test('Multi-day event occurrence matching', () {
      final baseEvent = CalendarEvent(
        id: 'ev-1',
        title: 'Botanical Field Expedition',
        startTime: DateTime(2026, 6, 1, 9, 0),
        endTime: DateTime(2026, 6, 3, 17, 0),
        createdAt: DateTime(2026, 5, 20),
      );

      expect(baseEvent.occursOn(DateTime(2026, 6, 1)), isTrue);
      expect(baseEvent.occursOn(DateTime(2026, 6, 2)), isTrue);
      expect(baseEvent.occursOn(DateTime(2026, 6, 3)), isTrue);
      expect(baseEvent.occursOn(DateTime(2026, 5, 31)), isFalse);
      expect(baseEvent.occursOn(DateTime(2026, 6, 4)), isFalse);
    });

    test('Leap year date handling', () {
      final leapYearEvent = CalendarEvent(
        id: 'ev-leap',
        title: 'Leap day review',
        startTime: DateTime(2024, 2, 29, 10, 0),
        endTime: DateTime(2024, 2, 29, 11, 0),
        createdAt: DateTime(2024, 2, 1),
      );

      expect(leapYearEvent.occursOn(DateTime(2024, 2, 29)), isTrue);
      expect(leapYearEvent.occursOn(DateTime(2024, 2, 28)), isFalse);
      expect(leapYearEvent.occursOn(DateTime(2024, 3, 1)), isFalse);
    });
  });

  group('Reminder Snooze & Due Tests', () {
    test('Snooze calculation updates reminder effective due time', () {
      final scheduledTime = DateTime(2026, 6, 10, 14, 0);
      final reminder = Reminder(
        id: 'rem-1',
        title: 'Afternoon tea & screen break',
        scheduledAt: scheduledTime,
        createdAt: DateTime(2026, 6, 1),
      );

      final snoozed = reminder.copyWith(
        snoozedUntil: scheduledTime.add(const Duration(minutes: 15)),
      );

      expect(snoozed.snoozedUntil, equals(scheduledTime.add(const Duration(minutes: 15))));
      expect(snoozed.isCompleted, isFalse);
    });
  });

  group('Note & Journal Serialization Tests', () {
    test('Note tags and pinned status persist correctly', () {
      final now = DateTime.now();
      final note = Note(
        id: 'n-1',
        title: 'Pressed Botanicals Method',
        content: 'Use unbleached parchment sheets and moderate weight.',
        tags: ['botanical', 'craft', 'herbarium'],
        isPinned: true,
        createdAt: now,
        updatedAt: now,
      );

      final map = note.toMap();
      final restored = Note.fromMap(map);

      expect(restored.isPinned, isTrue);
      expect(restored.tags, containsAll(['botanical', 'craft', 'herbarium']));
      expect(restored.title, equals('Pressed Botanicals Method'));
    });

    test('Journal entry reflection maps prompt and thoughts', () {
      final now = DateTime.now();
      final entry = JournalEntry(
        id: 'j-1',
        date: '2026-06-10',
        thought: 'Quiet morning mist. Felt grounded after the first cup of sage tea.',
        mood: 'calm',
        prompt: 'A thought for today...',
        createdAt: now,
        updatedAt: now,
      );

      final map = entry.toMap();
      final restored = JournalEntry.fromMap(map);

      expect(restored.thought, contains('Quiet morning mist'));
      expect(restored.mood, equals('calm'));
      expect(restored.date, equals('2026-06-10'));
    });
  });

  group('User Settings Tests', () {
    test('User settings default values and customization', () {
      final defaults = UserSettings();
      expect(defaults.userName, equals('Aadix'));
      expect(defaults.themeMode, equals(ThemeMode.light));
      expect(defaults.weekStartMonday, isTrue);
      expect(defaults.notificationsEnabled, isTrue);

      final custom = defaults.copyWith(
        userName: 'Aadix (Studio)',
        themeMode: ThemeMode.dark,
        weekStartMonday: false,
      );

      expect(custom.userName, equals('Aadix (Studio)'));
      expect(custom.themeMode, equals(ThemeMode.dark));
      expect(custom.weekStartMonday, isFalse);
    });

    test('Workspace configuration and serialization tests', () {
      final settings = UserSettings();
      expect(settings.activeWorkspace, equals('Workbench'));
      expect(settings.workspaces, contains('Workbench'));

      final modified = settings.copyWith(
        activeWorkspace: 'Creative Studio',
        workspaces: ['Workbench', 'Personal', 'Work', 'Creative Studio'],
      );
      expect(modified.activeWorkspace, equals('Creative Studio'));
      expect(modified.workspaces.length, equals(4));

      final prefMap = modified.toPreferencesMap();
      expect(prefMap['active_workspace'], equals('Creative Studio'));
      expect(prefMap['workspaces'], contains('Creative Studio'));

      final restored = UserSettings.fromPreferencesMap(prefMap);
      expect(restored.activeWorkspace, equals('Creative Studio'));
      expect(restored.workspaces, contains('Workbench'));
      expect(restored.workspaces, contains('Creative Studio'));
    });
  });

  group('Queue Refinement & Feature Tests', () {
    test('Part F: User Avatar initials generation rules', () {
      expect(UserAvatar.getInitials('Aaditya Battin'), equals('AB'));
      expect(UserAvatar.getInitials('Aaditya'), equals('A'));
      expect(UserAvatar.getInitials('Aaditya Shriniwas Battin'), equals('AB'));
      expect(UserAvatar.getInitials('  John   Doe  '), equals('JD'));
      expect(UserAvatar.getInitials(''), equals('Q'));
    });

    test('Part D: Subtask model serialization and toggle', () {
      final sub = Subtask(
        id: 'sub-1',
        taskId: 't-100',
        title: 'Draft wireframes',
        isCompleted: false,
        sortOrder: 1,
      );

      final toggled = sub.copyWith(isCompleted: true);
      expect(toggled.isCompleted, isTrue);
      expect(toggled.taskId, equals('t-100'));

      final map = toggled.toMap();
      expect(map['is_completed'], equals(1));
      expect(map['task_id'], equals('t-100'));

      final restored = Subtask.fromMap(map);
      expect(restored.id, equals('sub-1'));
      expect(restored.isCompleted, isTrue);
      expect(restored.title, equals('Draft wireframes'));
    });

    test('Part E: Journal exactly 4 supported moods', () {
      const allowedMoods = ['Happy 😊', 'Neutral 😐', 'Sad 😢', 'Angry 😠'];
      final entry = JournalEntry(
        id: 'j-1',
        prompt: 'Morning reflection',
        thought: 'Productive start to the sprint.',
        mood: 'Happy 😊',
        date: '2026-10-26',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(allowedMoods.contains(entry.mood), isTrue);
      final map = entry.toMap();
      final restored = JournalEntry.fromMap(map);
      expect(restored.mood, equals('Happy 😊'));
      expect(restored.prompt, equals('Morning reflection'));
      expect(restored.thought, equals('Productive start to the sprint.'));
    });
  });
}

