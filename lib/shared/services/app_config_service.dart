import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/supabase_constants.dart';
import '../../core/utils/logger.dart';

/// Dynamic app configuration fetched from Supabase app_config table
class AppConfigService {
  AppConfigService(this._client);

  final SupabaseClient _client;
  Map<String, dynamic> _config = {};

  /// Fetch all config from database
  Future<void> loadConfig() async {
    try {
      final response = await _client
          .from(SupabaseConstants.appConfigTable)
          .select('key, value');

      _config = {};
      for (final row in response as List) {
        _config[row['key'] as String] = row['value'];
      }
      AppLogger.info('App config loaded: ${_config.length} keys', 'AppConfig');
    } catch (e) {
      AppLogger.error('Failed to load app config', e, null, 'AppConfig');
      // Use defaults if config fetch fails
    }
  }

  /// Get a config value with fallback default
  T getValue<T>(String key, T defaultValue) {
    final value = _config[key];
    if (value == null) return defaultValue;
    if (value is T) return value;
    // Handle JSON number types
    if (T == int && value is num) return value.toInt() as T;
    if (T == double && value is num) return value.toDouble() as T;
    if (T == bool && value is String) return (value == 'true') as T;
    if (T == String && value is! String) return value.toString() as T;
    return defaultValue;
  }

  // ─── Typed Accessors ───────────────────────────────────────

  bool get maintenanceMode => getValue<bool>(
        SupabaseConstants.configMaintenanceMode,
        false,
      );

  String get minimumAppVersion => getValue<String>(
        SupabaseConstants.configMinAppVersion,
        '1.0.0',
      );

  String get latestAppVersion => getValue<String>(
        SupabaseConstants.configLatestAppVersion,
        '1.0.0',
      );

  String get supportEmail => getValue<String>(
        SupabaseConstants.configSupportEmail,
        '',
      );

  String get supportWhatsapp => getValue<String>(
        SupabaseConstants.configSupportWhatsapp,
        '',
      );

  String? get announcementText {
    final value = getValue<String>(
      SupabaseConstants.configAnnouncementText,
      '',
    );
    return value.isEmpty ? null : value;
  }

  int get maxScansPerHour => getValue<int>(
        SupabaseConstants.configMaxScansPerHour,
        100,
      );

  int get maxProfileViewsPerHour => getValue<int>(
        SupabaseConstants.configMaxProfileViewsPerHour,
        300,
      );

  int get maxSearchesPerHour => getValue<int>(
        SupabaseConstants.configMaxSearchesPerHour,
        200,
      );

  int get accountDeletionRecoveryDays => getValue<int>(
        SupabaseConstants.configAccountDeletionRecoveryDays,
        30,
      );

  int get scanHistoryRetentionDays => getValue<int>(
        SupabaseConstants.configScanHistoryRetentionDays,
        180,
      );
}

/// Provider for AppConfigService
final appConfigServiceProvider = Provider<AppConfigService>((ref) {
  final client = Supabase.instance.client;
  return AppConfigService(client);
});

/// Provider that loads and caches app config
final appConfigProvider = FutureProvider<AppConfigService>((ref) async {
  final service = ref.read(appConfigServiceProvider);
  await service.loadConfig();
  return service;
});
