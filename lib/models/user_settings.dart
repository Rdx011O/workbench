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
  final String activeWorkspace;
  final List<String> workspaces;

  UserSettings({
    this.userName = 'Aadix',
    this.themeMode = ThemeMode.light,
    this.accentColorHex = '2C2638', // Slate Aubergine
    this.weekStartMonday = true,
    this.timeFormat24Hour = false,
    this.notificationsEnabled = true,
    this.defaultReminderTime = const TimeOfDay(hour: 9, minute: 0),
    this.voiceInputEnabled = true,
    this.activeWorkspace = 'Workbench',
    this.workspaces = const ['Workbench', 'Personal', 'Work', 'Studies', 'Creative Studio'],
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
    String? activeWorkspace,
    List<String>? workspaces,
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
      activeWorkspace: activeWorkspace ?? this.activeWorkspace,
      workspaces: workspaces ?? this.workspaces,
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
      'active_workspace': activeWorkspace,
      'workspaces': workspaces.join('|||'),
    };
  }

  factory UserSettings.fromPreferencesMap(Map<String, String> map) {
    ThemeMode parseTheme(String? val) {
      if (val == 'dark') return ThemeMode.dark;
      if (val == 'system') return ThemeMode.system;
      return ThemeMode.light;
    }

    final rawWorkspaces = map['workspaces'];
    final parsedWorkspaces = (rawWorkspaces != null && rawWorkspaces.isNotEmpty)
        ? rawWorkspaces.split('|||').where((s) => s.trim().isNotEmpty).map((w) => w == 'Queue' ? 'Workbench' : w).toList()
        : const ['Workbench', 'Personal', 'Work', 'Studies', 'Creative Studio'];

    final active = map['active_workspace'];
    final resolvedActive = (active == null || active == 'Queue' || active.isEmpty) ? 'Workbench' : active;

    return UserSettings(
      userName: map['user_name'] ?? 'Aadix',
      themeMode: parseTheme(map['theme_mode']),
      accentColorHex: map['accent_color'] ?? '2C2638',
      weekStartMonday: (map['week_start_monday'] ?? '1') == '1',
      timeFormat24Hour: (map['time_format_24h'] ?? '0') == '1',
      notificationsEnabled: (map['notifications_enabled'] ?? '1') == '1',
      defaultReminderTime: TimeOfDay(
        hour: int.tryParse(map['reminder_hour'] ?? '9') ?? 9,
        minute: int.tryParse(map['reminder_minute'] ?? '0') ?? 0,
      ),
      voiceInputEnabled: (map['voice_enabled'] ?? '1') == '1',
      activeWorkspace: resolvedActive,
      workspaces: parsedWorkspaces.isEmpty ? const ['Workbench'] : parsedWorkspaces,
    );
  }
}
