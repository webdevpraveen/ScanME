import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/extensions/string_extensions.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';

/// Avatar widget with network image, fallback initials, and shimmer loading
class SeemeAvatar extends StatelessWidget {
  const SeemeAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.size = AppDimensions.avatarMd,
    this.onTap,
    this.showBorder = false,
    this.borderColor,
    this.isVerified = false,
  });

  final String? imageUrl;
  final String name;
  final double size;
  final VoidCallback? onTap;
  final bool showBorder;
  final Color? borderColor;
  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(
                color: borderColor ?? AppColors.primary,
                width: 2.5,
              )
            : null,
        gradient: imageUrl == null ? AppColors.primaryGradient : null,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                placeholder: (_, __) => _buildInitials(isDark),
                errorWidget: (_, __, ___) => _buildInitials(isDark),
              )
            : _buildInitials(isDark),
      ),
    );

    if (isVerified) {
      avatar = Stack(
        children: [
          avatar,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.3,
              height: size * 0.3,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.check,
                color: Colors.white,
                size: size * 0.18,
              ),
            ),
          ),
        ],
      );
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: avatar,
      );
    }

    return avatar;
  }

  Widget _buildInitials(bool isDark) {
    final initials = name.initials;
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.35,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
