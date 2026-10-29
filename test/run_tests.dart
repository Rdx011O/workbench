import 'package:workbench/models/task.dart';
import 'package:workbench/models/reminder.dart';
import 'package:workbench/models/event.dart';
import 'package:workbench/models/note.dart';
import 'package:workbench/models/journal_entry.dart';

void assertTrue(bool condition, String message) {
  if (!condition) {
    throw Exception('Assertion failed: $message');
  }
}

void assertEqual(dynamic actual, dynamic expected, String message) {
  if (actual != expected) {
    throw Exception('Assertion failed [$message]: expected $expected, got $actual');
  }
}

void main() {
  print('=============================================');
  print('Running Botanical Ink Domain Verification Suite...');
  print('=============================================');

  final now = DateTime.now();

  // Test 1: Task Overdue and Due Today calculations
  print('\n[1/5] Testing Task Due Statuses...');
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

  assertTrue(overdueTask.isOverdue, 'overdueTask.isOverdue must be true');
  assertTrue(!overdueTask.isDueToday, 'overdueTask.isDueToday must be false');
  assertTrue(todayTask.isDueToday, 'todayTask.isDueToday must be true');
  assertTrue(!todayTask.isOverdue, 'todayTask.isOverdue must be false');
  assertTrue(upcomingTask.isUpcoming, 'upcomingTask.isUpcoming must be true');
  print('  -> PASSED: Overdue, Due Today, and Upcoming task filters work correctly.');

  // Test 2: Task Map conversion and subtasks
  print('\n[2/5] Testing Task Serialization & Subtasks...');
  final taskWithSubtasks = Task(
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

  final taskMap = taskWithSubtasks.toMap();
  final restoredTask = Task.fromMap(taskMap);
  assertEqual(restoredTask.id, 'roundtrip-1', 'Task id match');
  assertEqual(restoredTask.title, 'Draft quarterly reflections', 'Task title match');
  assertEqual(restoredTask.priority, TaskPriority.high, 'Task priority match');
  assertEqual(restoredTask.subtasks.length, 2, 'Subtasks count');
  assertEqual(restoredTask.subtasks[0].title, 'Outline key themes', 'Subtask 1 title');
  assertTrue(restoredTask.subtasks[0].isCompleted, 'Subtask 1 completed');
  assertTrue(!restoredTask.subtasks[1].isCompleted, 'Subtask 2 not completed');
  print('  -> PASSED: Task serialization and subtasks roundtrip preserved.');

  // Test 3: Calendar Event Occurrence and Leap Year
  print('\n[3/5] Testing Calendar Events & Leap Year handling...');
  final event = CalendarEvent(
    id: 'ev-1',
    title: 'Botanical Field Expedition',
    startTime: DateTime(2026, 6, 1, 9, 0),
    endTime: DateTime(2026, 6, 3, 17, 0),
    createdAt: DateTime(2026, 5, 20),
  );
  assertTrue(event.occursOn(DateTime(2026, 6, 1)), 'Event occurs on start day');
  assertTrue(event.occursOn(DateTime(2026, 6, 2)), 'Event occurs on middle day');
  assertTrue(event.occursOn(DateTime(2026, 6, 3)), 'Event occurs on end day');
  assertTrue(!event.occursOn(DateTime(2026, 5, 31)), 'Event does not occur before start');
  assertTrue(!event.occursOn(DateTime(2026, 6, 4)), 'Event does not occur after end');

  final leapEvent = CalendarEvent(
    id: 'ev-leap',
    title: 'Leap Day Audit',
    startTime: DateTime(2024, 2, 29, 10, 0),
    endTime: DateTime(2024, 2, 29, 11, 0),
    createdAt: DateTime(2024, 2, 1),
  );
  assertTrue(leapEvent.occursOn(DateTime(2024, 2, 29)), 'Leap year Feb 29 matches');
  assertTrue(!leapEvent.occursOn(DateTime(2024, 2, 28)), 'Feb 28 does not match');
  print('  -> PASSED: Calendar occurrences, multi-day spans, and leap years handled.');

  // Test 4: Reminder Snooze
  print('\n[4/5] Testing Reminder Snooze...');
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
  assertEqual(snoozed.snoozedUntil, scheduledTime.add(const Duration(minutes: 15)), 'Snoozed 15 min');
  assertTrue(!snoozed.isCompleted, 'Snoozed reminder remains active');
  print('  -> PASSED: Reminder snooze and rescheduled time logic verified.');

  // Test 5: Note & Journal Entry
  print('\n[5/5] Testing Note Pinned State & Journal Serialization...');
  final note = Note(
    id: 'n-1',
    title: 'Pressed Botanicals Method',
    content: 'Use unbleached parchment sheets and moderate weight.',
    tags: ['botanical', 'craft', 'herbarium'],
    isPinned: true,
    createdAt: now,
    updatedAt: now,
  );
  final restoredNote = Note.fromMap(note.toMap());
  assertTrue(restoredNote.isPinned, 'Note pin status preserved');
  assertEqual(restoredNote.tags.length, 3, 'Note tag count');

  final journal = JournalEntry(
    id: 'j-1',
    date: '2026-06-10',
    thought: 'Quiet morning mist. Felt grounded after the first cup of sage tea.',
    mood: 'calm',
    prompt: 'A thought for today...',
    createdAt: now,
    updatedAt: now,
  );
  final restoredJournal = JournalEntry.fromMap(journal.toMap());
  assertEqual(restoredJournal.date, '2026-06-10', 'Journal date format');
  assertEqual(restoredJournal.mood, 'calm', 'Journal mood');
  assertTrue(restoredJournal.thought.contains('Quiet morning mist'), 'Journal thought content');
  print('  -> PASSED: Note tags, pinning, and Journal reflections verified.');

  print('\n=============================================');
  print('ALL 5 DOMAIN TEST SUITES PASSED! (100%)');
  print('=============================================');
}
