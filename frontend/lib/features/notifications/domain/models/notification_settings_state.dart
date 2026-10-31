class NotificationSettingsState {
  final bool notificationsEnabled;
  final int reminderHour;
  final int reminderMinute;
  final bool emailNotificationsEnabled;
  final Map<int, bool> reminderTypes;

  NotificationSettingsState({
    required this.notificationsEnabled,
    required this.reminderHour,
    required this.reminderMinute,
    required this.emailNotificationsEnabled,
    required this.reminderTypes,
  });

  NotificationSettingsState copyWith({
    bool? notificationsEnabled,
    int? reminderHour,
    int? reminderMinute,
    bool? emailNotificationsEnabled,
    Map<int, bool>? reminderTypes,
  }) {
    return NotificationSettingsState(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      emailNotificationsEnabled: emailNotificationsEnabled ?? this.emailNotificationsEnabled,
      reminderTypes: reminderTypes ?? this.reminderTypes,
    );
  }
}
