/// SeeMe application-wide constants
class AppConstants {
  AppConstants._();

  // ─── App Info ──────────────────────────────────────────────
  static const String appName = 'SeeMe';
  static const String appTagline = 'Scan. Connect. Grow.';
  static const String appVersion = '1.0.0';
  static const int appBuildNumber = 1;

  // ─── URLs ──────────────────────────────────────────────────
  static const String appDomain = 'seeme.app';
  static const String publicProfileBaseUrl = 'https://seeme.app/u/';
  static const String privacyPolicyUrl = 'https://seeme.app/privacy';
  static const String termsOfServiceUrl = 'https://seeme.app/terms';

  // ─── Validation Rules ──────────────────────────────────────
  static const int passwordMinLength = 8;
  static const int passwordMaxLength = 128;
  static const int nameMaxLength = 100;
  static const int bioMaxLength = 500;
  static const int rollNumberLength = 15;
  static const int maxSkills = 20;
  static const int maxInterests = 20;
  static const int maxSocialLinks = 15;

  // ─── File Upload ───────────────────────────────────────────
  static const int avatarMaxSizeMb = 5;
  static const int idCardMaxSizeMb = 10;
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'webp'];
  static const int avatarMaxDimension = 512;
  static const int avatarQuality = 85;

  // ─── Rate Limits (defaults, overridden by app_config) ──────
  static const int defaultMaxScansPerHour = 100;
  static const int defaultMaxProfileViewsPerHour = 300;
  static const int defaultMaxSearchesPerHour = 200;

  // ─── Data Retention (defaults, overridden by app_config) ───
  static const int defaultScanHistoryRetentionDays = 180;
  static const int defaultActivityLogRetentionDays = 365;
  static const int defaultAuditLogRetentionDays = 365;
  static const int defaultAccountDeletionRecoveryDays = 30;

  // ─── Pagination ────────────────────────────────────────────
  static const int defaultPageSize = 20;
  static const int maxPageSize = 50;

  // ─── Debounce ──────────────────────────────────────────────
  static const Duration searchDebounce = Duration(milliseconds: 300);
  static const Duration rollNumberCheckDebounce = Duration(milliseconds: 500);

  // ─── QR ────────────────────────────────────────────────────
  static const String seemeQrPrefix = 'seeme://';
  static const String seemeUrlPrefix = 'https://seeme.app/u/';
}
