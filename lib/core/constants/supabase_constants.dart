/// Supabase table names, bucket names, and function names
/// Single source of truth for all Supabase identifiers
class SupabaseConstants {
  SupabaseConstants._();

  // ─── Table Names ───────────────────────────────────────────
  static const String profilesTable = 'profiles';
  static const String collegesTable = 'colleges';
  static const String collegeStudentsTable = 'college_students';
  static const String userLinksTable = 'user_links';
  static const String studentVerificationsTable = 'student_verifications';
  static const String scanHistoryTable = 'scan_history';
  static const String notificationsTable = 'notifications';
  static const String profileViewsTable = 'profile_views';
  static const String reportedProfilesTable = 'reported_profiles';
  static const String blockedUsersTable = 'blocked_users';
  static const String userDevicesTable = 'user_devices';
  static const String appConfigTable = 'app_config';
  static const String featureFlagsTable = 'feature_flags';
  static const String activityLogsTable = 'activity_logs';
  static const String auditLogsTable = 'audit_logs';
  static const String rateLimitEventsTable = 'rate_limit_events';
  static const String appVersionsTable = 'app_versions';

  // ─── Storage Buckets ───────────────────────────────────────
  static const String avatarsBucket = 'avatars';
  static const String idCardsBucket = 'id-cards';
  static const String documentsBucket = 'documents';

  // ─── Database Functions ────────────────────────────────────
  static const String fnGetUserRole = 'get_user_role';
  static const String fnIsAdmin = 'is_admin';
  static const String fnIsModerator = 'is_moderator';
  static const String fnIsAdminOrModerator = 'is_admin_or_moderator';
  static const String fnCalculateProfileCompletion = 'calculate_profile_completion';
  static const String fnCheckRateLimit = 'check_rate_limit';
  static const String fnRecordRateLimitEvent = 'record_rate_limit_event';
  static const String fnSoftDeleteAccount = 'soft_delete_account';
  static const String fnRecoverAccount = 'recover_account';
  static const String fnIncrementProfileViews = 'increment_profile_views';

  // ─── App Config Keys ───────────────────────────────────────
  static const String configMaintenanceMode = 'maintenance_mode';
  static const String configMinAppVersion = 'minimum_app_version';
  static const String configLatestAppVersion = 'latest_app_version';
  static const String configSupportEmail = 'support_email';
  static const String configSupportWhatsapp = 'support_whatsapp';
  static const String configAnnouncementText = 'announcement_text';
  static const String configMaxScansPerHour = 'max_scans_per_hour';
  static const String configMaxProfileViewsPerHour = 'max_profile_views_per_hour';
  static const String configMaxSearchesPerHour = 'max_searches_per_hour';
  static const String configAccountDeletionRecoveryDays = 'account_deletion_recovery_days';
  static const String configScanHistoryRetentionDays = 'scan_history_retention_days';

  // ─── Rate Limit Action Types ───────────────────────────────
  static const String rateLimitScan = 'scan';
  static const String rateLimitProfileView = 'profile_view';
  static const String rateLimitSearch = 'search';
}
