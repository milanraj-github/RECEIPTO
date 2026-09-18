import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:receipto/features/warranty/domain/models/warranty_model.dart';
import 'package:receipto/features/notifications/data/services/notification_settings_service.dart';
import 'package:receipto/core/services/notification_service.dart';
import 'package:receipto/core/services/warranty_database_service.dart';
import 'package:receipto/core/services/receipt_database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

final notificationSchedulerProvider = Provider<NotificationScheduler>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  final settingsService = ref.watch(notificationSettingsServiceProvider);
  final warrantyDb = ref.watch(warrantyDatabaseServiceProvider);
  final receiptDb = ref.watch(receiptDatabaseServiceProvider);
  return NotificationScheduler(notificationService, settingsService, warrantyDb, receiptDb);
});

class NotificationScheduler {
  final NotificationService _notificationService;
  final NotificationSettingsService _settingsService;
  final WarrantyDatabaseService _warrantyDb;
  final ReceiptDatabaseService _receiptDb;
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  NotificationScheduler(
    this._notificationService,
    this._settingsService,
    this._warrantyDb,
    this._receiptDb,
  ) {
    tz_data.initializeTimeZones();
    _initTimezone();
  }

  Future<void> _initTimezone() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? tzName = prefs.getString('device_timezone');
      if (tzName == null) {
        final tzInfo = await FlutterTimezone.getLocalTimezone();
        tzName = tzInfo.identifier;
        await prefs.setString('device_timezone', tzName);
      }
      tz.setLocalLocation(tz.getLocation(tzName));
      debugPrint('[NotificationScheduler] Timezone database initialized to: "$tzName".');
    } catch (e) {
      debugPrint('[NotificationScheduler] Timezone lookup failed inside constructor: $e');
    }
  }

  /// Cancels all pending local scheduled notifications.
  Future<void> cancelAll() async {
    try {
      await _notificationsPlugin.cancelAll();
      debugPrint('[NotificationScheduler] All local scheduled notifications cancelled.');
    } catch (e) {
      debugPrint('[NotificationScheduler] cancelAll failed: $e');
    }
  }

  int calculateNotificationId(String warrantyId, int daysBefore) {
    return ((warrantyId.hashCode * 31) + daysBefore) & 0x7FFFFFFF;
  }

  int calculateGroupedNotificationId(tz.TZDateTime scheduledDate, int daysBefore) {
    final yyyymmdd = (scheduledDate.year * 10000) + (scheduledDate.month * 100) + scheduledDate.day;
    return ((yyyymmdd.hashCode * 37) + daysBefore) & 0x7FFFFFFF;
  }

  Future<void> cancelWarrantyNotifications(String warrantyId) async {
    debugPrint('Cancelling notifications for warranty: $warrantyId');
    final daysList = [30, 15, 7, 1, 0];
    for (final days in daysList) {
      final id = calculateNotificationId(warrantyId, days);
      await _notificationService.cancelNotification(id);
    }
  }

  Future<void> syncWarranties(List<WarrantyModel> activeWarranties) async {
    debugPrint('[Sync] App startup synchronization: Syncing ${activeWarranties.length} warranties...');
    try {
      final settings = await _settingsService.getSettings();
      final pendingRequests = await _notificationsPlugin.pendingNotificationRequests();
      final pendingIds = pendingRequests.map((r) => r.id).toSet();

      final Set<int> expectedIds = {};
      final Map<int, _PendingNotificationData> toSchedule = {};

      final now = tz.TZDateTime.now(tz.local);
      debugPrint('Selected reminder time: ${settings.reminderHour}:${settings.reminderMinute}');
      debugPrint('Current local time: $now');
      debugPrint('Timezone: ${tz.local.name}');

      // Group reminders by scheduled date and time
      final Map<int, List<_ReminderItem>> groupedReminders = {};

      if (settings.notificationsEnabled) {
        for (final w in activeWarranties) {
          final date = DateTime.tryParse(w.expiryDate);
          if (date == null) {
            debugPrint('[Sync] Skipping warranty ${w.id} due to invalid expiry date: ${w.expiryDate}');
            continue;
          }

          final expiryScheduledDate = tz.TZDateTime(
            tz.local,
            date.year,
            date.month,
            date.day,
            settings.reminderHour,
            settings.reminderMinute,
          );

          final daysList = [30, 15, 7, 1, 0];
          for (final days in daysList) {
            final isEnabled = settings.reminderTypes[days] ?? true;
            if (!isEnabled) continue;

            final reminderDate = expiryScheduledDate.subtract(Duration(days: days));
            if (reminderDate.isAfter(now)) {
              final key = reminderDate.millisecondsSinceEpoch;
              groupedReminders.putIfAbsent(key, () => []);
              groupedReminders[key]!.add(_ReminderItem(
                warranty: w,
                daysBefore: days,
                scheduledDate: reminderDate,
              ));
            }
          }
        }
      }

      // Build expected notification list and map them to single or grouped notifications
      for (final entry in groupedReminders.entries) {
        final timeMs = entry.key;
        final items = entry.value;
        final scheduledDate = tz.TZDateTime.fromMillisecondsSinceEpoch(tz.local, timeMs);

        if (items.length == 1) {
          // Single-product reminder
          final item = items.first;
          final w = item.warranty;
          final days = item.daysBefore;
          final id = calculateNotificationId(w.id ?? '', days);
          expectedIds.add(id);

          if (!pendingIds.contains(id)) {
            final details = _getNotificationContent(w.productName, days);
            final payload = jsonEncode({
              'receiptId': w.receiptId,
              'warrantyId': w.id,
              'productName': w.productName,
              'isGrouped': false,
            });
            debugPrint('Computed scheduled time: $scheduledDate');
            debugPrint('Notification ID: $id');
            toSchedule[id] = _PendingNotificationData(
              id: id,
              title: details.title,
              body: details.body,
              scheduledDate: scheduledDate,
              payload: payload,
            );
          }
        } else {
          // Grouped reminder
          items.sort((a, b) => a.warranty.productName.compareTo(b.warranty.productName));
          final days = items.first.daysBefore;
          final id = calculateGroupedNotificationId(scheduledDate, days);
          expectedIds.add(id);

          if (!pendingIds.contains(id)) {
            final count = items.length;
            final String title = 'Warranty Reminder';
            final String body;

            if (days == 30) {
              body = '$count products expire in 30 days. Tap to view details.';
            } else if (days == 15) {
              body = '$count products expire in 15 days. Tap to view details.';
            } else if (days == 7) {
              body = '$count products expire in one week. Tap to view details.';
            } else if (days == 1) {
              body = '$count products expire tomorrow. Tap to view details.';
            } else if (days == 0) {
              body = '$count products expire today. Tap to view details.';
            } else {
              body = '$count products expire in $days days. Tap to view details.';
            }

            final payload = jsonEncode({
              'isGrouped': true,
              'warrantyIds': items.map((it) => it.warranty.id).toList(),
              'daysBefore': days,
            });

            debugPrint('Computed scheduled time: $scheduledDate');
            debugPrint('Notification ID: $id');
            toSchedule[id] = _PendingNotificationData(
              id: id,
              title: title,
              body: body,
              scheduledDate: scheduledDate,
              payload: payload,
            );
          }
        }
      }

      // 1. Cancel obsolete notifications
      final activeWarrIds = activeWarranties.map((w) => w.id ?? '').toSet();
      for (final r in pendingRequests) {
        bool belongsToOurApp = false;
        final isExpected = expectedIds.contains(r.id);

        for (final wId in activeWarrIds) {
          for (final days in [30, 15, 7, 1, 0]) {
            if (r.id == calculateNotificationId(wId, days)) {
              belongsToOurApp = true;
              break;
            }
          }
          if (belongsToOurApp) break;
        }

        if (!belongsToOurApp && r.payload != null) {
          try {
            final decoded = jsonDecode(r.payload!) as Map<String, dynamic>;
            if (decoded.containsKey('isGrouped') || decoded.containsKey('warrantyId')) {
              belongsToOurApp = true;
            }
          } catch (_) {}
        }

        if (belongsToOurApp && !isExpected) {
          debugPrint('[Sync] Cancelling obsolete/disabled scheduled notification ID: ${r.id}');
          await _notificationService.cancelNotification(r.id);
        }
      }

      // 2. Schedule missing expected notifications
      if (toSchedule.isNotEmpty) {
        debugPrint('[Sync] Scheduling ${toSchedule.length} missing warranty notifications...');
        const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
          'warranty_reminders_channel',
          'Warranty Reminders',
          channelDescription: 'Notifications for warranty expiration alerts',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
        );

        const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

        const NotificationDetails platformDetails = NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        );

        for (final data in toSchedule.values) {
          try {
            await _notificationsPlugin.zonedSchedule(
              id: data.id,
              title: data.title,
              body: data.body,
              scheduledDate: data.scheduledDate,
              notificationDetails: platformDetails,
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
              payload: data.payload,
            );
            debugPrint('Alarm scheduled — ID: ${data.id} at ${data.scheduledDate}');
          } catch (e) {
            final errStr = e.toString();
            if (errStr.contains('SecurityException') || errStr.contains('exact alarm')) {
              debugPrint('[Sync] Exact alarm permission not granted. Falling back to inexact scheduling...');
              try {
                await _notificationsPlugin.zonedSchedule(
                  id: data.id,
                  title: data.title,
                  body: data.body,
                  scheduledDate: data.scheduledDate,
                  notificationDetails: platformDetails,
                  androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
                  payload: data.payload,
                );
                debugPrint('Alarm scheduled (Inexact fallback) — ID: ${data.id} at ${data.scheduledDate}');
              } catch (ex) {
                debugPrint('[Sync] Error scheduling inexact notification: $ex');
              }
            } else {
              debugPrint('[Sync] Error scheduling notification ID ${data.id}: $e');
            }
          }
        }
      } else {
        debugPrint('[Sync] All notifications are already perfectly in sync.');
      }
    } catch (e) {
      debugPrint('[Sync] Reconciliation failed: $e');
    }
  }

  Future<void> rescheduleWarranty(WarrantyModel w) async {
    debugPrint('Rescheduling notifications: Running full sync to verify groupings...');
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('[Reschedule] Cancelled: No authenticated user.');
      return;
    }

    try {
      final dbWarrs = await _warrantyDb.fetchAllWarranties(user.uid);
      final activeReceipts = await _receiptDb.fetchAllReceipts(userId: user.uid);
      final activeReceiptIds = activeReceipts.map((r) => r['id'].toString()).toSet();
      final activeWarranties = dbWarrs.where((w) => activeReceiptIds.contains(w.receiptId)).toList();

      await syncWarranties(activeWarranties);
    } catch (e) {
      debugPrint('[Reschedule] Error loading active warranties: $e');
    }
  }

  Future<DateTime?> getNextReminderDate(List<WarrantyModel> warranties) async {
    final settings = await _settingsService.getSettings();
    if (!settings.notificationsEnabled) {
      return null;
    }

    final now = DateTime.now();
    DateTime? nextDate;

    for (final w in warranties) {
      final date = DateTime.tryParse(w.expiryDate);
      if (date == null) continue;

      final expiryScheduledDate = DateTime(
        date.year,
        date.month,
        date.day,
        settings.reminderHour,
        settings.reminderMinute,
      );

      for (final days in [30, 15, 7, 1, 0]) {
        final isEnabled = settings.reminderTypes[days] ?? true;
        if (!isEnabled) continue;

        final reminderDate = expiryScheduledDate.subtract(Duration(days: days));
        if (reminderDate.isAfter(now)) {
          if (nextDate == null || reminderDate.isBefore(nextDate)) {
            nextDate = reminderDate;
          }
        }
      }
    }

    return nextDate;
  }

  _NotificationText _getNotificationContent(String productName, int daysBefore) {
    if (daysBefore == 30) {
      return _NotificationText(
        title: 'Warranty Reminder',
        body: 'Your $productName warranty expires in 30 days.',
      );
    } else if (daysBefore == 15) {
      return _NotificationText(
        title: 'Warranty Reminder',
        body: 'Only 15 days remaining for your $productName warranty.',
      );
    } else if (daysBefore == 7) {
      return _NotificationText(
        title: 'Warranty Reminder',
        body: 'Only one week remaining for your $productName warranty.',
      );
    } else if (daysBefore == 1) {
      return _NotificationText(
        title: 'Warranty Reminder',
        body: 'Your $productName warranty expires tomorrow.',
      );
    } else {
      return _NotificationText(
        title: 'Warranty Expired Today',
        body: 'Your $productName warranty expires today.',
      );
    }
  }
}

class _PendingNotificationData {
  final int id;
  final String title;
  final String body;
  final tz.TZDateTime scheduledDate;
  final String payload;

  _PendingNotificationData({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledDate,
    required this.payload,
  });
}

class _NotificationText {
  final String title;
  final String body;

  _NotificationText({required this.title, required this.body});
}

class _ReminderItem {
  final WarrantyModel warranty;
  final int daysBefore;
  final tz.TZDateTime scheduledDate;

  _ReminderItem({
    required this.warranty,
    required this.daysBefore,
    required this.scheduledDate,
  });
}
