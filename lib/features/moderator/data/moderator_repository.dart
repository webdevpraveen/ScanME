import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/supabase_constants.dart';
import '../../../core/utils/logger.dart';

class ModeratorRepository {
  ModeratorRepository(this._client);

  final SupabaseClient _client;

  /// Fetch all pending or resubmitted verifications, joined with profile and college info
  Future<List<Map<String, dynamic>>> getPendingVerifications() async {
    try {
      AppLogger.info('Fetching pending verifications', 'ModeratorRepository');
      final response = await _client
          .from(SupabaseConstants.studentVerificationsTable)
          .select('*, profiles(full_name, roll_number, email)')
          .or('status.eq.pending,status.eq.resubmitted')
          .order('submitted_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e, stack) {
      AppLogger.error('Error fetching pending verifications', e, stack, 'ModeratorRepository');
      rethrow;
    }
  }

  /// Review a student verification (Approve or Reject)
  Future<void> reviewVerification({
    required String verificationId,
    required String studentId,
    required String moderatorId,
    required bool approved,
    String? notes,
  }) async {
    try {
      AppLogger.info('Reviewing verification $verificationId: approved=$approved', 'ModeratorRepository');
      
      final status = approved ? 'approved' : 'rejected';

      // 1. Update verification record
      await _client.from(SupabaseConstants.studentVerificationsTable).update({
        'status': status,
        'reviewed_by': moderatorId,
        'review_notes': notes,
        'reviewed_at': DateTime.now().toIso8601String(),
      }).eq('id', verificationId);

      // 2. Update student profile verified status
      await _client.from(SupabaseConstants.profilesTable).update({
        'is_verified': approved,
      }).eq('id', studentId);

      AppLogger.info('Verification $verificationId updated successfully', 'ModeratorRepository');
    } catch (e, stack) {
      AppLogger.error('Error reviewing verification', e, stack, 'ModeratorRepository');
      rethrow;
    }
  }
}

/// Provider for ModeratorRepository
final moderatorRepositoryProvider = Provider<ModeratorRepository>((ref) {
  return ModeratorRepository(Supabase.instance.client);
});
