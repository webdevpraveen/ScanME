import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/history_repository.dart';
import '../../auth/providers/auth_providers.dart';

class ScanHistoryNotifier extends AutoDisposeAsyncNotifier<List<Map<String, dynamic>>> {
  @override
  FutureOr<List<Map<String, dynamic>>> build() async {
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    if (profile == null) return const [];

    return ref.read(historyRepositoryProvider).getScanHistory(profile.id);
  }

  /// Delete a single entry from history
  Future<void> deleteEntry(String id) async {
    final profile = ref.read(currentUserProfileProvider).valueOrNull;
    if (profile == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(historyRepositoryProvider).deleteHistoryEntry(id);
      return ref.read(historyRepositoryProvider).getScanHistory(profile.id);
    });
  }

  /// Clear all history
  Future<void> clearAll() async {
    final profile = ref.read(currentUserProfileProvider).valueOrNull;
    if (profile == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(historyRepositoryProvider).clearHistory(profile.id);
      return const [];
    });
  }
}

/// Provider for managing scan history state
final scanHistoryProvider = AutoDisposeAsyncNotifierProvider<ScanHistoryNotifier, List<Map<String, dynamic>>>(
  ScanHistoryNotifier.new,
);
