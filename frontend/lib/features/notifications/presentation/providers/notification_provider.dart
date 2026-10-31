import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receipto/core/services/firebase_auth_service.dart';
import 'package:receipto/core/services/notification_database_service.dart';
import 'package:receipto/features/notifications/domain/models/notification_model.dart';

final notificationNotifierProvider = StateNotifierProvider<NotificationNotifier, AsyncValue<List<NotificationModel>>>((ref) {
  final dbService = ref.watch(notificationDatabaseServiceProvider);
  final authUser = ref.watch(authStateChangesProvider).value;
  final userId = authUser?.uid ?? ref.watch(firebaseAuthServiceProvider).currentUser?.uid;
  return NotificationNotifier(dbService, userId ?? '');
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final state = ref.watch(notificationNotifierProvider);
  return state.maybeWhen(
    data: (list) => list.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});

class NotificationNotifier extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  final NotificationDatabaseService _dbService;
  final String _userId;

  NotificationNotifier(this._dbService, this._userId) : super(const AsyncValue.loading()) {
    loadNotifications();
  }

  /// Fetches user notification records.
  Future<void> loadNotifications() async {
    if (_userId.isEmpty) {
      if (mounted) state = const AsyncValue.data([]);
      return;
    }
    try {
      final notifications = await _dbService.fetchNotifications(_userId);
      if (mounted) state = AsyncValue.data(notifications);
    } catch (e, stack) {
      if (mounted) state = AsyncValue.error(e, stack);
    }
  }

  /// Triggers full state reload.
  Future<void> refresh() async {
    await loadNotifications();
  }

  /// Marks a specific notification log as read.
  Future<void> markRead(String id) async {
    if (_userId.isEmpty) return;
    try {
      await _dbService.markAsRead(id, userId: _userId);
      if (!mounted) return;
      state.whenData((list) {
        if (mounted) {
          state = AsyncValue.data(
            list.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList(),
          );
        }
      });
    } catch (e) {
      if (kDebugMode) print('Error marking notification as read: $e');
    }
  }

  /// Marks all current user notifications as read in database.
  Future<void> markAllAsRead() async {
    if (_userId.isEmpty) return;
    try {
      state.whenData((list) async {
        for (final n in list) {
          if (!n.isRead && n.id != null) {
            await _dbService.markAsRead(n.id!, userId: _userId);
          }
        }
        if (mounted) {
          state = AsyncValue.data(
            list.map((n) => n.copyWith(isRead: true)).toList(),
          );
        }
      });
    } catch (e) {
      if (kDebugMode) print('Error marking all notifications as read: $e');
    }
  }

  /// Deletes a specific notification log.
  Future<void> delete(String id) async {
    if (_userId.isEmpty) return;
    try {
      await _dbService.deleteNotification(id, userId: _userId);
      if (!mounted) return;
      state.whenData((list) {
        if (mounted) {
          state = AsyncValue.data(
            list.where((n) => n.id != id).toList(),
          );
        }
      });
    } catch (e) {
      if (kDebugMode) print('Error deleting notification: $e');
    }
  }

  /// Deletes all notifications for current user.
  Future<void> deleteAll() async {
    if (_userId.isEmpty) return;
    try {
      await _dbService.deleteAllNotifications(_userId);
      if (mounted) state = const AsyncValue.data([]);
    } catch (e) {
      if (kDebugMode) print('Error deleting all notifications: $e');
    }
  }
}
