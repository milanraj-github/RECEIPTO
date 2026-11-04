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
import 'package:receipto/core/services/currency_converter_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Safe environment configuration loading with fallback
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('[main] dotenv.load(.env) notice: $e');
  }

  // 2. Safe Firebase initialization
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('[main] Firebase.initializeApp notice: $e');
  }

  // 3. Safe Supabase initialization with hardcoded cloud fallback
  try {
    final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? 'https://ykqzefulvpqfiwsddnqt.supabase.co';
    final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'] ??
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlrcXplZnVsdnBxZml3c2RkbnF0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI3NTI2NTcsImV4cCI6MjA5ODMyODY1N30.NFm5dT7vVeHtziEkYWN-qk8ZEogpktPZ7NTmXDLO1Qs';
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseKey,
    );
  } catch (e) {
    debugPrint('[main] Supabase.initialize notice: $e');
  }

  // 4. Initialize Riverpod ProviderContainer
  final container = ProviderContainer();

  // 5. Mount the Flutter Widget Tree IMMEDIATELY so app UI displays without blocking
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const ReceiptoApp(),
    ),
  );

  // 6. Initialize background services asynchronously AFTER UI is mounted
  _initAsyncServices(container);
}

/// Asynchronous startup tasks running in the background without blocking the UI
void _initAsyncServices(ProviderContainer container) {
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    // Cache environment credentials for background isolates
    try {
      await container.read(emailServiceProvider).cacheEnvCredentials();
    } catch (e) {
      debugPrint('[main] Error caching credentials: $e');
    }

    // Initialize Live Currency Conversion
    try {
      CurrencyConverterService.initialize();
    } catch (e) {
      debugPrint('[main] Error initializing CurrencyConverter: $e');
    }

    // Initialize Notification Service & request permissions safely
    try {
      final notificationService = container.read(notificationServiceProvider);
      await notificationService.initialize(container);
      await notificationService.requestPermission();
    } catch (e) {
      debugPrint('[main] Error initializing NotificationService: $e');
    }

    // Initialize Workmanager
    try {
      Workmanager().initialize(callbackDispatcher);
      final prefs = await SharedPreferences.getInstance();
      final supabaseUrl = dotenv.env['SUPABASE_URL'];
      final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'];
      if (supabaseUrl != null) await prefs.setString('env_SUPABASE_URL', supabaseUrl);
      if (supabaseKey != null) await prefs.setString('env_SUPABASE_ANON_KEY', supabaseKey);
      await BackgroundService.registerPeriodicTask();
      debugPrint('[main] WorkManager initialized.');
    } catch (e) {
      debugPrint('[main] Error initializing WorkManager: $e');
    }

    // Listen to Auth changes to run startup notification synchronization
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      try {
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
            await scheduler.cancelAll();

            final dbWarrs = await container.read(warrantyDatabaseServiceProvider).fetchAllWarranties(user.uid);
            final dbReceiptsService = container.read(receiptDatabaseServiceProvider);
            final activeReceipts = await dbReceiptsService.fetchAllReceipts(userId: user.uid);
            final activeReceiptIds = activeReceipts.map((r) => r['id'].toString()).toSet();
            final activeWarranties = dbWarrs.where((w) => w.receiptId == null || w.receiptId!.isEmpty || activeReceiptIds.contains(w.receiptId)).toList();

            await scheduler.syncWarranties(activeWarranties);

            final reminderEngine = container.read(reminderEngineProvider);
            await reminderEngine.checkWarrantyReminders(user.uid, user.email, user.displayName);

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
              await BackgroundService.registerOneTimeTask(delay);
            } catch (e) {
              debugPrint('[Startup] Error scheduling one-time alarm: $e');
            }

            await Future.delayed(const Duration(seconds: 2));
            final context = container.read(routerProvider).routerDelegate.navigatorKey.currentContext;
            if (context != null && context.mounted) {
              await BatteryOptimizationService.checkAndPromptIfNeeded(context);
            }
          } catch (e) {
            debugPrint('[Startup] Error during startup notification sync: $e');
          }
        } else {
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('last_logged_in_email');
            await prefs.remove('last_logged_in_uid');
            await container.read(notificationSchedulerProvider).cancelAll();
            await BackgroundService.cancelOneTimeTask();
          } catch (e) {
            debugPrint('[main.dart] Error clearing cache on signout: $e');
          }
        }
      } catch (e) {
        debugPrint('[main.dart] Error in authStateChanges listener: $e');
      }
    });
  });
}
