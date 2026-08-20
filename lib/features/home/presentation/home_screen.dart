import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../shared/widgets/seeme_avatar.dart';
import '../../../shared/widgets/seeme_card.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../auth/providers/auth_providers.dart';
import '../../history/presentation/history_providers.dart';
import '../../notifications/presentation/notification_providers.dart';

/// Home screen — main landing page after login, loading real profile info and recent scans list
class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Watch profile & role
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    final userRole = ref.watch(userRoleProvider);

    // Watch history
    final historyAsync = ref.watch(scanHistoryProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ─── Header ─────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back 👋',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                profile?.fullName ?? 'Student',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Badge(
                            label: Text('$unreadCount'),
                            isLabelVisible: unreadCount > 0,
                            child: const Icon(
                              Icons.notifications_none_rounded,
                              size: 26,
                            ),
                          ),
                          onPressed: () => context.push('/notifications'),
                        ),
                        const SizedBox(width: AppDimensions.spacing8),
                        SeemeAvatar(
                          name: profile?.fullName ?? 'Student',
                          imageUrl: profile?.avatarUrl,
                          size: AppDimensions.avatarLg,
                          onTap: () => context.push('/profile'),
                          isVerified: profile?.isVerified ?? false,
                        ),
                      ],
                    ).animate().fadeIn(duration: 500.ms),
                    
                    // ─── Moderator Portal Access Banner ───────────
                    if (userRole.isAdminOrModerator) ...[
                      const SizedBox(height: AppDimensions.spacing16),
                      SeemeCard(
                        gradient: const LinearGradient(
                          colors: [AppColors.warning, Color(0xFFEA580C)],
                        ),
                        onTap: () => context.push('/moderator'),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.shield_outlined, color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: AppDimensions.spacing16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Moderator Portal',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  Text(
                                    'Review pending student verification requests',
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: Colors.white),
                          ],
                        ),
                      ).animate().fadeIn(delay: 100.ms),
                    ],

                    const SizedBox(height: AppDimensions.spacing20),

                    // ─── Quick Scan Button ──────────────────
                    SeemeCard(
                      gradient: AppColors.primaryGradient,
                      onTap: () => context.go('/scan'),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                            ),
                            child: const Icon(
                              Icons.qr_code_scanner_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.spacing16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Scan QR Code',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Connect with a student instantly',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.white.withValues(alpha: 0.8),
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideY(
                          begin: 0.2,
                          end: 0,
                        ),

                    const SizedBox(height: AppDimensions.spacing20),

                    // ─── Profile Completion ─────────────────
                    SeemeCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.pie_chart_outline_rounded,
                                color: AppColors.accent,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Profile Strength',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const Spacer(),
                              Text(
                                '${profile?.profileCompletion ?? 0}%',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      color: AppColors.accent,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.spacing12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (profile?.profileCompletion ?? 0) / 100.0,
                              backgroundColor: isDark
                                  ? AppColors.darkSurfaceVariant
                                  : AppColors.lightSurfaceVariant,
                              valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: AppDimensions.spacing8),
                          Text(
                            'Add your bio and social links to complete your profile',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextTertiary
                                      : AppColors.lightTextTertiary,
                                ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 300.ms, duration: 500.ms),

                    const SizedBox(height: AppDimensions.spacing24),

                    // ─── Section Title ─────────────────────
                    Text(
                      'Recent Connections',
                      style: Theme.of(context).textTheme.titleMedium,
                    ).animate().fadeIn(delay: 400.ms, duration: 500.ms),
                    const SizedBox(height: AppDimensions.spacing12),

                    // Recent connections list
                    historyAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Text('Error loading connections: $err'),
                      data: (history) {
                        if (history.isEmpty) {
                          return SeemeCard(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppDimensions.spacing24,
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.qr_code_2_rounded,
                                      size: 48,
                                      color: isDark
                                          ? AppColors.darkTextTertiary
                                          : AppColors.lightTextTertiary,
                                    ),
                                    const SizedBox(height: AppDimensions.spacing12),
                                    Text(
                                      'No connections yet',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: isDark
                                                ? AppColors.darkTextTertiary
                                                : AppColors.lightTextTertiary,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Scan a QR code to connect with students',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: isDark
                                                ? AppColors.darkTextTertiary
                                                : AppColors.lightTextTertiary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }

                        // Take top 3 recent scans
                        final recentList = history.take(3).toList();

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: recentList.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final entry = recentList[index];
                            final profileJson = entry['profiles'] as Map<String, dynamic>?;

                            if (profileJson == null) return const SizedBox.shrink();

                            final rollNumber = profileJson['roll_number'] as String;
                            final fullName = profileJson['full_name'] as String;
                            final avatarUrl = profileJson['avatar_url'] as String?;
                            final isVerified = profileJson['is_verified'] as bool? ?? false;

                            return SeemeCard(
                              onTap: () => context.push('/u/$rollNumber'),
                              child: Row(
                                children: [
                                  SeemeAvatar(
                                    name: fullName,
                                    imageUrl: avatarUrl,
                                    size: 40,
                                    isVerified: isVerified,
                                  ),
                                  const SizedBox(width: AppDimensions.spacing12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          fullName,
                                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          rollNumber,
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ).animate().fadeIn(delay: 500.ms, duration: 500.ms),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
