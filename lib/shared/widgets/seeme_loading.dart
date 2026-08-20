import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';

/// Shimmer loading skeleton for various content types
class SeemeLoading extends StatelessWidget {
  const SeemeLoading._({
    super.key,
    required this.child,
  });

  final Widget child;

  /// Full-screen loading indicator with pulsing logo
  static Widget fullScreen({Key? key}) {
    return Center(
      key: key,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            ),
            child: const Icon(
              Icons.qr_code_scanner_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: AppDimensions.spacing16),
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// Skeleton card loading placeholder
  static Widget card({Key? key, double height = 80}) {
    return SeemeLoading._(
      key: key,
      child: _SkeletonCard(height: height),
    );
  }

  /// Skeleton list item (avatar + text lines)
  static Widget listItem({Key? key}) {
    return SeemeLoading._(
      key: key,
      child: const _SkeletonListItem(),
    );
  }

  /// Multiple skeleton list items
  static Widget listItems({Key? key, int count = 5}) {
    return Column(
      key: key,
      children: List.generate(
        count,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.spacing12),
          child: SeemeLoading.listItem(),
        ),
      ),
    );
  }

  /// Profile skeleton
  static Widget profile({Key? key}) {
    return SeemeLoading._(
      key: key,
      child: const _SkeletonProfile(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.darkSurfaceVariant : const Color(0xFFE2E8F0),
      highlightColor: isDark ? const Color(0xFF475569) : const Color(0xFFF1F5F9),
      child: child,
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
    );
  }
}

class _SkeletonListItem extends StatelessWidget {
  const _SkeletonListItem();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Avatar
        Container(
          width: AppDimensions.avatarMd,
          height: AppDimensions.avatarMd,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppDimensions.spacing12),
        // Text lines
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 14,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 12,
                width: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SkeletonProfile extends StatelessWidget {
  const _SkeletonProfile();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Avatar
        Container(
          width: AppDimensions.avatarXxl,
          height: AppDimensions.avatarXxl,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: AppDimensions.spacing16),
        // Name
        Container(
          height: 20,
          width: 180,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        // Username
        Container(
          height: 14,
          width: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: AppDimensions.spacing24),
        // Bio
        Container(
          height: 12,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 12,
          width: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}
