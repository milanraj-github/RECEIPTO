import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart';

import 'package:receipto/app/app.dart';
import 'package:receipto/firebase_options.dart';
import 'package:receipto/core/services/notification_service.dart';
import 'package:receipto/core/services/background_service.dart';
import 'package:receipto/core/services/email_service.dart';
import 'package:receipto/core/services/reminder_engine.dart';
import 'package:receipto/core/services/battery_optimization_service.dart';
import 'package:receipto/core/services/warranty_database_service.dart';
import 'package:receipto/core/services/receipt_database_service.dart';
import 'package:receipto/app/config/routes.dart';
import 'package:receipto/features/notifications/data/services/notification_scheduler.dart';
import 'package:receipto/features/notifications/presentation/providers/notification_provider.dart';
import 'package:receipto/features/scan/presentation/providers/scan_provider.dart';
import 'package:receipto/features/ai_assistant/data/services/ai_assistant_service.dart';
import 'package:receipto/features/warranty/presentation/providers/warranty_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env configuration
  await dotenv.load(fileName: ".env");

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    publishableKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Initialize Riverpod ProviderContainer
  final container = ProviderContainer();

  // Cache environment credentials for background isolates
  try {
    await container.read(emailServiceProvider).cacheEnvCredentials();
  } catch (e) {
    debugPrint('[main] Error caching credentials: $e');
  }

  // Initialize Notification Service
  final notificationService = container.read(notificationServiceProvider);
  await notificationService.initialize(container);
  await notificationService.requestPermission();

  // Initialize Workmanager
  Workmanager().initialize(callbackDispatcher);
  // Cache Supabase env vars to SharedPreferences for background isolate
  try {
    final prefs = await SharedPreferences.getInstance();
    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'];
    if (supabaseUrl != null) await prefs.setString('env_SUPABASE_URL', supabaseUrl);
    if (supabaseKey != null) await prefs.setString('env_SUPABASE_ANON_KEY', supabaseKey);
  } catch (e) {
    debugPrint('[main] Error caching Supabase env vars: $e');
  }
  await BackgroundService.registerPeriodicTask();
  debugPrint('[main] WorkManager initialized.');

  // Listen to Auth changes to run startup notification synchronization
  FirebaseAuth.instance.authStateChanges().listen((user) async {
    // Invalidate all user-specific Riverpod providers and clear memory caches on auth state transition
    container.read(scanProvider.notifier).clearState();
    container.read(aiAssistantServiceProvider).clearCache();
    container.invalidate(dbReceiptsListProvider);
    container.invalidate(recycleBinProvider);
    container.invalidate(dbWarrantiesProvider);
    container.invalidate(notificationNotifierProvider);

    if (user != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        if (user.email != null && user.email!.isNotEmpty) {
          await prefs.setString('last_logged_in_email', user.email!);
          await prefs.setString('last_logged_in_uid', user.uid);
          debugPrint('[main.dart] Cached active user email to SharedPreferences: ${user.email}');
        }
      } catch (e) {
        debugPrint('[main.dart] SharedPreferences cache failed: $e');
      }

      debugPrint('[Startup] User detected: ${user.uid}. Starting notification synchronization...');
      try {
        final scheduler = container.read(notificationSchedulerProvider);
        await scheduler.cancelAll(); // Clear any stale notifications from previous account

        final dbWarrs = await container.read(warrantyDatabaseServiceProvider).fetchAllWarranties(user.uid);
        final dbReceiptsService = container.read(receiptDatabaseServiceProvider);
        final activeReceipts = await dbReceiptsService.fetchAllReceipts(userId: user.uid);
        final activeReceiptIds = activeReceipts.map((r) => r['id'].toString()).toSet();
        final activeWarranties = dbWarrs.where((w) => w.receiptId == null || w.receiptId!.isEmpty || activeReceiptIds.contains(w.receiptId)).toList();

        await scheduler.syncWarranties(activeWarranties);

        // Also evaluate and dispatch any currently due notifications/emails immediately
        final reminderEngine = container.read(reminderEngineProvider);
        await reminderEngine.checkWarrantyReminders(user.uid, user.email, user.displayName);

        // ── Schedule exact one-time alarm for configured reminder time ──
        // This is the primary mechanism: fires at the user-set time even when app is closed.
        try {
          final prefs = await SharedPreferences.getInstance();
          final reminderHour = prefs.getInt('warranty_notif_hour') ?? 9;
          final reminderMinute = prefs.getInt('warranty_notif_minute') ?? 0;
          final now = DateTime.now();
          var target = DateTime(now.year, now.month, now.day, reminderHour, reminderMinute);
          if (!target.isAfter(now)) {
            target = target.add(const Duration(days: 1));
          }
          final delay = target.difference(now);
          debugPrint('[Reminder] Login — Current time: $now');
          debugPrint('[Reminder] Login — Configured reminder time: ${reminderHour.toString().padLeft(2, "0")}:${reminderMinute.toString().padLeft(2, "0")}');
          debugPrint('[Reminder] Login — Target time: $target');
          debugPrint('[Reminder] Login — Scheduling exact alarm in: $delay');
          await BackgroundService.registerOneTimeTask(delay);
        } catch (e) {
          debugPrint('[Startup] Error scheduling one-time alarm: $e');
        }

        // Show battery optimization prompt once after user is authenticated
        // Use a short delay so the UI is fully mounted before showing a dialog
        await Future.delayed(const Duration(seconds: 2));
        final context = container.read(routerProvider).routerDelegate.navigatorKey.currentContext;
        if (context != null && context.mounted) {
          await BatteryOptimizationService.checkAndPromptIfNeeded(context);
        }
      } catch (e) {
        debugPrint('[Startup] Error during startup notification sync: $e');
      }
    } else {
      // User signed out: Clear local preferences, cancel device notifications,
      // and cancel the one-time alarm so it does NOT fire for the next user.
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('last_logged_in_email');
        await prefs.remove('last_logged_in_uid');
        await container.read(notificationSchedulerProvider).cancelAll();
        await BackgroundService.cancelOneTimeTask(); // ← cancel exact alarm on logout
      } catch (e) {
        debugPrint('[main.dart] Error clearing cache on signout: $e');
      }
    }
  });

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const ReceiptoApp(),
    ),
  );
}