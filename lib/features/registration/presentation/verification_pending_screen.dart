import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';

/// Shown while student verification is pending moderator review
class VerificationPendingScreen extends StatelessWidget {
  const VerificationPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spacing32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.warning.withValues(alpha: 0.15),
                        AppColors.primary.withValues(alpha: 0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.hourglass_top_rounded,
                    color: AppColors.warning,
                    size: 48,
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.05, 1.05),
                      duration: 2000.ms,
                      curve: Curves.easeInOut,
                    )
                    .then()
                    .rotate(
                      begin: -0.02,
                      end: 0.02,
                      duration: 1500.ms,
                      curve: Curves.easeInOut,
                    ),
                const SizedBox(height: AppDimensions.spacing32),

                Text(
                  'Verification in Progress',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

                const SizedBox(height: AppDimensions.spacing12),

                Text(
                  'Your college ID is being reviewed by our team. This usually takes 24-48 hours.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 400.ms, duration: 500.ms),

                const SizedBox(height: AppDimensions.spacing40),

                Container(
                  padding: const EdgeInsets.all(AppDimensions.spacing16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceVariant.withValues(alpha: 0.3)
                        : AppColors.lightSurfaceVariant,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Column(
                    children: [
                      _statusRow(context, 'Account Created', true),
                      const SizedBox(height: AppDimensions.spacing12),
                      _statusRow(context, 'ID Submitted', true),
                      const SizedBox(height: AppDimensions.spacing12),
                      _statusRow(context, 'Under Review', false, isPending: true),
                      const SizedBox(height: AppDimensions.spacing12),
                      _statusRow(context, 'Verification Complete', false),
                    ],
                  ),
                ).animate().fadeIn(delay: 600.ms, duration: 500.ms).slideY(
                      begin: 0.2,
                      end: 0,
                    ),

                const SizedBox(height: AppDimensions.spacing32),

                Text(
                  'You\'ll be notified once your verification is complete.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.lightTextTertiary,
                      ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 800.ms, duration: 500.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusRow(BuildContext context, String label, bool complete,
      {bool isPending = false}) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: complete
                ? AppColors.success
                : isPending
                    ? AppColors.warning
                    : Colors.transparent,
            border: complete || isPending
                ? null
                : Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkSurfaceVariant
                        : AppColors.lightBorder,
                    width: 2,
                  ),
          ),
          child: complete
              ? const Icon(Icons.check, color: Colors.white, size: 14)
              : isPending
                  ? const Icon(Icons.more_horiz, color: Colors.white, size: 14)
                  : null,
        ),
        const SizedBox(width: AppDimensions.spacing12),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: isPending ? FontWeight.w600 : FontWeight.w400,
                color: complete || isPending
                    ? null
                    : (Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary),
              ),
        ),
      ],
    );
  }
}
