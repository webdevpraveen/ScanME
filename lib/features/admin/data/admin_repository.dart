import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/supabase_constants.dart';
import '../../../core/utils/logger.dart';

class AdminRepository {
  AdminRepository(this._client);

  final SupabaseClient _client;

  /// Fetch list of users with search and filter capability
  Future<List<Map<String, dynamic>>> getUsers({String? query, String? roleFilter}) async {
    try {
      AppLogger.info('Fetching users list', 'AdminRepository');
      var builder = _client
          .from(SupabaseConstants.profilesTable)
          .select('*');

      if (roleFilter != null && roleFilter != 'all') {
        builder = builder.eq('role', roleFilter);
      }

      if (query != null && query.isNotEmpty) {
        builder = builder.or('full_name.ilike.%$query%,roll_number.ilike.%$query%,email.ilike.%$query%');
      }

      final response = await builder.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e, stack) {
      AppLogger.error('Error fetching users in admin', e, stack, 'AdminRepository');
      rethrow;
    }
  }

  /// Update a user's role
  Future<void> updateUserRole(String userId, String role) async {
    try {
      AppLogger.info('Updating user role: $userId to $role', 'AdminRepository');
      await _client
          .from(SupabaseConstants.profilesTable)
          .update({'role': role})
          .eq('id', userId);
    } catch (e, stack) {
      AppLogger.error('Error updating user role', e, stack, 'AdminRepository');
      rethrow;
    }
  }

  /// Disable or restore a user account status
  Future<void> updateAccountStatus(String userId, String status) async {
    try {
      AppLogger.info('Updating account status: $userId to $status', 'AdminRepository');
      await _client
          .from(SupabaseConstants.profilesTable)
          .update({
            'account_status': status,
            'deleted_at': status == 'soft_deleted' ? DateTime.now().toIso8601String() : null,
          })
          .eq('id', userId);
    } catch (e, stack) {
      AppLogger.error('Error updating account status', e, stack, 'AdminRepository');
      rethrow;
    }
  }



  /// Fetch all application configurations
  Future<List<Map<String, dynamic>>> getAppConfigs() async {
    try {
      AppLogger.info('Fetching app config in admin', 'AdminRepository');
      final response = await _client
          .from(SupabaseConstants.appConfigTable)
          .select()
          .order('key');
      return List<Map<String, dynamic>>.from(response);
    } catch (e, stack) {
      AppLogger.error('Error fetching app configs', e, stack, 'AdminRepository');
      rethrow;
    }
  }

  /// Update an application configuration value
  Future<void> updateAppConfig(String key, dynamic value) async {
    try {
      AppLogger.info('Updating app config key: $key', 'AdminRepository');
      await _client
          .from(SupabaseConstants.appConfigTable)
          .update({'value': value})
          .eq('key', key);
    } catch (e, stack) {
      AppLogger.error('Error updating app config', e, stack, 'AdminRepository');
      rethrow;
    }
  }

  /// Fetch all feature flags
  Future<List<Map<String, dynamic>>> getFeatureFlags() async {
    try {
      AppLogger.info('Fetching feature flags in admin', 'AdminRepository');
      final response = await _client
          .from(SupabaseConstants.featureFlagsTable)
          .select()
          .order('name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e, stack) {
      AppLogger.error('Error fetching feature flags', e, stack, 'AdminRepository');
      rethrow;
    }
  }

  /// Toggle feature flag status
  Future<void> toggleFeatureFlag(String name, bool isEnabled) async {
    try {
      AppLogger.info('Toggling feature flag: $name to $isEnabled', 'AdminRepository');
      await _client
          .from(SupabaseConstants.featureFlagsTable)
          .update({'is_enabled': isEnabled})
          .eq('name', name);
    } catch (e, stack) {
      AppLogger.error('Error toggling feature flag', e, stack, 'AdminRepository');
      rethrow;
    }
  }

  /// Fetch audit logs with optional search query
  Future<List<Map<String, dynamic>>> getAuditLogs({String? query}) async {
    try {
      AppLogger.info('Fetching audit logs', 'AdminRepository');
      var builder = _client
          .from(SupabaseConstants.auditLogsTable)
          .select();

      if (query != null && query.isNotEmpty) {
        builder = builder.or('action.ilike.%$query%,target_type.ilike.%$query%');
      }

      final response = await builder.order('created_at', ascending: false).limit(100);
      return List<Map<String, dynamic>>.from(response);
    } catch (e, stack) {
      AppLogger.error('Error fetching audit logs', e, stack, 'AdminRepository');
      rethrow;
    }
  }

  /// Fetch key metrics for admin dashboard cards
  Future<Map<String, dynamic>> getDashboardMetrics() async {
    try {
      AppLogger.info('Fetching dashboard metrics', 'AdminRepository');
      
      final totalUsersRes = await _client
          .from(SupabaseConstants.profilesTable)
          .select('id');
      final totalUsers = totalUsersRes.length;

      final verifiedUsersRes = await _client
          .from(SupabaseConstants.profilesTable)
          .select('id')
          .eq('is_verified', true);
      final verifiedUsers = verifiedUsersRes.length;

      final pendingVerificationsRes = await _client
          .from(SupabaseConstants.studentVerificationsTable)
          .select('id')
          .or('status.eq.pending,status.eq.resubmitted');
      final pendingReviews = pendingVerificationsRes.length;

      return {
        'totalUsers': totalUsers,
        'verifiedUsers': verifiedUsers,
        'pendingReviews': pendingReviews,
      };
    } catch (e, stack) {
      AppLogger.error('Error fetching metrics', e, stack, 'AdminRepository');
      rethrow;
    }
  }
}

/// Provider for AdminRepository
final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(Supabase.instance.client);
});
