import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:receipto/app/config/routes.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// Holds the payload of a pending notification tap navigation.
final pendingNotificationPayloadProvider = StateProvider<String?>((ref) => null);

/// Notification channel constants.
const String _kChannelId = 'warranty_reminders_channel';
const String _kChannelName = 'Warranty Reminders';
const String _kChannelDesc = 'Notifications for warranty expiration alerts';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  /// Natively handles notification tap payload execution with logging.
  void handleNotificationTapPayload(String payload, ProviderContainer container) {
    debugPrint('=== Notification tapped ===');
    debugPrint('Payload received: $payload');
    try {
      final Map<String, dynamic> data = jsonDecode(payload);
      final isGrouped = data['isGrouped'] ?? false;
      final receiptId = data['receiptId'];
      final warrantyId = data['warrantyId'];
      final warrantyIdsList = data['warrantyIds'] as List<dynamic>?;
      
      final warrantyIds = warrantyIdsList?.map((e) => e.toString()).toList();
      
      debugPrint('Grouped: $isGrouped');
      debugPrint('Receipt ID: $receiptId');
      debugPrint('Warranty IDs: $warrantyIds');

      final String destinationRoute;
      if (isGrouped && warrantyIds != null && warrantyIds.isNotEmpty) {
        final idsQuery = warrantyIds.join(',');
        destinationRoute = '/warranties/upcoming?ids=$idsQuery';
      } else if (receiptId != null) {
        destinationRoute = '/receipts/details/$receiptId';
      } else if (warrantyId != null) {
        destinationRoute = '/receipts/warranty/$warrantyId';
      } else {
        destinationRoute = '/dashboard';
      }
      
      debugPrint('Destination Route: $destinationRoute');

      final router = container.read(routerProvider);
      router.push(destinationRoute);
      
      debugPrint('Navigation Complete');
    } catch (e) {
      debugPrint('Error parsing notification tap payload: $e');
    }
  }

  /// Natively handles notification tap payload execution with WidgetRef/BuildContext.
  void handleNotificationTapPayloadWithRef(String payload, WidgetRef ref, BuildContext context) {
    debugPrint('=== Notification tapped ===');
    debugPrint('Payload received: $payload');
    try {
      final Map<String, dynamic> data = jsonDecode(payload);
      final isGrouped = data['isGrouped'] ?? false;
      final receiptId = data['receiptId'];
      final warrantyId = data['warrantyId'];
      final warrantyIdsList = data['warrantyIds'] as List<dynamic>?;
      
      final warrantyIds = warrantyIdsList?.map((e) => e.toString()).toList();
      
      debugPrint('Grouped: $isGrouped');
      debugPrint('Receipt ID: $receiptId');
      debugPrint('Warranty IDs: $warrantyIds');

      final String destinationRoute;
      if (isGrouped && warrantyIds != null && warrantyIds.isNotEmpty) {
        final idsQuery = warrantyIds.join(',');
        destinationRoute = '/warranties/upcoming?ids=$idsQuery';
      } else if (receiptId != null) {
        destinationRoute = '/receipts/details/$receiptId';
      } else if (warrantyId != null) {
        destinationRoute = '/receipts/warranty/$warrantyId';
      } else {
        destinationRoute = '/dashboard';
      }
      
      debugPrint('Destination Route: $destinationRoute');

      GoRouter.of(context).push(destinationRoute);
      
      debugPrint('Navigation Complete');
    } catch (e) {
      debugPrint('Error parsing notification tap payload: $e');
    }
  }

  /// Initialize local notification plugins and callback hooks.
  Future<void> initialize(ProviderContainer container) async {
    // 1. Initialize local Timezone database
    tz_data.initializeTimeZones();
    String? tzName;
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Try to get cached timezone first (extremely safe for background isolates/WorkManager)
      tzName = prefs.getString('device_timezone');
      
      // In foreground (or fallback), lookup via platform channel and cache it
      if (tzName == null) {
        final tzInfo = await FlutterTimezone.getLocalTimezone();
        tzName = tzInfo.identifier;
        await prefs.setString('device_timezone', tzName);
      }
      
      tz.setLocalLocation(tz.getLocation(tzName));
      debugPrint('[NotificationService] Timezone database initialized to: "$tzName".');
    } catch (e) {
      debugPrint('[NotificationService] Timezone initialization failed: $e');
      if (tzName != null) {
        try {
          tz.setLocalLocation(tz.getLocation(tzName));
          debugPrint('[NotificationService] Fallback to cached timezone: "$tzName".');
        } catch (_) {}
      } else {
        tz.setLocalLocation(tz.UTC);
        debugPrint('[NotificationService] Timezone database ultimate fallback to UTC.');
      }
    }

    // 2. Setup channel on Android
    await _createNotificationChannel();

    // 3. Initialize plugin settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          try {
            final router = container.read(routerProvider);
            final currentLocation = router.routeInformationProvider.value.uri.path;
            
            // Check if user is fully logged in and off splash/auth paths
            if (currentLocation != '/splash' && currentLocation != '/login' && currentLocation != '/signup') {
              handleNotificationTapPayload(payload, container);
            } else {
              debugPrint('[NotificationService] Transitionary state detected (location: $currentLocation). Buffering payload.');
              container.read(pendingNotificationPayloadProvider.notifier).state = payload;
            }
          } catch (e) {
            debugPrint('[NotificationService] Error during tap routing check: $e. Buffering payload.');
            container.read(pendingNotificationPayloadProvider.notifier).state = payload;
          }
        }
      },
    );

    // Check if the app was launched by tapping a notification (Cold Start)
    try {
      final launchDetails = await _notificationsPlugin.getNotificationAppLaunchDetails();
      if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
        final payload = launchDetails.notificationResponse?.payload;
        debugPrint('[NotificationService] App launched via notification tap (Cold Start). Payload: $payload');
        if (payload != null && payload.isNotEmpty) {
          container.read(pendingNotificationPayloadProvider.notifier).state = payload;
        }
      }
    } catch (e) {
      debugPrint('[NotificationService] Error retrieving app launch details: $e');
    }

    debugPrint('[NotificationService] Initialized successfully.');
  }

  /// Explicitly creates the notification channel.
  Future<void> _createNotificationChannel() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _kChannelId,
      _kChannelName,
      description: _kChannelDesc,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await androidPlugin.createNotificationChannel(channel);
    debugPrint('[NotificationService] Notification channel "$_kChannelId" created/verified.');
  }

  /// Request POST_NOTIFICATIONS permission on Android 13+ and iOS.
  Future<bool> requestPermission() async {
    final status = await Permission.notification.status;
    debugPrint('[NotificationService] Notification permission status: $status');
    if (status.isDenied || status.isProvisional) {
      final result = await Permission.notification.request();
      debugPrint('[NotificationService] Permission request result: $result');
    }
    
    // Request exact alarm permission dynamically on Android
    if (Platform.isAndroid) {
      try {
        final exactStatus = await Permission.scheduleExactAlarm.status;
        debugPrint('[NotificationService] Exact alarm permission status: $exactStatus');
        if (exactStatus.isDenied) {
          debugPrint('[NotificationService] Requesting exact alarm permission...');
          final result = await Permission.scheduleExactAlarm.request();
          debugPrint('[NotificationService] Exact alarm permission request result: $result');
        }
      } catch (e) {
        debugPrint('[NotificationService] Error requesting exact alarm permission: $e');
      }
    }
    
    final finalStatus = await Permission.notification.status;
    return finalStatus.isGranted;
  }

  /// Shows an immediate local notification.
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _kChannelId,
      _kChannelName,
      channelDescription: _kChannelDesc,
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

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformDetails,
      payload: payload,
    );
    
    debugPrint('Alarm triggered — ID: $id');
    debugPrint('Notification displayed — ID: $id | Title: "$title"');
  }

  /// Cancels a specific notification by ID.
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id: id);
    debugPrint('[NotificationService] Notification cancelled — ID: $id');
  }

  /// Cancels all active notifications.
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
    debugPrint('[NotificationService] All notifications cancelled.');
  }

  /// Checks if the notification channel is created on Android.
  Future<bool> isChannelCreatedAndEnabled() async {
    if (!Platform.isAndroid) return true;
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin == null) return false;
      final channels = await androidPlugin.getNotificationChannels();
      if (channels == null) return false;
      for (final channel in channels) {
        if (channel.id == _kChannelId) {
          return true;
        }
      }
    } catch (e) {
      debugPrint('[NotificationService] Error checking channel status: $e');
    }
    return false;
  }

  /// Lists all currently pending (scheduled) notification IDs to verify scheduling.
  Future<void> logPendingNotifications() async {
    final pending = await _notificationsPlugin.pendingNotificationRequests();
    if (pending.isEmpty) {
      debugPrint('[NotificationService] No pending scheduled notifications.');
    } else {
      debugPrint('[NotificationService] Pending notifications (${pending.length}):');
      for (final n in pending) {
        debugPrint('  → ID: ${n.id} | Title: "${n.title}" | Body: "${n.body}"');
      }
    }
  }
}
