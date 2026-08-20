import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/supabase_constants.dart';
import '../../../core/utils/logger.dart';
import '../../../shared/models/profile_model.dart';

/// Repository for handling search and discovery queries
class SearchRepository {
  SearchRepository(this._client);

  final SupabaseClient _client;

  /// Perform full-text search on profiles
  Future<List<ProfileModel>> searchStudents({
    required String queryText,
    required String myUserId,
    String? department,
  }) async {
    try {
      AppLogger.info('Searching students with query: "$queryText"', 'SearchRepository');

      if (queryText.trim().isEmpty) return const [];

      // Format query for websearch parsing
      var request = _client
          .from(SupabaseConstants.profilesTable)
          .select('*')
          .textSearch('search_vector', queryText, config: 'english', type: TextSearchType.websearch)
          .eq('is_verified', true)
          .eq('account_status', 'active');

      // Optional department filter
      if (department != null) {
        request = request.eq('department', department);
      }

      final response = await request.limit(50);

      // Parse profiles
      final allResults = (response as List)
          .map((json) => ProfileModel.fromJson(json))
          .toList();

      // Filter out self and any blocked profiles in memory to guarantee safety
      // 1. Fetch blocked users
      final blocks = await _client
          .from('blocked_users')
          .select('blocked_id, blocker_id')
          .or('blocker_id.eq.$myUserId,blocked_id.eq.$myUserId');

      final blockedIds = (blocks as List)
          .map((row) => row['blocker_id'] == myUserId ? row['blocked_id'] as String : row['blocker_id'] as String)
          .toSet();

      final filteredResults = allResults.where((profile) {
        return profile.id != myUserId && !blockedIds.contains(profile.id);
      }).toList();

      return filteredResults;
    } catch (e, stack) {
      AppLogger.error('Error during student search', e, stack, 'SearchRepository');
      rethrow;
    }
  }
}

/// Provider for SearchRepository
final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepository(Supabase.instance.client);
});
