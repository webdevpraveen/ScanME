import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';

/// Glass-effect card with frosted background and subtle border
class SeemeCard extends StatelessWidget {
  const SeemeCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.borderRadius,
    this.useGlass = false,
    this.gradient,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final VoidCallback? onTap;
  final double? borderRadius;
  final bool useGlass;
  final Gradient? gradient;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? AppDimensions.radiusLg;

    Widget card = Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: gradient,
        color: gradient == null
            ? (isDark ? AppColors.darkCard : AppColors.lightCard)
            : null,
        border: Border.all(
          color: borderColor ??
              (useGlass
                  ? AppColors.glassBorder
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder)),
          width: AppDimensions.cardBorderWidth,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: useGlass
            ? BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  color: isDark ? AppColors.glassWhite : Colors.white.withValues(alpha: 0.7),
                  padding: padding ??
                      const EdgeInsets.all(AppDimensions.spacing16),
                  child: child,
                ),
              )
            : Padding(
                padding: padding ??
                    const EdgeInsets.all(AppDimensions.spacing16),
                child: child,
              ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }
}
