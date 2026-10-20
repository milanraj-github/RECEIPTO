import 'dart:convert';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:workmanager/workmanager.dart';
import 'package:receipto/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:receipto/core/services/notification_service.dart';
import 'package:receipto/core/services/reminder_engine.dart';

/// Periodic background task name (runs every 15 min as safety net)
const String warrantyCheckTask = "warrantyCheckPeriodicTask";

/// One-time exact-time task name (scheduled for user-configured reminder time)
const String warrantyCheckOneTimeTask = "warrantyCheckOneTimeTask";

/// Unique WorkManager task ID for the one-time alarm
const String _kOneTimeTaskId = "warrantyCheckOnce";

/// Reliable environment loader targeting background isolates
Future<void> loadEnvReliably() async {
  try {
    await dotenv.load(fileName: ".env");
    debugPrint('[EnvLoad] Loaded via dotenv.load(.env)');
  } catch (e) {
    debugPrint('[EnvLoad] dotenv.load(.env) failed: $e. Trying manual loadString(.env)...');
    try {
      final content = await rootBundle.loadString('.env');
      final lines = const LineSplitter().convert(content);
      dotenv.env.addAll(const Parser().parse(lines));
      debugPrint('[EnvLoad] Loaded manually via .env');
    } catch (e2) {
      debugPrint('[EnvLoad] manual loadString(.env) failed: $e2. Trying manual loadString(assets/.env)...');
      try {
        final content = await rootBundle.loadString('assets/.env');
        final lines = const LineSplitter().convert(content);
        dotenv.env.addAll(const Parser().parse(lines));
        debugPrint('[EnvLoad] Loaded manually via assets/.env');
      } catch (e3) {
        debugPrint('[EnvLoad] All environment loading methods failed: $e3');
      }
    }
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    DartPluginRegistrant.ensureInitialized();
    WidgetsFlutterBinding.ensureInitialized();

    debugPrint('[Reminder] Alarm fired — task=$taskName');

    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_workmanager_run', DateTime.now().toLocal().toString());
      await prefs.setString('last_workmanager_status', 'RUNNING');
    } catch (e) {
      debugPrint('[WorkManager] SharedPreferences failed: $e');
    }

    // Load environmental configuration
    debugPrint('Loading dotenv');
    await loadEnvReliably();

    // Initialize Firebase
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      debugPrint('[WorkManager] Firebase initialized.');
    } catch (e) {
      debugPrint('[WorkManager] Firebase initialization error: $e');
    }

    // Initialize Supabase (with SharedPreferences fallback)
    try {
      final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? prefs?.getString('env_SUPABASE_URL');
      final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'] ?? prefs?.getString('env_SUPABASE_ANON_KEY');

      if (supabaseUrl != null && supabaseKey != null) {
        await sb.Supabase.initialize(
          url: supabaseUrl,
          publishableKey: supabaseKey,
        );
        debugPrint('[WorkManager] Supabase initialized successfully.');
      } else {
        throw Exception('Supabase URL or Anon Key is missing.');
      }
    } catch (e) {
      debugPrint('[WorkManager] Supabase initialization error: $e');
    }

    // Fetch active user with delay recovery checks
    fb.User? currentUser = fb.FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      // Wait up to 3 seconds for session to restore asynchronously
      for (int i = 0; i < 30; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        currentUser = fb.FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          debugPrint('[WorkManager] User session restored after ${i * 100}ms.');
          break;
        }
      }
    }

    String? userEmail = currentUser?.email;
    String? userUid = currentUser?.uid;

    if (userEmail == null || userEmail.isEmpty || userUid == null || userUid.isEmpty) {
      userEmail = prefs?.getString('last_logged_in_email');
      userUid = prefs?.getString('last_logged_in_uid');
      debugPrint('[Reminder] Using cached credentials: email=$userEmail, uid=$userUid');
    }

    if (userUid == null || userUid.isEmpty) {
      debugPrint('[Reminder] No authenticated user — alarm cancelled.');
      await prefs?.setString('last_workmanager_status', 'CANCELLED (No User)');
      return true;
    }

    debugPrint('[Reminder] Current user UID: $userUid');

    final container = ProviderContainer();
    // Initialize notifications
    await container.read(notificationServiceProvider).initialize(container);

    bool engineSuccess = false;
    try {
      final engine = container.read(reminderEngineProvider);
      debugPrint('[Reminder] Checking warranties...');
      await engine.checkWarrantyReminders(
        userUid,
        userEmail,
        currentUser?.displayName,
      );
      engineSuccess = true;
      await prefs?.setString('last_workmanager_status', 'SUCCESS');
      debugPrint('[WorkManager] finished: task=$taskName successfully executed.');
    } catch (e) {
      await prefs?.setString('last_workmanager_status', 'FAILED: $e');
      debugPrint('[WorkManager] failed: task=$taskName error=$e');
      if (kDebugMode) print('Error running background checks via reminder engine: $e');
    }

    // If this was the one-time exact-time task, re-schedule itself for the next day
    // so that the exact alarm keeps firing daily at the configured time.
    if (taskName == warrantyCheckOneTimeTask && engineSuccess) {
      try {
        final reminderHour = prefs?.getInt('warranty_notif_hour') ?? 9;
        final reminderMinute = prefs?.getInt('warranty_notif_minute') ?? 0;
        final now = DateTime.now();
        // Next occurrence is tomorrow at the same configured time
        var nextTarget = DateTime(now.year, now.month, now.day, reminderHour, reminderMinute);
        if (!nextTarget.isAfter(now)) {
          nextTarget = nextTarget.add(const Duration(days: 1));
        }
        final nextDelay = nextTarget.difference(now);
        await Workmanager().registerOneOffTask(
          _kOneTimeTaskId,
          warrantyCheckOneTimeTask,
          initialDelay: nextDelay,
          existingWorkPolicy: ExistingWorkPolicy.replace,
          constraints: Constraints(networkType: NetworkType.connected),
        );
        debugPrint('[Reminder] Next daily alarm scheduled for: $nextTarget (delay: $nextDelay)');
      } catch (e) {
        debugPrint('[Reminder] Failed to re-schedule next daily alarm: $e');
      }
    }

    return true;
  });
}

