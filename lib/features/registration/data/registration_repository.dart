import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/supabase_constants.dart';
import '../../../core/utils/logger.dart';

/// Registration repository — handles profile creation and verification submission
class RegistrationRepository {
  RegistrationRepository(this._client);

  final SupabaseClient _client;
  final _uuid = const Uuid();

  /// Complete registration after auth signup
  Future<void> completeRegistration({
    required String userId,
    required String rollNumber,
    required String fullName,
    required String email,
    String? department,
    String? academicYear,
  }) async {
    AppLogger.info('Completing registration for $rollNumber', 'Registration');

    final seemeQrId = _uuid.v4();

    // 1. Update profile (created by trigger on auth.users insert)
    await _client.from(SupabaseConstants.profilesTable).upsert({
      'id': userId,
      'roll_number': rollNumber,
      'full_name': fullName,
      'email': email,
      'department': department,
      'academic_year': academicYear,
      'seeme_qr_id': seemeQrId,
    });

    // 2. Create verification request
    await _client.from(SupabaseConstants.studentVerificationsTable).insert({
      'user_id': userId,
      'roll_number_declared': rollNumber,
      'status': 'pending',
    });

    AppLogger.info('Registration complete for $rollNumber', 'Registration');
  }

  /// Upload ID card image
  Future<String> uploadIdCard({
    required String userId,
    required String filePath,
  }) async {
    final fileName = '$userId/id_card_${DateTime.now().millisecondsSinceEpoch}.jpg';

    await _client.storage
        .from(SupabaseConstants.idCardsBucket)
        .upload(fileName, filePath as dynamic);

    final url = _client.storage
        .from(SupabaseConstants.idCardsBucket)
        .getPublicUrl(fileName);

    // Update verification with image URL
    await _client
        .from(SupabaseConstants.studentVerificationsTable)
        .update({'id_card_front_url': url})
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1);

    return url;
  }

  /// Check roll number availability
  Future<bool> isRollNumberAvailable(String rollNumber) async {
    final response = await _client
        .from(SupabaseConstants.profilesTable)
        .select('id')
        .eq('roll_number', rollNumber)
        .maybeSingle();

    return response == null;
  }

  /// Resubmit verification (for rejected students)
  Future<void> resubmitVerification({
    required String userId,
    required String rollNumber,
    String? idCardUrl,
  }) async {
    AppLogger.info('Resubmitting verification', 'Registration');

    await _client.from(SupabaseConstants.studentVerificationsTable).insert({
      'user_id': userId,
      'roll_number_declared': rollNumber,
      'id_card_front_url': idCardUrl,
      'status': 'resubmitted',
    });
  }
}

/// Provider for RegistrationRepository
final registrationRepositoryProvider = Provider<RegistrationRepository>((ref) {
  return RegistrationRepository(Supabase.instance.client);
});
