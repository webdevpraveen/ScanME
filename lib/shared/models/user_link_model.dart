import 'enums.dart';

/// Social/contact link model
class UserLinkModel {
  const UserLinkModel({
    required this.id,
    required this.userId,
    required this.platform,
    required this.url,
    this.displayName,
    this.isVisible = true,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final LinkPlatform platform;
  final String url;
  final String? displayName;
  final bool isVisible;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory UserLinkModel.fromJson(Map<String, dynamic> json) {
    return UserLinkModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      platform: LinkPlatform.values.firstWhere(
        (p) => p.name == json['platform'],
        orElse: () => LinkPlatform.custom,
      ),
      url: json['url'] as String,
      displayName: json['display_name'] as String?,
      isVisible: json['is_visible'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'platform': platform.name,
        'url': url,
        'display_name': displayName,
        'is_visible': isVisible,
        'sort_order': sortOrder,
      };

  UserLinkModel copyWith({
    String? url,
    String? displayName,
    bool? isVisible,
    int? sortOrder,
    LinkPlatform? platform,
  }) {
    return UserLinkModel(
      id: id,
      userId: userId,
      platform: platform ?? this.platform,
      url: url ?? this.url,
      displayName: displayName ?? this.displayName,
      isVisible: isVisible ?? this.isVisible,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Get the launch URL for this link
  String get launchUrl {
    switch (platform) {
      case LinkPlatform.phone:
        return 'tel:$url';
      case LinkPlatform.whatsapp:
        final number = url.replaceAll(RegExp(r'[\s+()-]'), '');
        return 'https://wa.me/$number';
      case LinkPlatform.email:
        return 'mailto:$url';
      default:
        return url;
    }
  }
}
