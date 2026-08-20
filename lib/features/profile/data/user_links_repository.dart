import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/supabase_constants.dart';
import '../../../core/utils/logger.dart';
import '../../../shared/models/user_link_model.dart';

/// Repository for handling UserLinks (Social links)
class UserLinksRepository {
  UserLinksRepository(this._client);

  final SupabaseClient _client;

  /// Fetch all links for a user, sorted by sort_order
  Future<List<UserLinkModel>> getUserLinks(String userId) async {
    try {
      AppLogger.info('Fetching links for user: $userId', 'UserLinksRepository');
      final response = await _client
          .from(SupabaseConstants.userLinksTable)
          .select()
          .eq('user_id', userId)
          .order('sort_order', ascending: true);

      return (response as List)
          .map((json) => UserLinkModel.fromJson(json))
          .toList();
    } catch (e, stack) {
      AppLogger.error('Error fetching user links', e, stack, 'UserLinksRepository');
      rethrow;
    }
  }

  /// Create a new link
  Future<UserLinkModel> createLink(UserLinkModel link) async {
    try {
      AppLogger.info('Creating link: ${link.platform.name}', 'UserLinksRepository');
      final response = await _client
          .from(SupabaseConstants.userLinksTable)
          .insert(link.toJson())
          .select()
          .single();

      return UserLinkModel.fromJson(response);
    } catch (e, stack) {
      AppLogger.error('Error creating user link', e, stack, 'UserLinksRepository');
      rethrow;
    }
  }

  /// Update an existing link
  Future<UserLinkModel> updateLink(UserLinkModel link) async {
    try {
      AppLogger.info('Updating link: ${link.id}', 'UserLinksRepository');
      final response = await _client
          .from(SupabaseConstants.userLinksTable)
          .update(link.toJson())
          .eq('id', link.id)
          .select()
          .single();

      return UserLinkModel.fromJson(response);
    } catch (e, stack) {
      AppLogger.error('Error updating user link', e, stack, 'UserLinksRepository');
      rethrow;
    }
  }

  /// Delete a link
  Future<void> deleteLink(String linkId) async {
    try {
      AppLogger.info('Deleting link: $linkId', 'UserLinksRepository');
      await _client
          .from(SupabaseConstants.userLinksTable)
          .delete()
          .eq('id', linkId);
    } catch (e, stack) {
      AppLogger.error('Error deleting user link', e, stack, 'UserLinksRepository');
      rethrow;
    }
  }

  /// Batch update links (e.g. after reordering)
  Future<void> updateLinksOrder(List<UserLinkModel> links) async {
    try {
      AppLogger.info('Updating links order', 'UserLinksRepository');
      final updates = links.map((link) => {
        'id': link.id,
        'user_id': link.userId,
        'platform': link.platform.name,
        'url': link.url,
        'display_name': link.displayName,
        'is_visible': link.isVisible,
        'sort_order': link.sortOrder,
      }).toList();

      await _client.from(SupabaseConstants.userLinksTable).upsert(updates);
    } catch (e, stack) {
      AppLogger.error('Error batch updating user links', e, stack, 'UserLinksRepository');
      rethrow;
    }
  }
}

/// Provider for UserLinksRepository
final userLinksRepositoryProvider = Provider<UserLinksRepository>((ref) {
  return UserLinksRepository(Supabase.instance.client);
});
