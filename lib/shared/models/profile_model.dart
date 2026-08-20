import '../models/enums.dart';

/// Profile data model
class ProfileModel {
  const ProfileModel({
    required this.id,
    required this.rollNumber,
    required this.fullName,
    required this.email,
    this.department,
    this.academicYear,
    this.bio,
    this.skills = const [],
    this.interests = const [],
    this.avatarUrl,
    this.isVerified = false,
    this.role = UserRole.student,
    this.visibility = VisibilityLevel.public,
    this.profileCompletion = 0,
    required this.seemeQrId,
    this.accountStatus = AccountStatus.active,
    this.deletedAt,
    this.deletionScheduledAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String rollNumber;
  final String fullName;
  final String email;
  final String? department;
  final String? academicYear;
  final String? bio;
  final List<String> skills;
  final List<String> interests;
  final String? avatarUrl;
  final bool isVerified;
  final UserRole role;
  final VisibilityLevel visibility;
  final int profileCompletion;
  final String seemeQrId;
  final AccountStatus accountStatus;
  final DateTime? deletedAt;
  final DateTime? deletionScheduledAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Constant college name for single-college SRMU architecture
  String get collegeName => 'SRMU';

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      rollNumber: json['roll_number'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      department: json['department'] as String?,
      academicYear: json['academic_year'] as String?,
      bio: json['bio'] as String?,
      skills: (json['skills'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      interests: (json['interests'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      avatarUrl: json['avatar_url'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      role: UserRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => UserRole.student,
      ),
      visibility: VisibilityLevel.fromDbValue(
        json['visibility'] as String? ?? 'public',
      ),
      profileCompletion: json['profile_completion'] as int? ?? 0,
      seemeQrId: json['seeme_qr_id'] as String,
      accountStatus: AccountStatus.fromDbValue(
        json['account_status'] as String? ?? 'active',
      ),
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
      deletionScheduledAt: json['deletion_scheduled_at'] != null
          ? DateTime.parse(json['deletion_scheduled_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'roll_number': rollNumber,
        'full_name': fullName,
        'email': email,
        'department': department,
        'academic_year': academicYear,
        'bio': bio,
        'skills': skills,
        'interests': interests,
        'avatar_url': avatarUrl,
        'visibility': visibility.dbValue,
      };

  ProfileModel copyWith({
    String? rollNumber,
    String? fullName,
    String? email,
    String? department,
    String? academicYear,
    String? bio,
    List<String>? skills,
    List<String>? interests,
    String? avatarUrl,
    bool? isVerified,
    UserRole? role,
    VisibilityLevel? visibility,
    int? profileCompletion,
    AccountStatus? accountStatus,
    DateTime? deletedAt,
    DateTime? deletionScheduledAt,
  }) {
    return ProfileModel(
      id: id,
      rollNumber: rollNumber ?? this.rollNumber,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      department: department ?? this.department,
      academicYear: academicYear ?? this.academicYear,
      bio: bio ?? this.bio,
      skills: skills ?? this.skills,
      interests: interests ?? this.interests,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isVerified: isVerified ?? this.isVerified,
      role: role ?? this.role,
      visibility: visibility ?? this.visibility,
      profileCompletion: profileCompletion ?? this.profileCompletion,
      seemeQrId: seemeQrId,
      accountStatus: accountStatus ?? this.accountStatus,
      deletedAt: deletedAt ?? this.deletedAt,
      deletionScheduledAt: deletionScheduledAt ?? this.deletionScheduledAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Public profile URL
  String get publicProfileUrl => 'https://seeme.app/u/$rollNumber';

  /// SeeMe QR content
  String get qrContent => 'seeme://$seemeQrId';

  /// Whether profile is active and usable
  bool get isActive => accountStatus == AccountStatus.active;

  /// Days remaining before permanent deletion (null if not soft-deleted)
  int? get daysUntilPermanentDeletion {
    if (deletionScheduledAt == null) return null;
    final remaining = deletionScheduledAt!.difference(DateTime.now()).inDays;
    return remaining.clamp(0, 999);
  }
}
