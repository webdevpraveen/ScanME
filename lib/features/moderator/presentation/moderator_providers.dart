import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/moderator_repository.dart';
import '../../auth/providers/auth_providers.dart';

class PendingVerificationsNotifier extends AutoDisposeAsyncNotifier<List<Map<String, dynamic>>> {
  @override
  FutureOr<List<Map<String, dynamic>>> build() async {
    return ref.read(moderatorRepositoryProvider).getPendingVerifications();
  }

  /// Approve verification
  Future<void> approve(String verificationId, String studentId) async {
    final moderator = ref.read(currentUserProfileProvider).valueOrNull;
    if (moderator == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(moderatorRepositoryProvider).reviewVerification(
            verificationId: verificationId,
            studentId: studentId,
            moderatorId: moderator.id,
            approved: true,
          );
      return ref.read(moderatorRepositoryProvider).getPendingVerifications();
    });
  }

  /// Reject verification
  Future<void> reject(String verificationId, String studentId, String notes) async {
    final moderator = ref.read(currentUserProfileProvider).valueOrNull;
    if (moderator == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(moderatorRepositoryProvider).reviewVerification(
            verificationId: verificationId,
            studentId: studentId,
            moderatorId: moderator.id,
            approved: false,
            notes: notes,
          );
      return ref.read(moderatorRepositoryProvider).getPendingVerifications();
    });
  }
}

/// Provider for managing pending reviews list
final pendingVerificationsProvider =
    AutoDisposeAsyncNotifierProvider<PendingVerificationsNotifier, List<Map<String, dynamic>>>(
  PendingVerificationsNotifier.new,
);
