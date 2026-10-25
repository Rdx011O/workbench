import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/database_service.dart';
import '../core/services/notification_service.dart';
import '../models/event.dart';
import '../models/journal_entry.dart';
import '../models/note.dart';
import '../models/reminder.dart';
import '../models/task.dart';
import '../models/user_settings.dart';

// --- Database Service Provider ---
final databaseServiceProvider = Provider<DatabaseService>((ref) => DatabaseService.instance);

// --- Notification Service Provider ---
final notificationServiceProvider = Provider<NotificationService>((ref) => NotificationService.instance);

// --- Task Notifier & Provider ---
class TaskNotifier extends StateNotifier<List<Task>> {
  final DatabaseService _db;
  Task? _lastCompletedTask;

  TaskNotifier(this._db) : super([]) {
    loadTasks();
  }

  Future<void> loadTasks() async {
    final tasks = await _db.getTasks();
    state = tasks;
  }

  Future<void> addTask(Task task) async {
    await _db.insertTask(task);
    await loadTasks();
  }

  Future<void> updateTask(Task task) async {
    await _db.updateTask(task);
    await loadTasks();
  }

  Future<void> toggleTaskCompletion(String taskId) async {
    final taskIndex = state.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return;

    final currentTask = state[taskIndex];
    final newStatus = !currentTask.isCompleted;
    final updatedTask = currentTask.copyWith(
      isCompleted: newStatus,
      completedAt: newStatus ? DateTime.now() : null,
      updatedAt: DateTime.now(),
    );

    if (newStatus) {
      _lastCompletedTask = currentTask;
    }

    await _db.updateTask(updatedTask);
    await loadTasks();
  }

  Future<bool> undoLastCompletion() async {
    if (_lastCompletedTask == null) return false;
    final taskToRevert = _lastCompletedTask!;
    _lastCompletedTask = null;

    final updated = taskToRevert.copyWith(
      isCompleted: false,
      completedAt: null,
      updatedAt: DateTime.now(),
    );
    await _db.updateTask(updated);
    await loadTasks();
    return true;
  }

  Future<void> deleteTask(String taskId) async {
    await _db.deleteTask(taskId);
    await loadTasks();
  }

  Future<void> reorderTasks(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final items = List<Task>.from(state);
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);

    state = items;
    for (int i = 0; i < items.length; i++) {
      final updated = items[i].copyWith(sortOrder: i);
      await _db.updateTask(updated);
    }
  }
}

final tasksProvider = StateNotifierProvider<TaskNotifier, List<Task>>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return TaskNotifier(db);
});

// --- Reminder Notifier & Provider ---
class ReminderNotifier extends StateNotifier<List<Reminder>> {
  final DatabaseService _db;
  final NotificationService _notifications;

  ReminderNotifier(this._db, this._notifications) : super([]) {
    loadReminders();
  }

  Future<void> loadReminders() async {
    final reminders = await _db.getReminders();
    state = reminders;
  }

  Future<void> addReminder(Reminder reminder) async {
    await _db.insertReminder(reminder);
    await _notifications.scheduleReminderNotification(reminder);
    await loadReminders();
  }

  Future<void> updateReminder(Reminder reminder) async {
    await _db.updateReminder(reminder);
    await _notifications.scheduleReminderNotification(reminder);
    await loadReminders();
  }

  Future<void> toggleReminderCompletion(String reminderId) async {
    final index = state.indexWhere((r) => r.id == reminderId);
    if (index == -1) return;

    final current = state[index];
    final updated = current.copyWith(isCompleted: !current.isCompleted);
    await _db.updateReminder(updated);
    if (updated.isCompleted) {
      await _notifications.cancelNotification(reminderId);
    }
    await loadReminders();
  }

  Future<void> snoozeReminder(String reminderId, Duration duration) async {
    final index = state.indexWhere((r) => r.id == reminderId);
    if (index == -1) return;

    final current = state[index];
    final snoozeTime = DateTime.now().add(duration);
    final updated = current.copyWith(
      snoozedUntil: snoozeTime,
      isCompleted: false,
    );
    await _db.updateReminder(updated);
    await _notifications.scheduleReminderNotification(updated);
    await loadReminders();
  }

