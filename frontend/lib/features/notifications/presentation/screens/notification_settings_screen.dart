import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:receipto/core/constants/constants.dart';
import 'package:receipto/core/widgets/glass_card.dart';
import 'package:receipto/features/notifications/presentation/providers/notification_settings_provider.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(notificationSettingsProvider);
    final nextReminderAsync = ref.watch(nextScheduledReminderProvider);
    
    String formatNextReminder(DateTime? date) {
      if (date == null) return 'No upcoming reminders.';
      
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final day = date.day.toString();
      final month = months[date.month - 1];
      final year = date.year.toString();
      
      final hourInt = date.hour;
      final minuteInt = date.minute;
      final period = hourInt >= 12 ? 'PM' : 'AM';
      final formattedHour = hourInt == 0 ? 12 : (hourInt > 12 ? hourInt - 12 : hourInt);
      final formattedMinute = minuteInt.toString().padLeft(2, '0');
      
      return '$day $month $year at $formattedHour:$formattedMinute $period';
    }

    Widget buildCompactToggleRow({
      required String title,
      required bool value,
      required ValueChanged<bool> onChanged,
      required bool enabled,
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                color: enabled ? AppColors.onSurface : AppColors.onSurfaceVariant.withValues(alpha: 0.4),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Switch(
              value: value,
              onChanged: enabled ? onChanged : null,
              activeThumbColor: AppColors.primary,
              activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
              inactiveThumbColor: AppColors.onSurfaceVariant,
              inactiveTrackColor: AppColors.surfaceVariant,
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Notification Settings',
          style: GoogleFonts.hankenGrotesk(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Section 1: Warranty Notifications
              Text(
                'Warranty Notifications',
                style: GoogleFonts.hankenGrotesk(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Receive reminders before warranty expiry.',
                style: GoogleFonts.inter(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              GlassCard(
                borderRadius: AppRadius.lg,
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Enable Notifications',
                      style: GoogleFonts.inter(
                        color: AppColors.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Switch(
                      value: settings.notificationsEnabled,
                      onChanged: (val) {
                        ref.read(notificationSettingsProvider.notifier).updateNotificationsEnabled(val);
                      },
                      activeThumbColor: AppColors.primary,
                      activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
                      inactiveThumbColor: AppColors.onSurfaceVariant,
                      inactiveTrackColor: AppColors.surfaceVariant,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Section 2: Reminder Time
              Text(
                'Reminder Time',
                style: GoogleFonts.hankenGrotesk(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              GlassCard(
                borderRadius: AppRadius.lg,
                padding: const EdgeInsets.all(16),
                child: InkWell(
                  onTap: settings.notificationsEnabled
                      ? () async {
                          final TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay(
                              hour: settings.reminderHour,
                              minute: settings.reminderMinute,
                            ),
                            builder: (BuildContext context, Widget? child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  timePickerTheme: const TimePickerThemeData(
                                    hourMinuteTextColor: Colors.white,
                                    dayPeriodTextColor: Colors.white,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            ref
                                .read(notificationSettingsProvider.notifier)
                                .updateReminderTime(picked.hour, picked.minute);
                          }
                        }
                      : null,
                  borderRadius: AppRadius.lg,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Scheduled Time',
                        style: GoogleFonts.inter(
                          color: settings.notificationsEnabled
                              ? AppColors.onSurface
                              : AppColors.onSurfaceVariant.withValues(alpha: 0.4),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: settings.notificationsEnabled
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: settings.notificationsEnabled
                                ? AppColors.primary.withValues(alpha: 0.3)
                                : Colors.transparent,
                          ),
                        ),
                        child: Text(
                          TimeOfDay(
                            hour: settings.reminderHour,
                            minute: settings.reminderMinute,
                          ).format(context),
                          style: GoogleFonts.inter(
                            color: settings.notificationsEnabled
                                ? AppColors.primary
                                : AppColors.onSurfaceVariant.withValues(alpha: 0.4),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Section 3: Reminder Types
              Text(
                'Reminder Types',
                style: GoogleFonts.hankenGrotesk(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              GlassCard(
                borderRadius: AppRadius.lg,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    buildCompactToggleRow(
                      title: '30 Days Before',
                      value: settings.reminderTypes[30] ?? true,
                      enabled: settings.notificationsEnabled,
                      onChanged: (val) {
                        ref.read(notificationSettingsProvider.notifier).updateSetting(30, val);
                      },
                    ),
                    const Divider(color: Colors.white10, height: 12),
                    buildCompactToggleRow(
                      title: '15 Days Before',
                      value: settings.reminderTypes[15] ?? true,
                      enabled: settings.notificationsEnabled,
                      onChanged: (val) {
                        ref.read(notificationSettingsProvider.notifier).updateSetting(15, val);
                      },
                    ),
                    const Divider(color: Colors.white10, height: 12),
                    buildCompactToggleRow(
                      title: '7 Days Before',
                      value: settings.reminderTypes[7] ?? true,
                      enabled: settings.notificationsEnabled,
                      onChanged: (val) {
                        ref.read(notificationSettingsProvider.notifier).updateSetting(7, val);
                      },
                    ),
                    const Divider(color: Colors.white10, height: 12),
                    buildCompactToggleRow(
                      title: '1 Day Before',
                      value: settings.reminderTypes[1] ?? true,
                      enabled: settings.notificationsEnabled,
                      onChanged: (val) {
                        ref.read(notificationSettingsProvider.notifier).updateSetting(1, val);
                      },
                    ),
                    const Divider(color: Colors.white10, height: 12),
                    buildCompactToggleRow(
                      title: 'Expiry Day',
                      value: settings.reminderTypes[0] ?? true,
                      enabled: settings.notificationsEnabled,
                      onChanged: (val) {
                        ref.read(notificationSettingsProvider.notifier).updateSetting(0, val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Section 4: Email Notifications
              Text(
                'Email Notifications',
                style: GoogleFonts.hankenGrotesk(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              GlassCard(
                borderRadius: AppRadius.lg,
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Email Reminders',
                            style: GoogleFonts.inter(
                              color: AppColors.onSurface,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Send reminders to your email address.',
                            style: GoogleFonts.inter(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: settings.emailNotificationsEnabled,
                      onChanged: (val) {
                        ref
                            .read(notificationSettingsProvider.notifier)
                            .updateEmailNotificationsEnabled(val);
                      },
                      activeThumbColor: AppColors.primary,
                      activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
                      inactiveThumbColor: AppColors.onSurfaceVariant,
                      inactiveTrackColor: AppColors.surfaceVariant,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Section 5: Quick Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: settings.notificationsEnabled
                              ? AppColors.primary.withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.05),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.md,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: settings.notificationsEnabled
                          ? () {
                              ref.read(notificationSettingsProvider.notifier).enableAll();
                            }
                          : null,
                      child: Text(
                        'Enable All',
                        style: GoogleFonts.inter(
                          color: settings.notificationsEnabled
                              ? AppColors.primary
                              : AppColors.onSurfaceVariant.withValues(alpha: 0.4),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: settings.notificationsEnabled
                              ? AppColors.error.withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.05),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.md,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: settings.notificationsEnabled
                          ? () {
                              ref.read(notificationSettingsProvider.notifier).disableAll();
                            }
                          : null,
                      child: Text(
                        'Disable All',
                        style: GoogleFonts.inter(
                          color: settings.notificationsEnabled
                              ? AppColors.error
                              : AppColors.onSurfaceVariant.withValues(alpha: 0.4),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Section 6: Status
              Text(
                'Status',
                style: GoogleFonts.hankenGrotesk(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              GlassCard(
                borderRadius: AppRadius.lg,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Next Scheduled Reminder',
                      style: GoogleFonts.inter(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    nextReminderAsync.when(
                      data: (date) {
                        final formatted = formatNextReminder(date);
                        final isScheduled = date != null;
                        return Row(
                          children: [
                            Icon(
                              isScheduled
                                  ? Icons.alarm_on_rounded
                                  : Icons.alarm_off_rounded,
                              color: isScheduled ? AppColors.primary : Colors.white30,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                formatted,
                                style: GoogleFonts.inter(
                                  color: isScheduled ? Colors.white : Colors.white30,
                                  fontSize: 14,
                                  fontWeight: isScheduled ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      error: (err, stack) => Text(
                        'Error loading upcoming reminders',
                        style: GoogleFonts.inter(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
