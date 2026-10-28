import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../database/database_service.dart';
import '../../models/reminder.dart';
import '../../models/task.dart';
import '../../models/user_settings.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  bool _hasPermission = false;
  Timer? _deadlineWatcherTimer;
  final Set<String> _alertedNotificationKeys = {};

  NotificationService._internal();

  bool get hasPermission => _hasPermission;
  bool get isInitialized => _isInitialized;

  // Notification Channel Definitions
  static const String channelAlerts = 'workbench_alerts_channel';
  static const String channelTasks = 'workbench_tasks_channel';
  static const String channelReminders = 'workbench_reminders_channel';
  static const String channelGeneral = 'workbench_general_channel';

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const linuxSettings = LinuxInitializationSettings(defaultActionName: 'Open Workbench');

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
        linux: linuxSettings,
      );

      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification clicked: ${response.payload}');
        },
      );

      // Create high-priority notification channels on Android
      final androidPlatform = _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlatform != null) {
        await androidPlatform.createNotificationChannel(
          const AndroidNotificationChannel(
            channelAlerts,
            'Alerts & Deadlines',
            description: 'Critical deadline alerts and immediate notifications',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );

        await androidPlatform.createNotificationChannel(
          const AndroidNotificationChannel(
            channelTasks,
            'Tasks & Goals',
            description: 'Task assignments, milestones, and status alerts',
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
        );

        await androidPlatform.createNotificationChannel(
          const AndroidNotificationChannel(
            channelReminders,
            'Reminders & Habits',
            description: 'Gentle habit and time-based reminders',
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
        );

        // Auto request permission on startup
        final granted = await androidPlatform.requestNotificationsPermission();
        _hasPermission = granted ?? true;
      } else {
        _hasPermission = true;
      }

      _isInitialized = true;

      // Initialize timezone data
      tz.initializeTimeZones();
      final locationName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(locationName));
    } catch (e) {
      debugPrint('Notification initialization fallback: $e');
      _isInitialized = false;
    }
  }

  Future<bool> requestPermissions() async {
    if (!_isInitialized) await initialize();

    try {
      final androidPlatform = _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlatform != null) {
        final granted = await androidPlatform.requestNotificationsPermission();
        _hasPermission = granted ?? true;
        return _hasPermission;
      }

      final iosPlatform = _notificationsPlugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (iosPlatform != null) {
        final granted = await iosPlatform.requestPermissions(alert: true, badge: true, sound: true);
        _hasPermission = granted ?? false;
        return _hasPermission;
      }

      _hasPermission = true;
      return true;
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
      _hasPermission = false;
      return false;
    }
  }

  /// Pushes an instant alert for high priority items or approaching deadlines
  Future<void> showDeadlineAlert({
    required String title,
    required String body,
    String? payload,
    int? notificationId,
  }) async {
    if (!_isInitialized) await initialize();

    final id = notificationId ?? (DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF);

    const androidDetails = AndroidNotificationDetails(
      channelAlerts,
      'Alerts & Deadlines',
      channelDescription: 'Critical deadline alerts and immediate notifications',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
    );

    const details = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(id, title, body, details, payload: payload);
  }

  /// Schedules a task notification at the task's due date+time via zonedSchedule.
  /// If the task has no dueDate/dueTime, or the datetime is in the past, no notification is shown.
  Future<void> showTaskNotification(Task task, {String? customTitle, String? customMessage}) async {
    if (!_isInitialized) await initialize();

    // Only schedule if the task has a future due date+time
    final deadline = task.deadlineDateTime;
    if (deadline == null) return; // No date set — skip silently
    if (!deadline.isAfter(DateTime.now())) return; // Past — skip silently

    final id = (task.id.hashCode & 0x7FFFFFFF);
    final title = customTitle ?? 'Task: ${task.title}';
    final dueInfo = task.dueDate != null
        ? 'Due: ${task.dueDate!.day}/${task.dueDate!.month}${task.dueTime != null ? ' at ${task.dueTime!.formatDirect()}' : ''}'
        : 'Priority: ${task.priority.label}';
    final body = customMessage ?? '${task.category} · $dueInfo';

    const androidDetails = AndroidNotificationDetails(
      channelTasks,
      'Tasks & Goals',
      channelDescription: 'Task assignments, milestones, and status alerts',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
    );

    const details = NotificationDetails(android: androidDetails);
    await scheduleExactNotification(
      id: id,
      title: title,
      body: body,
      scheduledTime: deadline,
      details: details,
      payload: 'task:${task.id}',
    );
  }

  /// Schedules a reminder notification via zonedSchedule.
  /// If the target time is in the past, the notification is silently skipped.
  Future<void> scheduleReminderNotification(Reminder reminder) async {
    if (!_isInitialized) await initialize();

    final id = (reminder.id.hashCode & 0x7FFFFFFF);
    final targetTime = reminder.snoozedUntil ?? reminder.scheduledAt;
    final timeStr = '${targetTime.hour.toString().padLeft(2, '0')}:${targetTime.minute.toString().padLeft(2, '0')}';

    const androidDetails = AndroidNotificationDetails(
      channelReminders,
      'Reminders & Habits',
      channelDescription: 'Gentle habit and time-based reminders',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await scheduleExactNotification(
      id: id,
      title: 'Reminder: ${reminder.title}',
      body: 'Scheduled alert for $timeStr ${reminder.isRecurring ? '(Recurring)' : ''}',
      scheduledTime: targetTime,
      details: notificationDetails,
      payload: 'reminder:${reminder.id}',
    );
  }

  /// Schedules an exact notification at [scheduledTime] using zonedSchedule.
  /// Silently no-ops if [scheduledTime] is in the past.
  Future<void> scheduleExactNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required NotificationDetails details,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();
    if (!scheduledTime.isAfter(DateTime.now())) {
      debugPrint('Skipping notification (past time): $title at $scheduledTime');
      return;
    }
    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
      debugPrint('Scheduled notification "$title" for $scheduledTime');
    } catch (e) {
      debugPrint('Error scheduling exact notification: $e');
    }
  }

  Future<void> cancelNotification(String entityId) async {
    if (!_isInitialized) return;
    final id = entityId.hashCode & 0x7FFFFFFF;
    await _notificationsPlugin.cancel(id);
    clearAlertKey(entityId);
  }

  void clearAlertKey(String entityId) {
    _alertedNotificationKeys.removeWhere((k) => k.startsWith('${entityId}_'));
  }

  /// Starts the active deadline and timeline watcher without blasting notifications on app open
  void startDeadlineWatcher(DatabaseService db, UserSettings Function() getSettings) {
    _deadlineWatcherTimer?.cancel();
    // Initial check in silent seed mode so opening the app NEVER pushes immediate notifications
    checkApproachingDeadlines(db, getSettings(), isInitialSeed: true);
    // Periodic heartbeat check every 30 seconds
    _deadlineWatcherTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      checkApproachingDeadlines(db, getSettings(), isInitialSeed: false);
    });
  }

  /// Checks approaching deadlines for tasks, reminders, and timeline events.
  /// If [isInitialSeed] is true (e.g. app just opened), it records keys into
  /// [_alertedNotificationKeys] without displaying alerts so opening the app never spams the user.
  Future<void> checkApproachingDeadlines(
    DatabaseService db,
    UserSettings settings, {
    bool isInitialSeed = false,
  }) async {
    if (!settings.notificationsEnabled) return;
    if (!_isInitialized) await initialize();

    final now = DateTime.now();
    final leadDuration = settings.deadlineLeadDuration;

    try {
      // 1. Check Tasks
      final tasks = await db.getTasks();
      for (final task in tasks) {
        if (task.isCompleted || task.dueDate == null) continue;
        final deadline = task.deadlineDateTime;
        if (deadline == null) continue;

        final diff = deadline.difference(now);
        final leadTimeWindow = leadDuration.inMinutes > 0 ? leadDuration : const Duration(minutes: 15);

        // Alert A: Deadline ending soon within user-configured lead window
        if (diff > Duration.zero && diff <= leadTimeWindow) {
          final alertKey = '${task.id}_soon_${deadline.toIso8601String().substring(0, 16)}';
          if (!_alertedNotificationKeys.contains(alertKey)) {
            _alertedNotificationKeys.add(alertKey);
            if (!isInitialSeed) {
              final remainingStr = _formatRemaining(diff);
              await showDeadlineAlert(
                title: '⏳ Deadline Ending Soon: ${task.title}',
                body: 'Ending in $remainingStr (by ${task.dueTime != null ? task.dueTime!.formatDirect() : "today"}) · ${task.category}',
                payload: 'task:${task.id}',
              );
            }
          }
        }

        // Alert B: Timeline deadline has arrived / come to an end
        if (diff <= Duration.zero && diff >= const Duration(hours: -2)) {
          final alertKey = '${task.id}_due_${deadline.toIso8601String().substring(0, 16)}';
          if (!_alertedNotificationKeys.contains(alertKey)) {
            _alertedNotificationKeys.add(alertKey);
            if (!isInitialSeed) {
              await showDeadlineAlert(
                title: '🚨 Deadline Reached: ${task.title}',
                body: 'The timeline for this task has ended. Tap to complete or reschedule.',
                payload: 'task:${task.id}',
              );
            }
          }
        }
      }

      // 2. Check Reminders
      final reminders = await db.getReminders();
      for (final reminder in reminders) {
        if (reminder.isCompleted) continue;
        final triggerTime = reminder.effectiveDueTime;
        final diff = triggerTime.difference(now);
        final leadTimeWindow = leadDuration.inMinutes > 0 ? leadDuration : const Duration(minutes: 15);

        if (diff > Duration.zero && diff <= leadTimeWindow) {
          final alertKey = '${reminder.id}_soon_${triggerTime.toIso8601String().substring(0, 16)}';
          if (!_alertedNotificationKeys.contains(alertKey)) {
            _alertedNotificationKeys.add(alertKey);
            if (!isInitialSeed) {
              await showDeadlineAlert(
                title: '⏰ Reminder Soon: ${reminder.title}',
                body: 'Scheduled in ${_formatRemaining(diff)}',
                payload: 'reminder:${reminder.id}',
              );
            }
          }
        }

        if (diff <= Duration.zero && diff >= const Duration(minutes: -15)) {
          final alertKey = '${reminder.id}_due_${triggerTime.toIso8601String().substring(0, 16)}';
          if (!_alertedNotificationKeys.contains(alertKey)) {
            _alertedNotificationKeys.add(alertKey);
            if (!isInitialSeed) {
              await showDeadlineAlert(
                title: '⏰ Reminder: ${reminder.title}',
                body: 'Scheduled time reached right now.',
                payload: 'reminder:${reminder.id}',
              );
            }
          }
        }
      }

      // 3. Check Calendar Events
      final events = await db.getEvents();
      for (final event in events) {
        final diff = event.endTime.difference(now);
        final leadTimeWindow = leadDuration.inMinutes > 0 ? leadDuration : const Duration(minutes: 15);

        if (diff > Duration.zero && diff <= leadTimeWindow) {
          final alertKey = '${event.id}_soon_${event.endTime.toIso8601String().substring(0, 16)}';
          if (!_alertedNotificationKeys.contains(alertKey)) {
            _alertedNotificationKeys.add(alertKey);
            if (!isInitialSeed) {
              await showDeadlineAlert(
                title: '📅 Event Finishing Soon: ${event.title}',
                body: 'Ends in ${_formatRemaining(diff)} · ${event.location ?? "Calendar"}',
                payload: 'event:${event.id}',
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error running deadline watcher: $e');
    }
  }

  /// Sends a simulated test deadline notification reflecting custom user lead time
  Future<void> triggerTestDeadlineAlert({int leadHours = 0, int leadMinutes = 30}) async {
    final leadText = leadHours > 0
        ? (leadMinutes > 0 ? '$leadHours hr $leadMinutes min' : '$leadHours hr')
        : '$leadMinutes min';

    await showDeadlineAlert(
      title: '⏳ Deadline Ending Soon: Project Review (Sample)',
      body: 'You are set to be notified $leadText earlier before deadlines end. Alerts are active!',
    );
  }

  String _formatRemaining(Duration diff) {
    if (diff.inHours > 0) {
      final mins = diff.inMinutes % 60;
      return mins > 0 ? '${diff.inHours}h ${mins}m' : '${diff.inHours}h';
    }
    if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m';
    }
    return '${diff.inSeconds}s';
  }

  Future<void> showQuickNotification(String title, String body) async {
    if (!_isInitialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      channelGeneral,
      'General Updates',
      channelDescription: 'General updates and daily reflections',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(0, title, body, details);
  }
}

extension TimeOfDayFormat on TimeOfDay {
  String formatDirect() {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
