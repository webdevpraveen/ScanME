import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/supabase_constants.dart';
import '../../../core/utils/logger.dart';
import '../../../shared/models/profile_model.dart';

/// Repository for handling all Profile data operations
class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;

  /// Fetch a user profile by ID
  Future<ProfileModel?> getProfile(String userId) async {
    try {
      AppLogger.info('Fetching profile for user: $userId', 'ProfileRepository');
      final response = await _client
          .from(SupabaseConstants.profilesTable)
          .select('*')
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;
      return ProfileModel.fromJson(response);
    } catch (e, stack) {
      AppLogger.error('Error fetching profile', e, stack, 'ProfileRepository');
      rethrow;
    }
  }

  /// Update own profile details
  Future<ProfileModel> updateProfile(ProfileModel profile) async {
    try {
      AppLogger.info('Updating profile: ${profile.id}', 'ProfileRepository');
      
      final response = await _client
          .from(SupabaseConstants.profilesTable)
          .update(profile.toJson())
          .eq('id', profile.id)
          .select('*')
          .single();

      return ProfileModel.fromJson(response);
    } catch (e, stack) {
      AppLogger.error('Error updating profile', e, stack, 'ProfileRepository');
      rethrow;
    }
  }

  /// Upload avatar to avatars bucket and get public url
  Future<String> uploadAvatar({
    required String userId,
    required String filePath,
  }) async {
    try {
      AppLogger.info('Uploading avatar for: $userId', 'ProfileRepository');
      
      final fileName = '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Upload new avatar file
      await _client.storage
          .from(SupabaseConstants.avatarsBucket)
          .upload(fileName, filePath as dynamic);

      final url = _client.storage
          .from(SupabaseConstants.avatarsBucket)
          .getPublicUrl(fileName);

      // Update avatar_url in database
      await _client
          .from(SupabaseConstants.profilesTable)
          .update({'avatar_url': url})
          .eq('id', userId);

      AppLogger.info('Avatar uploaded successfully', 'ProfileRepository');
      return url;
    } catch (e, stack) {
      AppLogger.error('Error uploading avatar', e, stack, 'ProfileRepository');
      rethrow;
    }
  }

  /// Get public profile by roll number
  Future<ProfileModel?> getPublicProfile(String rollNumber) async {
    try {
      AppLogger.info('Fetching public profile for roll number: $rollNumber', 'ProfileRepository');
      final response = await _client
          .from(SupabaseConstants.profilesTable)
          .select('*')
          .eq('roll_number', rollNumber)
          .eq('account_status', 'active')
          .maybeSingle();

      if (response == null) return null;
      
      final profile = ProfileModel.fromJson(response);
      
      // If the profile is hidden or not public/verified, we shouldn't show it to unauthenticated users,
      // but GoRouter/PublicProfileScreen will handle the check based on who is logged in.
      return profile;
    } catch (e, stack) {
      AppLogger.error('Error fetching public profile', e, stack, 'ProfileRepository');
      rethrow;
    }
  }

  /// Record a profile view (calls the PostgreSQL function `increment_profile_views`)
  Future<bool> recordProfileView({
    required String viewerId,
    required String viewedId,
  }) async {
    try {
      AppLogger.info('Recording profile view: $viewerId viewed $viewedId', 'ProfileRepository');
      final response = await _client.rpc<bool>(
        'increment_profile_views',
        params: {
          'p_viewer': viewerId,
          'p_viewed': viewedId,
        },
      );
      return response;
    } catch (e) {
      AppLogger.warning('Failed to record profile view (likely rate limited or blocked): $e', 'ProfileRepository');
      return false;
    }
  }
}

/// Provider for ProfileRepository
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(Supabase.instance.client);
});
