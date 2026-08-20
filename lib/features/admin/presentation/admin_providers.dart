import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/admin_repository.dart';

/// Provider for admin dashboard metrics
final adminMetricsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.watch(adminRepositoryProvider).getDashboardMetrics();
});

/// Search query state for user management
final userSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

/// Role filter state for user management
final userRoleFilterProvider = StateProvider.autoDispose<String>((ref) => 'all');

/// Future provider to fetch users list based on search and filters
final adminUsersProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final query = ref.watch(userSearchQueryProvider);
  final roleFilter = ref.watch(userRoleFilterProvider);
  return ref.watch(adminRepositoryProvider).getUsers(query: query, roleFilter: roleFilter);
});


/// Async notifier for application configuration settings
class AdminConfigsNotifier extends AutoDisposeAsyncNotifier<List<Map<String, dynamic>>> {
  @override
  FutureOr<List<Map<String, dynamic>>> build() async {
    return ref.watch(adminRepositoryProvider).getAppConfigs();
  }

  Future<void> updateConfig(String key, dynamic value) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(adminRepositoryProvider).updateAppConfig(key, value);
      return ref.read(adminRepositoryProvider).getAppConfigs();
    });
  }
}

final adminConfigsProvider =
    AutoDisposeAsyncNotifierProvider<AdminConfigsNotifier, List<Map<String, dynamic>>>(
  AdminConfigsNotifier.new,
);

/// Async notifier for feature flags
class AdminFeatureFlagsNotifier extends AutoDisposeAsyncNotifier<List<Map<String, dynamic>>> {
  @override
  FutureOr<List<Map<String, dynamic>>> build() async {
    return ref.watch(adminRepositoryProvider).getFeatureFlags();
  }

  Future<void> toggleFlag(String name, bool isEnabled) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(adminRepositoryProvider).toggleFeatureFlag(name, isEnabled);
      return ref.read(adminRepositoryProvider).getFeatureFlags();
    });
  }
}

final adminFeatureFlagsProvider =
    AutoDisposeAsyncNotifierProvider<AdminFeatureFlagsNotifier, List<Map<String, dynamic>>>(
  AdminFeatureFlagsNotifier.new,
);

/// Search query state for audit logs
final auditLogsSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

/// Future provider to fetch audit logs based on search query
final adminAuditLogsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final query = ref.watch(auditLogsSearchQueryProvider);
  return ref.watch(adminRepositoryProvider).getAuditLogs(query: query);
});
