import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/supabase_constants.dart';
import '../../../core/utils/logger.dart';

/// Repository for managing scan history entries
class HistoryRepository {
  HistoryRepository(this._client);

  final SupabaseClient _client;

  /// Fetch scan history for the logged-in user (joined with scanned student details)
  Future<List<Map<String, dynamic>>> getScanHistory(String userId) async {
    try {
      AppLogger.info('Fetching scan history for user: $userId', 'HistoryRepository');
      final response = await _client
          .from(SupabaseConstants.scanHistoryTable)
          .select('*, profiles!scan_history_scanned_id_fkey(id, roll_number, full_name, avatar_url, is_verified, department)')
          .eq('scanner_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e, stack) {
      AppLogger.error('Error fetching scan history', e, stack, 'HistoryRepository');
      rethrow;
    }
  }

  /// Delete a single scan history entry by ID
  Future<void> deleteHistoryEntry(String id) async {
    try {
      AppLogger.info('Deleting scan history entry: $id', 'HistoryRepository');
      await _client
          .from(SupabaseConstants.scanHistoryTable)
          .delete()
          .eq('id', id);
    } catch (e, stack) {
      AppLogger.error('Error deleting scan history entry', e, stack, 'HistoryRepository');
      rethrow;
    }
  }

  /// Clear all scan history for the user
  Future<void> clearHistory(String userId) async {
    try {
      AppLogger.info('Clearing all scan history for user: $userId', 'HistoryRepository');
      await _client
          .from(SupabaseConstants.scanHistoryTable)
          .delete()
          .eq('scanner_id', userId);
    } catch (e, stack) {
      AppLogger.error('Error clearing scan history', e, stack, 'HistoryRepository');
      rethrow;
    }
  }
}

/// Provider for HistoryRepository
final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepository(Supabase.instance.client);
});
