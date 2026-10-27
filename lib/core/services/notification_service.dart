import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../models/reminder.dart';
import '../../models/task.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  bool _hasPermission = false;

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

  /// Pushes a task notification (creation, deadline reminder, or status change)
  Future<void> showTaskNotification(Task task, {String? customTitle, String? customMessage}) async {
    if (!_isInitialized) await initialize();

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
    await _notificationsPlugin.show(id, title, body, details, payload: 'task:${task.id}');
  }

  /// Schedules or immediately notifies for a reminder/habit
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

    try {
      debugPrint('Notification pushed for reminder: ${reminder.title} at $timeStr');
      await _notificationsPlugin.show(
        id,
        'Reminder: ${reminder.title}',
        'Scheduled alert for $timeStr ${reminder.isRecurring ? '(Recurring)' : ''}',
        notificationDetails,
        payload: 'reminder:${reminder.id}',
      );
    } catch (e) {
      debugPrint('Error scheduling reminder notification: $e');
    }
  }

  Future<void> cancelNotification(String entityId) async {
    if (!_isInitialized) return;
    final id = entityId.hashCode & 0x7FFFFFFF;
    await _notificationsPlugin.cancel(id);
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
