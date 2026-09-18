import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:receipto/features/notifications/domain/models/notification_model.dart';

final notificationDatabaseServiceProvider = Provider<NotificationDatabaseService>((ref) {
  return NotificationDatabaseService(Supabase.instance.client);
});

class NotificationDatabaseService {
  final SupabaseClient _client;

  NotificationDatabaseService(this._client);

  /// Saves a new notification log in the Supabase table.
  Future<NotificationModel> saveNotification(NotificationModel notification) async {
    final response = await _client
        .from('notifications')
        .insert(notification.toJson())
        .select()
        .single();
    return NotificationModel.fromJson(response);
  }

  /// Fetches notification logs for a user sorted by creation date descending.
  Future<List<NotificationModel>> fetchNotifications(String userId) async {
    final response = await _client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    
    return (response as List)
        .map((json) => NotificationModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Marks a specific notification as read for a specific user.
  Future<void> markAsRead(String id, {required String userId}) async {
    final intId = int.tryParse(id);
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', intId ?? id)
        .eq('user_id', userId);
  }

  /// Deletes a specific notification for a specific user.
  Future<void> deleteNotification(String id, {required String userId}) async {
    final intId = int.tryParse(id);
    await _client
        .from('notifications')
        .delete()
        .eq('id', intId ?? id)
        .eq('user_id', userId);
  }

  /// Deletes all notifications for a specific user.
  Future<void> deleteAllNotifications(String userId) async {
    await _client
        .from('notifications')
        .delete()
        .eq('user_id', userId);
  }
}
