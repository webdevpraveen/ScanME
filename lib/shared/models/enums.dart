/// Enums used across the application
/// These mirror the PostgreSQL enums in the database

enum UserRole {
  student,
  moderator,
  admin;

  bool get isStudent => this == UserRole.student;
  bool get isModerator => this == UserRole.moderator;
  bool get isAdmin => this == UserRole.admin;
  bool get isAdminOrModerator => isAdmin || isModerator;
}

enum VerificationStatus {
  pending,
  approved,
  rejected,
  resubmitted;

  bool get isPending => this == VerificationStatus.pending;
  bool get isApproved => this == VerificationStatus.approved;
  bool get isRejected => this == VerificationStatus.rejected;
  bool get isResubmitted => this == VerificationStatus.resubmitted;
  bool get isAwaitingReview => isPending || isResubmitted;
}

enum VisibilityLevel {
  public,
  studentsOnly,
  hidden;

  String get displayName => switch (this) {
    VisibilityLevel.public => 'Public',
    VisibilityLevel.studentsOnly => 'Students Only',
    VisibilityLevel.hidden => 'Hidden',
  };

  String get description => switch (this) {
    VisibilityLevel.public => 'Anyone can see your profile',
    VisibilityLevel.studentsOnly => 'Only verified students can see your profile',
    VisibilityLevel.hidden => 'Your profile is hidden from search and scan',
  };

  /// Convert to database string (snake_case)
  String get dbValue => switch (this) {
    VisibilityLevel.public => 'public',
    VisibilityLevel.studentsOnly => 'students_only',
    VisibilityLevel.hidden => 'hidden',
  };

  static VisibilityLevel fromDbValue(String value) => switch (value) {
    'public' => VisibilityLevel.public,
    'students_only' => VisibilityLevel.studentsOnly,
    'hidden' => VisibilityLevel.hidden,
    _ => VisibilityLevel.public,
  };
}

enum LinkPlatform {
  phone,
  whatsapp,
  email,
  instagram,
  linkedin,
  github,
  x,
  portfolio,
  custom;

  String get displayName => switch (this) {
    LinkPlatform.phone => 'Phone',
    LinkPlatform.whatsapp => 'WhatsApp',
    LinkPlatform.email => 'Email',
    LinkPlatform.instagram => 'Instagram',
    LinkPlatform.linkedin => 'LinkedIn',
    LinkPlatform.github => 'GitHub',
    LinkPlatform.x => 'X (Twitter)',
    LinkPlatform.portfolio => 'Portfolio',
    LinkPlatform.custom => 'Custom Link',
  };

  String get iconAsset => switch (this) {
    LinkPlatform.phone => 'phone',
    LinkPlatform.whatsapp => 'whatsapp',
    LinkPlatform.email => 'email',
    LinkPlatform.instagram => 'instagram',
    LinkPlatform.linkedin => 'linkedin',
    LinkPlatform.github => 'github',
    LinkPlatform.x => 'x',
    LinkPlatform.portfolio => 'portfolio',
    LinkPlatform.custom => 'link',
  };

  String get placeholder => switch (this) {
    LinkPlatform.phone => '+91 98765 43210',
    LinkPlatform.whatsapp => '+91 98765 43210',
    LinkPlatform.email => 'your@email.com',
    LinkPlatform.instagram => 'https://instagram.com/username',
    LinkPlatform.linkedin => 'https://linkedin.com/in/username',
    LinkPlatform.github => 'https://github.com/username',
    LinkPlatform.x => 'https://x.com/username',
    LinkPlatform.portfolio => 'https://yoursite.com',
    LinkPlatform.custom => 'https://...',
  };

  bool get isUrlType => switch (this) {
    LinkPlatform.phone || LinkPlatform.whatsapp || LinkPlatform.email => false,
    _ => true,
  };
}

enum NotificationType {
  approval,
  rejection,
  profileView,
  system,
  announcement;

  String get dbValue => switch (this) {
    NotificationType.approval => 'approval',
    NotificationType.rejection => 'rejection',
    NotificationType.profileView => 'profile_view',
    NotificationType.system => 'system',
    NotificationType.announcement => 'announcement',
  };

  static NotificationType fromDbValue(String value) => switch (value) {
    'approval' => NotificationType.approval,
    'rejection' => NotificationType.rejection,
    'profile_view' => NotificationType.profileView,
    'system' => NotificationType.system,
    'announcement' => NotificationType.announcement,
    _ => NotificationType.system,
  };
}

enum ReportStatus {
  pending,
  reviewed,
  resolved,
  dismissed;
}

enum AccountStatus {
  active,
  softDeleted,
  purged;

  String get dbValue => switch (this) {
    AccountStatus.active => 'active',
    AccountStatus.softDeleted => 'soft_deleted',
    AccountStatus.purged => 'purged',
  };

  static AccountStatus fromDbValue(String value) => switch (value) {
    'active' => AccountStatus.active,
    'soft_deleted' => AccountStatus.softDeleted,
    'purged' => AccountStatus.purged,
    _ => AccountStatus.active,
  };
}
