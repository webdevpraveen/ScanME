import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';

/// Primary button with gradient, loading state, and icon support
class SeemeButton extends StatelessWidget {
  const SeemeButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isOutlined = false,
    this.isSmall = false,
    this.isDestructive = false,
    this.width,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isOutlined;
  final bool isSmall;
  final bool isDestructive;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final height = isSmall
        ? AppDimensions.buttonHeightMd
        : AppDimensions.buttonHeightLg;

    if (isOutlined) {
      return SizedBox(
        width: width ?? double.infinity,
        height: height,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: isDestructive ? AppColors.error : AppColors.primary,
            side: BorderSide(
              color: isDestructive
                  ? AppColors.error.withValues(alpha: 0.5)
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            minimumSize: Size(0, height),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
          ),
          child: _buildContent(
            isDestructive ? AppColors.error : AppColors.primary,
          ),
        ),
      );
    }

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isDestructive
              ? const LinearGradient(
                  colors: [AppColors.error, Color(0xFFDC2626)],
                )
              : onPressed != null && !isLoading
                  ? AppColors.primaryGradient
                  : null,
          color: onPressed == null || isLoading
              ? (isDark ? AppColors.darkSurfaceVariant : AppColors.lightBorder)
              : null,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          boxShadow: onPressed != null && !isLoading
              ? [
                  BoxShadow(
                    color: (isDestructive ? AppColors.error : AppColors.primary)
                        .withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            minimumSize: Size(0, height),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
          ),
          child: _buildContent(Colors.white),
        ),
      ),
    );
  }

  Widget _buildContent(Color color) {
    if (isLoading) {
      return SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: color,
        ),
      ).animate(onPlay: (c) => c.repeat()).shimmer(
            duration: 1200.ms,
            color: color.withValues(alpha: 0.3),
          );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: isSmall ? 18 : 20),
          SizedBox(width: isSmall ? 6 : 8),
        ],
        Text(
          label,
          style: isSmall ? AppTextStyles.labelLarge : AppTextStyles.button,
        ),
      ],
    );
  }
}
