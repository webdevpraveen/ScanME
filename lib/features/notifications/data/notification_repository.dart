import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/supabase_constants.dart';
import '../../../core/utils/logger.dart';
import '../../../shared/models/notification_model.dart';

class NotificationRepository {
  NotificationRepository(this._client);

  final SupabaseClient _client;

  /// Fetch notifications for a user, sorted by newest first
  Future<List<NotificationModel>> getNotifications(String userId) async {
    try {
      AppLogger.info('Fetching notifications for user: $userId', 'NotificationRepository');
      final response = await _client
          .from(SupabaseConstants.notificationsTable)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => NotificationModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      AppLogger.error('Error fetching notifications', e, stack, 'NotificationRepository');
      rethrow;
    }
  }

  /// Mark a single notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      AppLogger.info('Marking notification as read: $notificationId', 'NotificationRepository');
      await _client
          .from(SupabaseConstants.notificationsTable)
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e, stack) {
      AppLogger.error('Error marking notification as read', e, stack, 'NotificationRepository');
      rethrow;
    }
  }

  /// Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    try {
      AppLogger.info('Marking all notifications as read for user: $userId', 'NotificationRepository');
      await _client
          .from(SupabaseConstants.notificationsTable)
          .update({'is_read': true})
          .eq('user_id', userId);
    } catch (e, stack) {
      AppLogger.error('Error marking all notifications as read', e, stack, 'NotificationRepository');
      rethrow;
    }
  }

  /// Register or update an FCM token for push notifications
  Future<void> registerDeviceToken({
    required String userId,
    required String token,
    required String platform,
    required String deviceInfo,
  }) async {
    try {
      AppLogger.info('Registering device token for: $userId ($platform)', 'NotificationRepository');
      
      // We upsert: if the token already exists for this user, it updates, otherwise inserts.
      await _client.from(SupabaseConstants.userDevicesTable).upsert({
        'user_id': userId,
        'device_token': token,
        'platform': platform,
        'device_info': deviceInfo,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,device_token');
    } catch (e, stack) {
      AppLogger.error('Error registering device token', e, stack, 'NotificationRepository');
      // Do not block app startup if token registration fails
    }
  }

  /// Remove an FCM token (e.g., on logout)
  Future<void> removeDeviceToken(String userId, String token) async {
    try {
      AppLogger.info('Removing device token for user: $userId', 'NotificationRepository');
      await _client
          .from(SupabaseConstants.userDevicesTable)
          .delete()
          .eq('user_id', userId)
          .eq('device_token', token);
    } catch (e, stack) {
      AppLogger.error('Error removing device token', e, stack, 'NotificationRepository');
    }
  }
}

/// Provider for NotificationRepository
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(Supabase.instance.client);
});
