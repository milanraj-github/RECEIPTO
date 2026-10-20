import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receipto/features/notifications/domain/models/notification_settings_state.dart';

final notificationSettingsServiceProvider = Provider<NotificationSettingsService>((ref) {
  return NotificationSettingsService();
});

class NotificationSettingsService {
  static const String _keyPrefix = 'warranty_notif_';
  
  static const String _keyNotificationsEnabled = '${_keyPrefix}enabled';
  static const String _keyReminderHour = '${_keyPrefix}hour';
  static const String _keyReminderMinute = '${_keyPrefix}minute';
  static const String _keyEmailNotificationsEnabled = '${_keyPrefix}email_enabled';

  static const String _key30Days = '${_keyPrefix}30_days';
  static const String _key15Days = '${_keyPrefix}15_days';
  static const String _key7Days = '${_keyPrefix}7_days';
  static const String _key1Day = '${_keyPrefix}1_day';
  static const String _keyOnExpiry = '${_keyPrefix}on_expiry';

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificationsEnabled, enabled);
  }

  Future<void> setReminderTime(int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyReminderHour, hour);
    await prefs.setInt(_keyReminderMinute, minute);
  }

  Future<void> setEmailNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEmailNotificationsEnabled, enabled);
  }

  Future<void> setRemindersEnabled({
    required bool remind30Days,
    required bool remind15Days,
    required bool remind7Days,
    required bool remind1Day,
    required bool remindOnExpiry,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key30Days, remind30Days);
    await prefs.setBool(_key15Days, remind15Days);
    await prefs.setBool(_key7Days, remind7Days);
    await prefs.setBool(_key1Day, remind1Day);
    await prefs.setBool(_keyOnExpiry, remindOnExpiry);
  }

  Future<NotificationSettingsState> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return NotificationSettingsState(
      notificationsEnabled: prefs.getBool(_keyNotificationsEnabled) ?? true,
      reminderHour: prefs.getInt(_keyReminderHour) ?? 9,
      reminderMinute: prefs.getInt(_keyReminderMinute) ?? 0,
      emailNotificationsEnabled: prefs.getBool(_keyEmailNotificationsEnabled) ?? true,
      reminderTypes: {
        30: prefs.getBool(_key30Days) ?? true,
        15: prefs.getBool(_key15Days) ?? true,
        7: prefs.getBool(_key7Days) ?? true,
        1: prefs.getBool(_key1Day) ?? true,
        0: prefs.getBool(_keyOnExpiry) ?? true,
      },
    );
  }

  Future<void> updateSingleSetting(int days, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    switch (days) {
      case 30:
        await prefs.setBool(_key30Days, enabled);
        break;
      case 15:
        await prefs.setBool(_key15Days, enabled);
        break;
      case 7:
        await prefs.setBool(_key7Days, enabled);
        break;
      case 1:
        await prefs.setBool(_key1Day, enabled);
        break;
      case 0:
        await prefs.setBool(_keyOnExpiry, enabled);
        break;
    }
  }
}
