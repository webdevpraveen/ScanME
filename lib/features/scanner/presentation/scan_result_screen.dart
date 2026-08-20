import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../shared/models/profile_model.dart';
import '../../../shared/widgets/seeme_avatar.dart';
import '../../../shared/widgets/seeme_button.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';

/// Screen displayed after a successful QR code scan and identity resolution
class ScanResultScreen extends StatelessWidget {
  const ScanResultScreen({
    super.key,
    required this.profile,
  });

  final ProfileModel profile;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Result'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pagePaddingH),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ─── Celebration Animation & Card ───────────────
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.spacing24),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.success.withValues(alpha: isDark ? 0.15 : 0.05),
                          blurRadius: 32,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Success icon
                        Container(
                          padding: const EdgeInsets.all(AppDimensions.spacing12),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.success,
                            size: 40,
                          ),
                        ).animate().scale(delay: 100.ms, duration: 400.ms, curve: Curves.easeOutBack),
                        const SizedBox(height: AppDimensions.spacing20),

                        Text(
                          'Connection Made!',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 200.ms),
                        const SizedBox(height: AppDimensions.spacing24),

                        // Scanned Student Profile Details
                        SeemeAvatar(
                          name: profile.fullName,
                          imageUrl: profile.avatarUrl,
                          size: 80,
                          isVerified: profile.isVerified,
                        ).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.8, 0.8)),
                        const SizedBox(height: AppDimensions.spacing16),

                        Text(
                          profile.fullName,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          profile.rollNumber,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppDimensions.spacing8),

                        Text(
                          'SRMU',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 2),

                        if (profile.department != null)
                          Text(
                            profile.department!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                      ],
                    ),
                  ).animate().fadeIn().slideY(begin: 0.1, end: 0, duration: 400.ms),
                  const SizedBox(height: AppDimensions.spacing32),

                  // ─── Actions ─────────────────────────────────────
                  SeemeButton(
                    label: 'View Full Profile',
                    icon: Icons.person_rounded,
                    onPressed: () => context.go('/u/${profile.rollNumber}'),
                  ).animate().fadeIn(delay: 400.ms),
                  const SizedBox(height: AppDimensions.spacing12),
                  SeemeButton(
                    label: 'Scan Another Code',
                    icon: Icons.qr_code_scanner_rounded,
                    isOutlined: true,
                    onPressed: () => context.go('/scan'),
                  ).animate().fadeIn(delay: 500.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
