import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:receipto/features/notifications/domain/models/notification_model.dart';

final notificationDatabaseServiceProvider = Provider<NotificationDatabaseService>((ref) {
  return NotificationDatabaseService(Supabase.instance.client);
});

class NotificationDatabaseService {
  final SupabaseClient _client;
  static const String _prefPrefix = 'offline_notifications_user_';

  NotificationDatabaseService(this._client);

  String _userKey(String userId) => '$_prefPrefix$userId';

  /// Saves a new notification log both locally and in the Supabase table.
  Future<NotificationModel> saveNotification(NotificationModel notification) async {
    final notiWithId = notification.id != null
        ? notification
        : notification.copyWith(id: DateTime.now().millisecondsSinceEpoch.toString());

    // 1. Save locally first for instant, resilient offline availability
    await _saveNotificationLocally(notiWithId);

    // 2. Persist to Supabase if possible
    try {
      final payload = notiWithId.toJson();
      final response = await _client
          .from('notifications')
          .insert(payload)
          .select()
          .maybeSingle();
      if (response != null) {
        return NotificationModel.fromJson(response);
      }
    } catch (e) {
      if (kDebugMode) print('[NotificationDatabaseService] Remote save skipped ($e), saved locally.');
    }

    return notiWithId;
  }

  /// Fetches notification logs for a user sorted by creation date descending.
  Future<List<NotificationModel>> fetchNotifications(String userId) async {
    if (userId.isEmpty) return [];

    try {
      final intId = int.tryParse(userId);
      final query = _client.from('notifications').select();
      
      final dynamic response = await (intId != null 
          ? query.or('user_id.eq.$intId,user_id.eq.$userId') 
          : query.eq('user_id', userId))
          .order('created_at', ascending: false);

      final list = (response as List)
          .map((json) => NotificationModel.fromJson(json as Map<String, dynamic>))
          .toList();

      // Sync and merge with local cache
      await _cacheNotificationsLocally(userId, list);
      return list;
    } catch (e) {
      if (kDebugMode) {
        print('[NotificationDatabaseService] Remote fetch notice ($e). Serving local notifications cache.');
      }
      return await getLocalNotifications(userId);
    }
  }

  /// Marks a specific notification as read for a specific user.
  Future<void> markAsRead(String id, {required String userId}) async {
    // 1. Update local cache
    await _updateLocalNotification(userId, id, (n) => n.copyWith(isRead: true));

    // 2. Update remote
    try {
      final intId = int.tryParse(id);
      final intUserId = int.tryParse(userId);
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', intId ?? id)
          .eq('user_id', intUserId ?? userId);
    } catch (e) {
      if (kDebugMode) print('[NotificationDatabaseService] Remote markAsRead skipped: $e');
    }
  }

  /// Deletes a specific notification for a specific user.
  Future<void> deleteNotification(String id, {required String userId}) async {
    // 1. Delete from local cache
    await _deleteLocalNotification(userId, id);

    // 2. Delete from remote
    try {
      final intId = int.tryParse(id);
      final intUserId = int.tryParse(userId);
      await _client
          .from('notifications')
          .delete()
          .eq('id', intId ?? id)
          .eq('user_id', intUserId ?? userId);
    } catch (e) {
      if (kDebugMode) print('[NotificationDatabaseService] Remote deleteNotification skipped: $e');
    }
  }

  /// Deletes all notifications for a specific user.
  Future<void> deleteAllNotifications(String userId) async {
    // 1. Clear local cache
    await _clearLocalNotifications(userId);

    // 2. Delete from remote
    try {
      final intUserId = int.tryParse(userId);
      await _client
          .from('notifications')
          .delete()
          .eq('user_id', intUserId ?? userId);
    } catch (e) {
      if (kDebugMode) print('[NotificationDatabaseService] Remote deleteAllNotifications skipped: $e');
    }
  }

  // --- Local Cache Helpers ---

  Future<List<NotificationModel>> getLocalNotifications(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_userKey(userId));
      if (raw == null || raw.isEmpty) return [];
      final List<dynamic> list = jsonDecode(raw);
      return list.map((item) => NotificationModel.fromJson(Map<String, dynamic>.from(item as Map))).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _cacheNotificationsLocally(String userId, List<NotificationModel> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = list.map((n) => n.toJson()).toList();
      await prefs.setString(_userKey(userId), jsonEncode(jsonList));
    } catch (_) {}
  }

  Future<void> _saveNotificationLocally(NotificationModel notification) async {
    try {
      final current = await getLocalNotifications(notification.userId);
      final updated = [notification, ...current.where((n) => n.id != notification.id)];
      await _cacheNotificationsLocally(notification.userId, updated);
    } catch (_) {}
  }

  Future<void> _updateLocalNotification(String userId, String id, NotificationModel Function(NotificationModel) updater) async {
    try {
      final current = await getLocalNotifications(userId);
      final updated = current.map((n) => n.id == id ? updater(n) : n).toList();
      await _cacheNotificationsLocally(userId, updated);
    } catch (_) {}
  }

  Future<void> _deleteLocalNotification(String userId, String id) async {
    try {
      final current = await getLocalNotifications(userId);
      final updated = current.where((n) => n.id != id).toList();
      await _cacheNotificationsLocally(userId, updated);
    } catch (_) {}
  }

  Future<void> _clearLocalNotifications(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey(userId));
    } catch (_) {}
  }
}
