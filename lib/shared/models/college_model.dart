/// College model for multi-college architecture
class CollegeModel {
  const CollegeModel({
    required this.id,
    required this.name,
    required this.shortCode,
    this.domain,
    this.logoUrl,
    this.qrFormatHint,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String shortCode;
  final String? domain;
  final String? logoUrl;
  final String? qrFormatHint;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory CollegeModel.fromJson(Map<String, dynamic> json) {
    return CollegeModel(
      id: json['id'] as String,
      name: json['name'] as String,
      shortCode: json['short_code'] as String,
      domain: json['domain'] as String?,
      logoUrl: json['logo_url'] as String?,
      qrFormatHint: json['qr_format_hint'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'short_code': shortCode,
        'domain': domain,
        'logo_url': logoUrl,
        'qr_format_hint': qrFormatHint,
        'is_active': isActive,
      };
}

/// College-student relationship
class CollegeStudentModel {
  const CollegeStudentModel({
    required this.id,
    required this.userId,
    required this.collegeId,
    required this.rollNumber,
    this.enrollmentYear,
    required this.createdAt,
    this.collegeName,
  });

  final String id;
  final String userId;
  final String collegeId;
  final String rollNumber;
  final String? enrollmentYear;
  final DateTime createdAt;
  final String? collegeName;

  factory CollegeStudentModel.fromJson(Map<String, dynamic> json) {
    String? collegeName;
    final college = json['colleges'];
    if (college is Map<String, dynamic>) {
      collegeName = college['name'] as String?;
    }

    return CollegeStudentModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      collegeId: json['college_id'] as String,
      rollNumber: json['roll_number'] as String,
      enrollmentYear: json['enrollment_year'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      collegeName: collegeName,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'college_id': collegeId,
        'roll_number': rollNumber,
        'enrollment_year': enrollmentYear,
      };
}
