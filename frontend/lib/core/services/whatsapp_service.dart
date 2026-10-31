import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:receipto/core/services/firebase_auth_service.dart';

final whatsappServiceProvider = Provider<WhatsAppService>((ref) {
  return WhatsAppService(Supabase.instance.client);
});

final userWhatsAppNumberProvider = FutureProvider.autoDispose<String?>((ref) async {
  final authUser = ref.watch(authStateChangesProvider).value ??
      ref.watch(firebaseAuthServiceProvider).currentUser;
  final userId = authUser?.uid;
  if (userId == null) return null;

  final service = ref.watch(whatsappServiceProvider);
  return await service.getLinkedPhoneNumber(userId);
});

class WhatsAppService {
  final SupabaseClient _supabase;

  WhatsAppService([SupabaseClient? supabase])
      : _supabase = supabase ?? Supabase.instance.client;

  /// Fetches the linked phone number for the given user ID, if any.
  Future<String?> getLinkedPhoneNumber(String userId) async {
    try {
      final List<dynamic> records = await _supabase
          .from('whatsapp_users')
          .select('phone_number, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      if (records.isNotEmpty) {
        // 1. Prefer standard phone numbers (10 to 13 digits) over internal LIDs (14+ digits)
        for (final row in records) {
          final phone = row['phone_number'] as String?;
          if (phone != null && !phone.startsWith('pending:')) {
            final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
            if (digits.length >= 10 && digits.length <= 13) {
              return phone;
            }
          }
        }

        // 2. Fallback to any valid non-pending record
        for (final row in records) {
          final phone = row['phone_number'] as String?;
          if (phone != null && !phone.startsWith('pending:')) {
            return phone;
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching linked WhatsApp phone: $e');
      return null;
    }
  }

  /// Normalizes and links the user's phone number to their Firebase UID.
  /// Replaces any existing linked number for this user.
  Future<bool> linkPhoneNumber({
    required String userId,
    required String rawPhoneNumber,
  }) async {
    try {
      final cleanPhone = normalizePhoneNumber(rawPhoneNumber);
      if (cleanPhone.isEmpty || cleanPhone.length < 10) {
        throw Exception('Invalid phone number length.');
      }

      // Remove existing mapping for this user ID first to prevent duplicate assignments
      await _supabase.from('whatsapp_users').delete().eq('user_id', userId);

      // Insert or upsert new mapping
      await _supabase.from('whatsapp_users').upsert({
        'phone_number': cleanPhone,
        'user_id': userId,
      });

      return true;
    } catch (e) {
      debugPrint('Error linking WhatsApp phone number: $e');
      rethrow;
    }
  }

  /// Unlinks the WhatsApp phone number for the user.
  Future<bool> unlinkPhoneNumber(String userId, {String? phoneNumber}) async {
    try {
      // 1. Delete all records matching this user_id (primary number and any linked device IDs)
      await _supabase.from('whatsapp_users').delete().eq('user_id', userId);

      // 2. Also delete by phone number directly if provided to ensure complete purge
      if (phoneNumber != null && phoneNumber.trim().isNotEmpty) {
        final clean = normalizePhoneNumber(phoneNumber);
        await _supabase.from('whatsapp_users').delete().eq('phone_number', clean);
      }
      return true;
    } catch (e) {
      debugPrint('Error unlinking WhatsApp phone: $e');
      rethrow;
    }
  }

  /// Creates a 6-digit verification code and registers it as a pending linking attempt.
  Future<String> createVerificationCode({
    required String userId,
    required String rawPhoneNumber,
  }) async {
    try {
      final cleanPhone = normalizePhoneNumber(rawPhoneNumber);
      if (cleanPhone.isEmpty || cleanPhone.length < 10) {
        throw Exception('Invalid phone number format.');
      }

      // Generate a cryptographically secure 6-digit random code
      final random = Random.secure();
      final code = (100000 + random.nextInt(900000)).toString();

      // Clear any previous pending record for this phone number
      await _supabase.from('whatsapp_users').delete().eq('phone_number', cleanPhone);

      // Register the pending verification
      await _supabase.from('whatsapp_users').insert({
        'phone_number': cleanPhone,
        'user_id': 'pending:$code:$userId',
      });

      return code;
    } catch (e) {
      debugPrint('Error creating verification code: $e');
      rethrow;
    }
  }

  /// Checks if the given phone number has been verified by the WhatsApp Bot.
  Future<bool> checkVerificationStatus({
    required String userId,
    required String rawPhoneNumber,
  }) async {
    try {
      final cleanPhone = normalizePhoneNumber(rawPhoneNumber);
      final List<dynamic> response = await _supabase
          .from('whatsapp_users')
          .select('user_id')
          .eq('phone_number', cleanPhone);

      if (response.isNotEmpty && response[0]['user_id'] != null) {
        final currentUserId = response[0]['user_id'] as String;
        // If it equals the userId and no longer starts with 'pending:', it is verified!
        return currentUserId == userId;
      }
      return false;
    } catch (e) {
      debugPrint('Error checking verification status: $e');
      return false;
    }
  }

  /// Cancels an unverified pending verification code.
  Future<void> cancelVerification(String rawPhoneNumber) async {
    try {
      final cleanPhone = normalizePhoneNumber(rawPhoneNumber);
      final response = await _supabase
          .from('whatsapp_users')
          .select('user_id')
          .eq('phone_number', cleanPhone)
          .maybeSingle();

      if (response != null && (response['user_id'] as String).startsWith('pending:')) {
        await _supabase.from('whatsapp_users').delete().eq('phone_number', cleanPhone);
      }
    } catch (e) {
      debugPrint('Error canceling verification: $e');
    }
  }

  /// Default bot phone number if not configured in .env
  static const String defaultBotPhone = '918431890337';

  /// Launches WhatsApp directly into the chat with the bot.
  Future<bool> openWhatsAppChat({
    String? botPhoneNumber,
    String defaultMessage = 'Hi! Here is my receipt.',
  }) async {
    try {
      final configuredPhone = botPhoneNumber ??
          dotenv.env['WHATSAPP_BOT_NUMBER'] ??
          defaultBotPhone;
      final cleanBot = configuredPhone.replaceAll(RegExp(r'[^\d]'), '');

      // Try native WhatsApp app scheme first for direct, seamless opening
      final nativeUri = Uri.parse(
        'whatsapp://send?phone=$cleanBot&text=${Uri.encodeComponent(defaultMessage)}',
      );
      if (await canLaunchUrl(nativeUri)) {
        return await launchUrl(
          nativeUri,
          mode: LaunchMode.externalApplication,
        );
      }

      // Fallback to wa.me deep link
      final webUri = Uri.parse(
        'https://wa.me/$cleanBot?text=${Uri.encodeComponent(defaultMessage)}',
      );
      return await launchUrl(
        webUri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('Error launching WhatsApp: $e');
      return false;
    }
  }

  /// Formats raw phone number to E.164 standard (e.g. `+919876543210`).
  static String normalizePhoneNumber(String phone) {
    String cleaned = phone.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (!cleaned.startsWith('+')) {
      if (cleaned.length == 10) {
        // Default to India (+91) if 10-digit number without country code
        cleaned = '+91$cleaned';
      } else {
        cleaned = '+$cleaned';
      }
    }
    return cleaned;
  }
}