class BackgroundService {
  /// Schedules a one-time exact-time task that fires at the user-configured
  /// reminder time. Uses WorkManager's initialDelay which internally uses
  /// AlarmManager.setExactAndAllowWhileIdle — works even when app is closed.
  ///
  /// ExistingWorkPolicy.replace ensures any previously scheduled alarm
  /// is cancelled and replaced with the new target time.
  static Future<void> registerOneTimeTask(Duration delay) async {
    debugPrint('[Reminder] Scheduling exact one-time alarm...');
    debugPrint('[Reminder] Delay until alarm fires: $delay');
    await Workmanager().registerOneOffTask(
      _kOneTimeTaskId,
      warrantyCheckOneTimeTask,
      initialDelay: delay,
      existingWorkPolicy: ExistingWorkPolicy.replace,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
    debugPrint('[Reminder] Exact alarm registered successfully.');
  }

  /// Cancels the one-time exact-time task (e.g., on user logout).
  static Future<void> cancelOneTimeTask() async {
    try {
      await Workmanager().cancelByUniqueName(_kOneTimeTaskId);
      debugPrint('[Reminder] One-time alarm cancelled (user logout).');
    } catch (e) {
      debugPrint('[Reminder] Error cancelling one-time alarm: $e');
    }
  }

  /// Registers the periodic background task using Workmanager.
  /// Runs every 15 minutes (Android minimum) as a safety net for missed alarms.
  /// ExistingWorkPolicy.replace ensures settings changes take effect.
  static Future<void> registerPeriodicTask() async {
    Workmanager().registerPeriodicTask(
      "warrantyCheck",
      warrantyCheckTask,
      frequency: const Duration(minutes: 15),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
    debugPrint('[BackgroundService] Periodic safety-net task registered (every 15 min).');
  }
}
