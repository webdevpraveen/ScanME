import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/notification_repository.dart';
import '../../auth/providers/auth_providers.dart';
import '../../../shared/models/notification_model.dart';

class UserNotificationsNotifier extends AutoDisposeAsyncNotifier<List<NotificationModel>> {
  @override
  FutureOr<List<NotificationModel>> build() async {
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    if (profile == null) return const [];

    return ref.read(notificationRepositoryProvider).getNotifications(profile.id);
  }

  /// Mark single notification as read
  Future<void> markAsRead(String id) async {
    final profile = ref.read(currentUserProfileProvider).valueOrNull;
    if (profile == null) return;

    // Optimistically update local state
    final previousState = state;
    if (state.hasValue) {
      final updatedList = state.value!.map((n) {
        if (n.id == id) {
          return n.copyWith(isRead: true);
        }
        return n;
      }).toList();
      state = AsyncValue.data(updatedList);
    }

    try {
      await ref.read(notificationRepositoryProvider).markAsRead(id);
    } catch (e) {
      // Revert if error
      state = previousState;
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final profile = ref.read(currentUserProfileProvider).valueOrNull;
    if (profile == null) return;

    final previousState = state;
    if (state.hasValue) {
      final updatedList = state.value!.map((n) => n.copyWith(isRead: true)).toList();
      state = AsyncValue.data(updatedList);
    }

    try {
      await ref.read(notificationRepositoryProvider).markAllAsRead(profile.id);
    } catch (e) {
      state = previousState;
    }
  }
}

/// Provider for notifications list
final userNotificationsProvider =
    AutoDisposeAsyncNotifierProvider<UserNotificationsNotifier, List<NotificationModel>>(
  UserNotificationsNotifier.new,
);

/// Derived provider to count unread notifications
final unreadNotificationsCountProvider = Provider.autoDispose<int>((ref) {
  final notifications = ref.watch(userNotificationsProvider).valueOrNull ?? [];
  return notifications.where((n) => !n.isRead).length;
});