  Future<void> deleteReminder(String reminderId) async {
    await _notifications.cancelNotification(reminderId);
    await _db.deleteReminder(reminderId);
    await loadReminders();
  }
}

final remindersProvider = StateNotifierProvider<ReminderNotifier, List<Reminder>>((ref) {
  final db = ref.watch(databaseServiceProvider);
  final notifications = ref.watch(notificationServiceProvider);
  return ReminderNotifier(db, notifications);
});

// --- Event Notifier & Provider ---
class EventNotifier extends StateNotifier<List<CalendarEvent>> {
  final DatabaseService _db;

  EventNotifier(this._db) : super([]) {
    loadEvents();
  }

  Future<void> loadEvents() async {
    final events = await _db.getEvents();
    state = events;
  }

  Future<void> addEvent(CalendarEvent event) async {
    await _db.insertEvent(event);
    await loadEvents();
  }

  Future<void> updateEvent(CalendarEvent event) async {
    await _db.updateEvent(event);
    await loadEvents();
  }

  Future<void> deleteEvent(String eventId) async {
    await _db.deleteEvent(eventId);
    await loadEvents();
  }
}

final eventsProvider = StateNotifierProvider<EventNotifier, List<CalendarEvent>>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return EventNotifier(db);
});

// --- Note Notifier & Provider ---
class NoteNotifier extends StateNotifier<List<Note>> {
  final DatabaseService _db;

  NoteNotifier(this._db) : super([]) {
    loadNotes();
  }

  Future<void> loadNotes() async {
    final notes = await _db.getNotes();
    state = notes;
  }

  Future<void> addNote(Note note) async {
    await _db.insertNote(note);
    await loadNotes();
  }

  Future<void> updateNote(Note note) async {
    await _db.updateNote(note);
    await loadNotes();
  }

  Future<void> togglePinNote(String noteId) async {
    final index = state.indexWhere((n) => n.id == noteId);
    if (index == -1) return;

    final current = state[index];
    final updated = current.copyWith(
      isPinned: !current.isPinned,
      updatedAt: DateTime.now(),
    );
    await _db.updateNote(updated);
    await loadNotes();
  }

  Future<void> deleteNote(String noteId) async {
    await _db.deleteNote(noteId);
    await loadNotes();
  }
}

final notesProvider = StateNotifierProvider<NoteNotifier, List<Note>>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return NoteNotifier(db);
});

// --- Journal Notifier & Provider ---
class JournalNotifier extends StateNotifier<List<JournalEntry>> {
  final DatabaseService _db;

  JournalNotifier(this._db) : super([]) {
    loadEntries();
  }

  Future<void> loadEntries() async {
    final entries = await _db.getJournalEntries();
    state = entries;
  }

  Future<void> saveEntry(JournalEntry entry) async {
    await _db.saveJournalEntry(entry);
    await loadEntries();
  }

  JournalEntry? getEntryForDate(DateTime date) {
    final dateString = "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    try {
      return state.firstWhere((e) => e.date == dateString);
    } catch (_) {
      return null;
    }
  }
}

final journalProvider = StateNotifierProvider<JournalNotifier, List<JournalEntry>>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return JournalNotifier(db);
});

// --- Settings Notifier & Provider ---
class SettingsNotifier extends StateNotifier<UserSettings> {
  final DatabaseService _db;

  SettingsNotifier(this._db) : super(UserSettings()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    final settings = await _db.getUserSettings();
    state = settings;
  }

  Future<void> updateSettings(UserSettings settings) async {
    state = settings;
    await _db.saveUserSettings(settings);
  }

  Future<void> toggleTheme(ThemeMode mode) async {
    final updated = state.copyWith(themeMode: mode);
    await updateSettings(updated);
  }

  Future<void> setAccentColor(String hex) async {
    final updated = state.copyWith(accentColorHex: hex);
    await updateSettings(updated);
  }

