import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:receipto/core/constants/constants.dart';
import 'package:google_fonts/google_fonts.dart';

const String _kBatteryPromptShownKey = 'battery_optimization_prompt_shown';

/// Checks whether battery optimization is bypassed and shows a one-time
/// prompt if not. This is critical for notifications to fire on OEM devices
/// (Xiaomi, Realme, Oppo, OnePlus, Samsung) that aggressively kill background tasks.
class BatteryOptimizationService {
  static Future<void> checkAndPromptIfNeeded(BuildContext context) async {
    if (!Platform.isAndroid) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final alreadyShown = prefs.getBool(_kBatteryPromptShownKey) ?? false;
      if (alreadyShown) return;

      final status = await Permission.ignoreBatteryOptimizations.status;
      debugPrint('[BatteryOpt] Battery optimization ignored: ${status.isGranted}');

      if (!status.isGranted) {
        await prefs.setBool(_kBatteryPromptShownKey, true);
        // Check context is still valid after all async gaps before using it
        if (context.mounted) {
          _showPrompt(context);
        }
      }
    } catch (e) {
      debugPrint('[BatteryOpt] Check failed: $e');
    }
  }

  static void _showPrompt(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lg,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        title: Row(
          children: [
            const Icon(Icons.battery_alert_rounded, color: AppColors.primary, size: 22),
            const SizedBox(width: 10),
            Text(
              'Enable Reliable Notifications',
              style: GoogleFonts.hankenGrotesk(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Text(
          'Your device\'s battery manager may prevent Receipto from '
          'delivering warranty reminders while the app is closed.\n\n'
          'To ensure you never miss an expiry alert:\n\n'
          '1. Tap "Open Settings" below\n'
          '2. Find Receipto in the list\n'
          '3. Select "Don\'t optimize" or "Unrestricted"\n\n'
          'This only affects background reminder delivery.',
          style: GoogleFonts.inter(
            color: AppColors.onSurfaceVariant,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Maybe Later',
              style: GoogleFonts.inter(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await Permission.ignoreBatteryOptimizations.request();
              } catch (e) {
                debugPrint('[BatteryOpt] Failed to open settings: $e');
              }
            },
            child: Text(
              'Open Settings',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
