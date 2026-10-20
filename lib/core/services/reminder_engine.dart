import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:receipto/core/services/notification_service.dart';
import 'package:receipto/core/services/email_service.dart';
import 'package:receipto/core/services/warranty_database_service.dart';
import 'package:receipto/core/services/notification_database_service.dart';
import 'package:receipto/features/notifications/domain/models/notification_model.dart';
import 'package:receipto/features/warranty/domain/models/warranty_model.dart';
import 'package:receipto/core/utils/warranty_utils.dart';

final reminderEngineProvider = Provider<ReminderEngine>((ref) {
  final dbService = ref.watch(warrantyDatabaseServiceProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  final emailService = ref.watch(emailServiceProvider);
  final notiDbService = ref.watch(notificationDatabaseServiceProvider);
  return ReminderEngine(dbService, notificationService, emailService, notiDbService);
});

class ReminderEngine {
  final WarrantyDatabaseService _dbService;
  final NotificationService _notificationService;
  final EmailService _emailService;
  final NotificationDatabaseService _notiDbService;

  ReminderEngine(this._dbService, this._notificationService, this._emailService, this._notiDbService);

  int calculateNotificationId(String warrantyId, int daysBefore) {
    return ((warrantyId.hashCode * 31) + daysBefore) & 0x7FFFFFFF;
  }

  WarrantyModel _applyNotificationFlag(WarrantyModel w, int daysRemaining) {
    if (daysRemaining <= 30 && daysRemaining > 15) {
      return w.copyWith(notification30Sent: true);
    }
    if (daysRemaining <= 15 && daysRemaining > 7) {
      return w.copyWith(notification15Sent: true, notification30Sent: true);
    }
    if (daysRemaining <= 7 && daysRemaining > 3) {
      return w.copyWith(notification7Sent: true, notification15Sent: true, notification30Sent: true);
    }
    if (daysRemaining <= 3 && daysRemaining > 1) {
      return w.copyWith(notification3Sent: true, notification7Sent: true, notification15Sent: true, notification30Sent: true);
    }
    if (daysRemaining == 1) {
      return w.copyWith(notification1Sent: true, notification3Sent: true, notification7Sent: true, notification15Sent: true, notification30Sent: true);
    }
    if (daysRemaining == 0) {
      return w.copyWith(notificationTodaySent: true, notification1Sent: true, notification3Sent: true, notification7Sent: true, notification15Sent: true, notification30Sent: true);
    }
    if (daysRemaining < 0) {
      return w.copyWith(
        notificationExpiredSent: true,
        notificationTodaySent: true,
        notification1Sent: true,
        notification3Sent: true,
        notification7Sent: true,
        notification15Sent: true,
        notification30Sent: true,
      );
    }
    return w;
  }

  WarrantyModel _applyEmailFlag(WarrantyModel w, int daysRemaining) {
    if (daysRemaining <= 30 && daysRemaining > 15) {
      return w.copyWith(email30Sent: true);
    }
    if (daysRemaining <= 15 && daysRemaining > 7) {
      return w.copyWith(email15Sent: true, email30Sent: true);
    }
    if (daysRemaining <= 7 && daysRemaining > 3) {
      return w.copyWith(email7Sent: true, email15Sent: true, email30Sent: true);
    }
    if (daysRemaining <= 3 && daysRemaining > 1) {
      return w.copyWith(email3Sent: true, email7Sent: true, email15Sent: true, email30Sent: true);
    }
    if (daysRemaining == 1) {
      return w.copyWith(email1Sent: true, email3Sent: true, email7Sent: true, email15Sent: true, email30Sent: true);
    }
    if (daysRemaining == 0) {
      return w.copyWith(emailTodaySent: true, email1Sent: true, email3Sent: true, email7Sent: true, email15Sent: true, email30Sent: true);
    }
    if (daysRemaining < 0) {
      return w.copyWith(
        emailExpiredSent: true,
        emailTodaySent: true,
        email1Sent: true,
        email3Sent: true,
        email7Sent: true,
        email15Sent: true,
        email30Sent: true,
      );
    }
    return w;
  }

  /// Performs warranty alerts scanning for a user.
  Future<void> checkWarrantyReminders(String userId, String? email, String? displayName) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    print("========== WARRANTY REMINDER ==========");
    print("Background task started");
    print("Current Date: $today");

    // Verify Firebase Current User
    print("Firebase Current User");
    String firebaseEmail = 'NULL';
    String firebaseUid = 'NULL';
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print("No logged-in user found.");
      } else {
        firebaseEmail = currentUser.email ?? 'NULL';
        firebaseUid = currentUser.uid;
        print("UID");
        print(firebaseUid);
        print("Email");
        print(firebaseEmail);
      }
    } catch (e) {
      print("Firebase not initialized in this environment.");
    }

    try {
      final client = Supabase.instance.client;
      final prefs = await SharedPreferences.getInstance();

      // Recipient Email Resolution Priority Checks (Objective 5)
      String? resolvedEmail;
      
      bool isValidEmail(String em) {
        final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
        return emailRegex.hasMatch(em.trim());
      }

      // Priority 1: Use email explicitly passed into checkWarrantyReminders()
      if (email != null && email.trim().isNotEmpty && isValidEmail(email)) {
        resolvedEmail = email.trim();
      }
      
      // Priority 2: If email parameter is null/empty, read last_logged_in_email from SharedPreferences
      if (resolvedEmail == null) {
        final cached = prefs.getString('last_logged_in_email');
        if (cached != null && cached.trim().isNotEmpty && isValidEmail(cached)) {
          resolvedEmail = cached.trim();
        }
      }
      
      // Priority 3: If both are unavailable, attempt to recover FirebaseAuth.currentUser
      if (resolvedEmail == null) {
        if (firebaseEmail != 'NULL' && firebaseEmail.isNotEmpty && isValidEmail(firebaseEmail)) {
          resolvedEmail = firebaseEmail;
        }
      }

      // Priority 4: Final validation check before declaring resolved recipient
      final recipientEmail = resolvedEmail ?? '';
      final emailValid = recipientEmail.isNotEmpty;

      // Fetch active receipts
      final activeResponse = await client
          .from('receipts')
          .select('id')
          .eq('user_id', userId)
          .or('is_deleted.is.null,is_deleted.eq.false');
      final activeReceiptIds = (activeResponse as List).map((r) => r['id'].toString()).toSet();

      final allWarranties = await _dbService.fetchAllWarranties(userId);
      final warranties = allWarranties.where((w) => w.receiptId == null || w.receiptId!.isEmpty || activeReceiptIds.contains(w.receiptId)).toList();

      print("Fetched ${warranties.length} active warranties for reminders");

      final userName = displayName ?? 'User';

      final isNotificationsEnabled = prefs.getBool('warranty_notif_enabled') ?? true;
      final isEmailEnabled = prefs.getBool('warranty_notif_email_enabled') ?? true;

      final remind30 = prefs.getBool('warranty_notif_30_days') ?? true;
      final remind15 = prefs.getBool('warranty_notif_15_days') ?? true;
      final remind7 = prefs.getBool('warranty_notif_7_days') ?? true;
      final remind1 = prefs.getBool('warranty_notif_1_day') ?? true;
      final remind0 = prefs.getBool('warranty_notif_on_expiry') ?? true;

      final List<DueReminder> dueNotifications = [];
      final List<DueReminder> dueEmails = [];
      
      // Separate update maps for notification and email flags (Safety Requirement)
      final Map<String, WarrantyModel> updatedWarrantiesNotif = {};
      final Map<String, WarrantyModel> updatedWarrantiesEmail = {};

      for (final w in warranties) {
        final daysRemaining = WarrantyUtils.calculateDaysRemaining(w.expiryDate);

        final isExpired = w.status == 'EXPIRED';
        bool notifDue = false;
        String notifReason = "No trigger conditions met";

        // Check local notification triggers
        if (isNotificationsEnabled) {
          if (daysRemaining <= 30 && daysRemaining > 15) {
            if (!w.notification30Sent) {
              if (remind30) {
                notifDue = true;
                notifReason = "30-day push notification due";
              } else {
                notifReason = "30-day push notification skipped (disabled in settings)";
              }
            } else {
              notifReason = "30-day push notification already sent";
            }
          } else if (daysRemaining <= 15 && daysRemaining > 7) {
            if (!w.notification15Sent) {
              if (remind15) {
                notifDue = true;
                notifReason = "15-day push notification due";
              } else {
                notifReason = "15-day push notification skipped (disabled in settings)";
              }
            } else {
              notifReason = "15-day push notification already sent";
            }
          } else if (daysRemaining <= 7 && daysRemaining > 3) {
            if (!w.notification7Sent) {
              if (remind7) {
                notifDue = true;
                notifReason = "7-day push notification due";
              } else {
                notifReason = "7-day push notification skipped (disabled in settings)";
              }
            } else {
              notifReason = "7-day push notification already sent";
            }
          } else if (daysRemaining <= 3 && daysRemaining > 1) {
            if (!w.notification3Sent) {
              notifDue = true;
              notifReason = "3-day push notification due";
            } else {
              notifReason = "3-day push notification already sent";
            }
          } else if (daysRemaining == 1) {
            if (!w.notification1Sent) {
              if (remind1) {
                notifDue = true;
                notifReason = "1-day push notification due";
              } else {
                notifReason = "1-day push notification skipped (disabled in settings)";
              }
            } else {
              notifReason = "1-day push notification already sent";
            }
          } else if (daysRemaining == 0) {
            if (!w.notificationTodaySent) {
              if (remind0) {
                notifDue = true;
                notifReason = "0-day push notification due";
              } else {
                notifReason = "0-day push notification skipped (disabled in settings)";
              }
            } else {
              notifReason = "0-day push notification already sent";
            }
          } else if (daysRemaining < 0) {
            if (!w.notificationExpiredSent) {
              notifDue = true;
              notifReason = "Expired push notification due";
            } else {
              notifReason = "Expired push notification already sent";
            }
          }
        } else {
          notifReason = "Push notifications globally disabled";
        }

        bool emailDue = false;
        String emailReason = "No trigger conditions met";

        // Check email triggers (only if email capability resolved correctly)
        if (isEmailEnabled) {
          if (!emailValid) {
            emailReason = "No valid recipient resolved (Priority 1-3 all failed).";
          } else {
            if (daysRemaining <= 30 && daysRemaining > 15) {
              if (!w.email30Sent) {
                if (remind30) {
                  emailDue = true;
                  emailReason = "30-day email reminder due";
                } else {
                  emailReason = "30-day email skipped (disabled in settings)";
                }
              } else {
                emailReason = "30-day email already sent";
              }
            } else if (daysRemaining <= 15 && daysRemaining > 7) {
              if (!w.email15Sent) {
                if (remind15) {
                  emailDue = true;
                  emailReason = "15-day email reminder due";
                } else {
                  emailReason = "15-day email skipped (disabled in settings)";
                }
              } else {
                emailReason = "15-day email already sent";
              }
            } else if (daysRemaining <= 7 && daysRemaining > 3) {
              if (!w.email7Sent) {
                if (remind7) {
                  emailDue = true;
                  emailReason = "7-day email reminder due";
                } else {
                  emailReason = "7-day email skipped (disabled in settings)";
                }
              } else {
                emailReason = "7-day email already sent";
              }
            } else if (daysRemaining <= 3 && daysRemaining > 1) {
              if (!w.email3Sent) {
                emailDue = true;
                emailReason = "3-day email reminder due";
              } else {
                emailReason = "3-day email already sent";
              }
            } else if (daysRemaining == 1) {
              if (!w.email1Sent) {
                if (remind1) {
                  emailDue = true;
                  emailReason = "1-day email reminder due";
                } else {
                  emailReason = "1-day email skipped (disabled in settings)";
                }
              } else {
                emailReason = "1-day email already sent";
              }
            } else if (daysRemaining == 0) {
              if (!w.emailTodaySent) {
                if (remind0) {
                  emailDue = true;
                  emailReason = "0-day email reminder due";
                } else {
                  emailReason = "0-day email skipped (disabled in settings)";
                }
              } else {
                emailReason = "0-day email already sent";
              }
            } else if (daysRemaining < 0) {
              if (!w.emailExpiredSent) {
                emailDue = true;
                emailReason = "Expired email reminder due";
              } else {
                emailReason = "Expired email already sent";
              }
            }
          }
        } else {
          emailReason = "Email reminders globally disabled";
        }

        final shouldSend = notifDue || emailDue;

        // Print Warranty Reminder Debug details
        print("Warranty ID");
        print(w.id ?? 'NULL');
        print("Product");
        print(w.productName);
        print("Expiry Date");
        print(w.expiryDate);
        print("Today's Date");
        print(today);
        print("Days Remaining");
        print(daysRemaining);
        print("Reminder Enabled");
        print(isNotificationsEnabled);
        print("Email Enabled");
        print(isEmailEnabled);
        print("Recipient Email");
        print(recipientEmail);
        print("Should Send");
        print(shouldSend);
        if (shouldSend) {
          print("Reason");
          print(emailDue ? emailReason : notifReason);
        } else {
          // Print actual individual reasons so we know exactly why each is skipped
          print("Skipped — Notif: $notifReason | Email: $emailReason");
        }

        if (isExpired && w.notificationExpiredSent && w.emailExpiredSent) {
          continue;
        }

        if (shouldSend) {
          if (notifDue) {
            dueNotifications.add(DueReminder(w, daysRemaining));
            updatedWarrantiesNotif[w.id!] = _applyNotificationFlag(
              updatedWarrantiesNotif[w.id!] ?? w,
              daysRemaining,
            );
          }
          if (emailDue) {
            dueEmails.add(DueReminder(w, daysRemaining));
            updatedWarrantiesEmail[w.id!] = _applyEmailFlag(
              updatedWarrantiesEmail[w.id!] ?? w,
              daysRemaining,
            );
          }
        }
      }

      // Process grouped push notifications (group by daysRemaining stage)
      try {
        final Map<int, List<DueReminder>> groupedNotifs = {};
        for (final dn in dueNotifications) {
          groupedNotifs.putIfAbsent(dn.daysRemaining, () => []);
          groupedNotifs[dn.daysRemaining]!.add(dn);
        }

        for (final entry in groupedNotifs.entries) {
          final stage = entry.key;
          final list = entry.value;

          if (list.length == 1) {
            final dn = list.first;
            final w = dn.warranty;
            await sendSingleReminder(w, dn.daysRemaining);
          } else {
            await sendGroupedReminder(list, stage);
          }
        }

        // Persist Notification flags immediately after push dispatches complete
        if (updatedWarrantiesNotif.isNotEmpty) {
          for (final updated in updatedWarrantiesNotif.values) {
            await _dbService.updateWarranty(updated, userId: updated.userId);
          }
          print("=== Notification Flags Updated for ${updatedWarrantiesNotif.length} warranties ===");
        }
      } catch (e) {
        print("Push notification dispatch error: $e");
      }

      // Process grouped email reminders (send ONE combined email summarizing all of them)
      try {
        if (dueEmails.isNotEmpty) {
          dueEmails.sort((a, b) => b.daysRemaining.compareTo(a.daysRemaining));

          final List<Map<String, String>> productsInfo = dueEmails.map((de) {
            final w = de.warranty;
            return {
              'name': w.productName,
              'merchant': w.merchantName,
              'purchaseDate': w.purchaseDate,
              'expiryDate': w.expiryDate,
              'daysRemaining': de.daysRemaining.toString(),
              'invoiceNumber': w.invoiceNumber ?? '',
            };
          }).toList();

          final cachedEmail = prefs.getString('last_logged_in_email') ?? 'NULL';

          print("SMTP Start");
          print("Calling sendWarrantyReminderEmail()");

          final warrantyIds = dueEmails.map((de) => de.warranty.id ?? 'NULL').join(', ');
          final productNames = dueEmails.map((de) => de.warranty.productName).join(', ');

          await _emailService.sendGroupedWarrantyReminderEmail(
            recipientEmail: recipientEmail,
            userName: userName,
            products: productsInfo,
            loggedUserUid: userId,
            loggedUserEmail: recipientEmail,
            warrantyOwnerUid: dueEmails.first.warranty.userId,
            warrantyOwnerEmail: recipientEmail,
            warrantyId: warrantyIds,
            productName: productNames,
          );

          print("SMTP End");
          print("SMTP Result");
          print("SUCCESS");
          print("Email Sent Successfully");
          print("Warranty Reminder Email Sent");

          // Save a DB notification record for each item in the email
          for (final de in dueEmails) {
            final w = de.warranty;
            final bodyText = 'Grouped Email Sent: ${w.productName} warranty reminder.';
            try {
              await _notiDbService.saveNotification(
                NotificationModel(
                  userId: w.userId,
                  warrantyId: w.id,
                  receiptId: w.receiptId,
                  title: 'Email Reminder Sent',
                  message: bodyText,
                  type: 'EMAIL',
                  createdAt: DateTime.now(),
                ),
              );
            } catch (e) {
              print("DB Notification Save Error: $e");
            }
          }

          // Persist Email Flags ONLY upon successful SMTP dispatch! (Flag Safety Requirement)
          if (updatedWarrantiesEmail.isNotEmpty) {
            for (final updated in updatedWarrantiesEmail.values) {
              await _dbService.updateWarranty(updated, userId: updated.userId);
            }
            print("=== Email Flags Updated for ${updatedWarrantiesEmail.length} warranties ===");
            print("Flags Updated");
            print("YES");
          }

          // Final verification matching print checks
          print("Firebase Email");
          print(firebaseEmail);
          print("Cached Email");
          print(cachedEmail);
          print("Resolved Recipient");
          print(recipientEmail);
          print("Message.recipients");
          print(recipientEmail);
          print("SMTP Result");
          print("SUCCESS");

        }
      } catch (e) {
        print("SMTP End");
        print("SMTP Result");
        print("FAILED");
        print("Email Failed");
        print("Email sending failed with error: $e");
      }

    } catch (e) {
      print("Global checking execution error: $e");
    }
  }

  /// Sends reminder for a single product.
  Future<void> sendSingleReminder(WarrantyModel w, int daysRemaining) async {
    final isExpired = daysRemaining < 0;
    String subjectText = 'Warranty Reminder';
    String bodyText = '';

    if (daysRemaining <= 30 && daysRemaining > 15) {
      bodyText = 'Your ${w.productName} warranty expires in 30 days.';
    } else if (daysRemaining <= 15 && daysRemaining > 7) {
      bodyText = 'Only 15 days remaining for your ${w.productName} warranty.';
    } else if (daysRemaining <= 7 && daysRemaining > 3) {
      bodyText = 'Only one week remaining for your ${w.productName} warranty.';
    } else if (daysRemaining <= 3 && daysRemaining > 1) {
      bodyText = 'Your warranty expires in 3 days.';
    } else if (daysRemaining == 1) {
      bodyText = 'Your warranty expires tomorrow.';
    } else if (daysRemaining == 0) {
      subjectText = 'Warranty Expired Today';
      bodyText = 'Your warranty expires today.';
    } else if (isExpired) {
      subjectText = 'Warranty Expired';
      bodyText = 'Your warranty has expired.';
    }

    final id = calculateNotificationId(w.id ?? '', daysRemaining);
    final payload = jsonEncode({
      'receiptId': w.receiptId,
      'warrantyId': w.id,
      'productName': w.productName,
      'isGrouped': false,
    });

    // Cancel any pre-scheduled zonedSchedule alarm with this exact ID first.
    // This prevents the scheduled alarm from firing a duplicate later.
    // Cancelling before show: clears the future alarm, then we re-post the notification.
    await _notificationService.cancelNotification(id);
    await _notificationService.showNotification(
      id: id,
      title: subjectText,
      body: bodyText,
      payload: payload,
    );

    try {
      await _notiDbService.saveNotification(
        NotificationModel(
          userId: w.userId,
          warrantyId: w.id,
          receiptId: w.receiptId,
          title: subjectText,
          message: bodyText,
          type: 'WARRANTY',
          createdAt: DateTime.now(),
        ),
      );
    } catch (e) {
      print('Error storing warranty notification in DB: $e');
    }
  }

  /// Sends grouped reminder.
  Future<void> sendGroupedReminder(List<DueReminder> list, int stage) async {
    final count = list.length;
    final String title = 'Warranty Reminder';
    final String body;

    if (stage <= 30 && stage > 15) {
      body = '$count products expire in 30 days. Tap to view details.';
    } else if (stage <= 15 && stage > 7) {
      body = '$count products expire in 15 days. Tap to view details.';
    } else if (stage <= 7 && stage > 3) {
      body = '$count products expire in one week. Tap to view details.';
    } else if (stage == 1) {
      body = '$count products expire tomorrow. Tap to view details.';
    } else if (stage == 0) {
      body = '$count products expire today. Tap to view details.';
    } else {
      body = '$count products expire in $stage days. Tap to view details.';
    }

    // Generate deterministically grouped ID using today's yyyymmdd and stage
    final now = DateTime.now();
    final yyyymmdd = (now.year * 10000) + (now.month * 100) + now.day;
    final id = ((yyyymmdd.hashCode * 37) + stage) & 0x7FFFFFFF;

    final payload = jsonEncode({
      'isGrouped': true,
      'warrantyIds': list.map((it) => it.warranty.id).toList(),
      'daysBefore': stage,
    });

    // Cancel any pre-scheduled grouped zonedSchedule alarm with this exact ID first.
    await _notificationService.cancelNotification(id);
    await _notificationService.showNotification(
      id: id,
      title: title,
      body: body,
      payload: payload,
    );

    for (final dn in list) {
      final w = dn.warranty;
      try {
        await _notiDbService.saveNotification(
          NotificationModel(
            userId: w.userId,
            warrantyId: w.id,
            receiptId: w.receiptId,
            title: title,
            message: 'Grouped Reminder: ${w.productName} warranty expiration alert.',
            type: 'WARRANTY',
            createdAt: DateTime.now(),
          ),
        );
      } catch (e) {
        print('Error storing grouped notification in DB: $e');
      }
    }
  }
}

class DueReminder {
  final WarrantyModel warranty;
  final int daysRemaining;
  DueReminder(this.warranty, this.daysRemaining);
}