  Future<void> updateUserName(String name) async {
    final updated = state.copyWith(userName: name);
    await updateSettings(updated);
  }

  Future<void> setActiveWorkspace(String workspace) async {
    final updated = state.copyWith(activeWorkspace: workspace);
    await updateSettings(updated);
  }

  Future<void> addWorkspace(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || state.workspaces.contains(trimmed)) return;
    final updatedList = List<String>.from(state.workspaces)..add(trimmed);
    final updated = state.copyWith(workspaces: updatedList, activeWorkspace: trimmed);
    await updateSettings(updated);
  }

  Future<void> deleteWorkspace(String name) async {
    if (name == 'Queue' || state.workspaces.length <= 1) return;
    final updatedList = List<String>.from(state.workspaces)..remove(name);
    final newActive = state.activeWorkspace == name ? 'Queue' : state.activeWorkspace;
    final updated = state.copyWith(workspaces: updatedList, activeWorkspace: newActive);
    await updateSettings(updated);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, UserSettings>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return SettingsNotifier(db);
});

// --- Workspace Providers ---
final activeWorkspaceProvider = Provider<String>((ref) {
  return ref.watch(settingsProvider).activeWorkspace;
});

final workspacesProvider = Provider<List<String>>((ref) {
  return ref.watch(settingsProvider).workspaces;
});

// --- Selected Date Provider for Calendar & Agenda sync ---
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

// --- Activity Summary Provider ---
class ActivitySummary {
  final int totalTasksToday;
  final int completedTasksToday;
  final int pendingTasksToday;
  final int upcomingRemindersToday;
  final int notesCreatedToday;
  final double completionRateToday;
  final List<int> past7DaysCompletions;

  ActivitySummary({
    required this.totalTasksToday,
    required this.completedTasksToday,
    required this.pendingTasksToday,
    required this.upcomingRemindersToday,
    required this.notesCreatedToday,
    required this.completionRateToday,
    required this.past7DaysCompletions,
  });

  int get currentStreakDays {
    int streak = 0;
    for (int i = past7DaysCompletions.length - 1; i >= 0; i--) {
      if (past7DaysCompletions[i] > 0) {
        streak++;
      } else if (i == past7DaysCompletions.length - 1 && completedTasksToday == 0) {
        continue;
      } else {
        break;
      }
    }
    return streak == 0 && completedTasksToday > 0 ? 1 : streak;
  }
}

final activitySummaryProvider = Provider<ActivitySummary>((ref) {
  final tasks = ref.watch(tasksProvider);
  final reminders = ref.watch(remindersProvider);
  final notes = ref.watch(notesProvider);

  final now = DateTime.now();
  final todayTasks = tasks.where((t) => t.isDueToday).toList();
  final completedToday = todayTasks.where((t) => t.isCompleted).length;
  final pendingToday = todayTasks.where((t) => !t.isCompleted).length;
  final remindersToday = reminders.where((r) => r.isDueToday && !r.isCompleted).length;

  final notesToday = notes.where((n) {
    return n.createdAt.year == now.year &&
        n.createdAt.month == now.month &&
        n.createdAt.day == now.day;
  }).length;

  final total = todayTasks.length;
  final rate = total > 0 ? (completedToday / total) : 0.0;

  // Calculate past 7 days completed tasks
  final List<int> completions = [];
  for (int i = 6; i >= 0; i--) {
    final day = now.subtract(Duration(days: i));
    final count = tasks.where((t) {
      if (!t.isCompleted || t.completedAt == null) return false;
      return t.completedAt!.year == day.year &&
          t.completedAt!.month == day.month &&
          t.completedAt!.day == day.day;
    }).length;
    completions.add(count);
  }

  return ActivitySummary(
    totalTasksToday: total,
    completedTasksToday: completedToday,
    pendingTasksToday: pendingToday,
    upcomingRemindersToday: remindersToday,
    notesCreatedToday: notesToday,
    completionRateToday: rate,
    past7DaysCompletions: completions,
  );
});
