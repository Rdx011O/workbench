import 'package:flutter/material.dart';

class UserSettings {
  final String userName;
  final ThemeMode themeMode;
  final String accentColorHex;
  final bool weekStartMonday;
  final bool timeFormat24Hour;
  final bool notificationsEnabled;
  final TimeOfDay defaultReminderTime;
  final bool voiceInputEnabled;

  UserSettings({
    this.userName = 'Aadix',
    this.themeMode = ThemeMode.light,
    this.accentColorHex = 'C77D5B', // Subdued Terracotta
    this.weekStartMonday = true,
    this.timeFormat24Hour = false,
    this.notificationsEnabled = true,
    this.defaultReminderTime = const TimeOfDay(hour: 9, minute: 0),
    this.voiceInputEnabled = true,
  });

  UserSettings copyWith({
    String? userName,
    ThemeMode? themeMode,
    String? accentColorHex,
    bool? weekStartMonday,
    bool? timeFormat24Hour,
    bool? notificationsEnabled,
    TimeOfDay? defaultReminderTime,
    bool? voiceInputEnabled,
  }) {
    return UserSettings(
      userName: userName ?? this.userName,
      themeMode: themeMode ?? this.themeMode,
      accentColorHex: accentColorHex ?? this.accentColorHex,
      weekStartMonday: weekStartMonday ?? this.weekStartMonday,
      timeFormat24Hour: timeFormat24Hour ?? this.timeFormat24Hour,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      defaultReminderTime: defaultReminderTime ?? this.defaultReminderTime,
      voiceInputEnabled: voiceInputEnabled ?? this.voiceInputEnabled,
    );
  }

  Map<String, String> toPreferencesMap() {
    return {
      'user_name': userName,
      'theme_mode': themeMode.name,
      'accent_color': accentColorHex,
      'week_start_monday': weekStartMonday ? '1' : '0',
      'time_format_24h': timeFormat24Hour ? '1' : '0',
      'notifications_enabled': notificationsEnabled ? '1' : '0',
      'reminder_hour': defaultReminderTime.hour.toString(),
      'reminder_minute': defaultReminderTime.minute.toString(),
      'voice_enabled': voiceInputEnabled ? '1' : '0',
    };
  }

  factory UserSettings.fromPreferencesMap(Map<String, String> map) {
    ThemeMode parseTheme(String? val) {
      if (val == 'dark') return ThemeMode.dark;
      if (val == 'system') return ThemeMode.system;
      return ThemeMode.light;
    }

    return UserSettings(
      userName: map['user_name'] ?? 'Aadix',
      themeMode: parseTheme(map['theme_mode']),
      accentColorHex: map['accent_color'] ?? 'C77D5B',
      weekStartMonday: (map['week_start_monday'] ?? '1') == '1',
      timeFormat24Hour: (map['time_format_24h'] ?? '0') == '1',
      notificationsEnabled: (map['notifications_enabled'] ?? '1') == '1',
      defaultReminderTime: TimeOfDay(
        hour: int.tryParse(map['reminder_hour'] ?? '9') ?? 9,
        minute: int.tryParse(map['reminder_minute'] ?? '0') ?? 0,
      ),
      voiceInputEnabled: (map['voice_enabled'] ?? '1') == '1',
    );
  }
}
