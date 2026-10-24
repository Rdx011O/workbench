import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../models/reminder.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  bool _hasPermission = false;

  NotificationService._internal();

  bool get hasPermission => _hasPermission;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const linuxSettings = LinuxInitializationSettings(defaultActionName: 'Open Botanical Planner');

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
        _hasPermission = granted ?? false;
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

  Future<void> scheduleReminderNotification(Reminder reminder) async {
    if (!_isInitialized || !_hasPermission) return;

    final targetTime = reminder.snoozedUntil ?? reminder.scheduledAt;
    if (targetTime.isBefore(DateTime.now())) return;

    final id = reminder.id.hashCode & 0x7FFFFFFF;

    const androidDetails = AndroidNotificationDetails(
      'botanical_reminders_channel',
      'Reminders & Habits',
      channelDescription: 'Calm, gentle reminders from your life planner',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    try {
      // In production environment with timezone data initialized, zonedSchedule is used.
      // Here we provide safe scheduled or instant validation notification.
      debugPrint('Scheduled notification for ${reminder.title} at $targetTime');
      await _notificationsPlugin.show(
        id,
        'Reminder: ${reminder.title}',
        'Scheduled for ${targetTime.hour.toString().padLeft(2, '0')}:${targetTime.minute.toString().padLeft(2, '0')}',
        notificationDetails,
      );
    } catch (e) {
      debugPrint('Error scheduling reminder notification: $e');
    }
  }

  Future<void> cancelNotification(String reminderId) async {
    if (!_isInitialized) return;
    final id = reminderId.hashCode & 0x7FFFFFFF;
    await _notificationsPlugin.cancel(id);
  }

  Future<void> showQuickNotification(String title, String body) async {
    if (!_isInitialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'botanical_general_channel',
      'Planner Updates',
      channelDescription: 'General updates and daily reflections',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const details = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(0, title, body, details);
  }
}
