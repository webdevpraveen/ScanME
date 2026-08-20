import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/supabase_constants.dart';
import '../../../core/utils/logger.dart';
import '../../qr_resolver/qr_resolver_service.dart';
import '../../../shared/models/profile_model.dart';

/// Repository for handling all scan actions and resolving QR codes to profiles
class ScannerRepository {
  ScannerRepository(this._client);

  final SupabaseClient _client;

  /// Check if the user is within their hourly scan rate limit
  Future<bool> checkScanRateLimit(String userId, int maxScans) async {
    try {
      final response = await _client.rpc<bool>(
        'check_rate_limit',
        params: {
          'p_user_id': userId,
          'p_action': 'scan',
          'p_max_count': maxScans,
          'p_window_interval': '1 hour',
        },
      );
      return response;
    } catch (e) {
      AppLogger.warning('Rate limit check failed, defaulting to allow: $e', 'ScannerRepository');
      return true;
    }
  }

  /// Record a scan event in rate limit tracking
  Future<void> recordScanRateLimitEvent(String userId) async {
    try {
      await _client.rpc('record_rate_limit_event', params: {
        'p_user_id': userId,
        'p_action': 'scan',
      });
    } catch (e) {
      AppLogger.warning('Failed to record rate limit event: $e', 'ScannerRepository');
    }
  }

  /// Resolve a ResolvedIdentity to a full ProfileModel and log the scan in history
  Future<ProfileModel?> resolveIdentity({
    required String scannerId,
    required ResolvedIdentity identity,
  }) async {
    try {
      AppLogger.info('Resolving identity: ${identity.type.name} - ${identity.identifier}', 'ScannerRepository');
      
      Map<String, dynamic>? json;

      switch (identity.type) {
        case ResolvedIdentityType.seemeQrId:
          json = await _client
              .from(SupabaseConstants.profilesTable)
              .select('*')
              .eq('seeme_qr_id', identity.identifier)
              .eq('account_status', 'active')
              .maybeSingle();
          break;

        case ResolvedIdentityType.rollNumber:
          json = await _client
              .from(SupabaseConstants.profilesTable)
              .select('*')
              .eq('roll_number', identity.identifier)
              .eq('account_status', 'active')
              .maybeSingle();
          break;

        case ResolvedIdentityType.userId:
          json = await _client
              .from(SupabaseConstants.profilesTable)
              .select('*')
              .eq('id', identity.identifier)
              .eq('account_status', 'active')
              .maybeSingle();
          break;


      }

      if (json == null) return null;
      final profile = ProfileModel.fromJson(json);

      // Check if self-scan
      if (profile.id == scannerId) {
        throw Exception('You cannot scan your own QR code!');
      }

      // Check if user is blocked or has blocked the scanner
      final blockedCheck = await _client
          .from('blocked_users')
          .select('id')
          .or('and(blocker_id.eq.$scannerId,blocked_id.eq.${profile.id}),and(blocker_id.eq.${profile.id},blocked_id.eq.$scannerId)')
          .maybeSingle();

      if (blockedCheck != null) {
        throw Exception('You cannot view this profile because one of you has blocked the other.');
      }

      // Log successful scan in scan_history
      await _client.from(SupabaseConstants.scanHistoryTable).insert({
        'scanner_id': scannerId,
        'scanned_id': profile.id,
        'scan_type': 'qr',
      });

      // Record rate limit event
      await recordScanRateLimitEvent(scannerId);

      AppLogger.info('Identity resolved successfully and logged to scan history', 'ScannerRepository');
      return profile;
    } catch (e, stack) {
      AppLogger.error('Error resolving identity', e, stack, 'ScannerRepository');
      rethrow;
    }
  }
}

/// Provider for ScannerRepository
final scannerRepositoryProvider = Provider<ScannerRepository>((ref) {
  return ScannerRepository(Supabase.instance.client);
});
