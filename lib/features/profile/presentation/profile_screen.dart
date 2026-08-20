import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../shared/widgets/seeme_avatar.dart';
import '../../../shared/widgets/seeme_button.dart';
import '../../../shared/widgets/seeme_card.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/profile_providers.dart';

/// Display own profile details, college info, skills, links, and profile completion
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profileAsync = ref.watch(currentUserProfileProvider);
    final linksAsync = ref.watch(myLinksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_2_rounded),
            tooltip: 'My QR Code',
            onPressed: () => context.push('/profile/qr'),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Profile',
            onPressed: () => context.push('/profile/edit'),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(myLinksProvider);
            await ref.read(currentUserProfileProvider.notifier).refresh();
          },
          child: profileAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error loading profile: $err')),
            data: (profile) {
              if (profile == null) {
                return const Center(child: Text('No profile found'));
              }

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.pagePaddingH,
                  vertical: AppDimensions.pagePaddingV,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ─── Profile Header ────────────────────────
                        SeemeCard(
                          child: Column(
                            children: [
                              SeemeAvatar(
                                name: profile.fullName,
                                imageUrl: profile.avatarUrl,
                                size: 96,
                                isVerified: profile.isVerified,
                              ),
                              const SizedBox(height: AppDimensions.spacing16),
                              Text(
                                profile.fullName,
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                profile.rollNumber,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppDimensions.spacing12),
                              
                              // College & Roll info
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.school_outlined, size: 16, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      profile.collegeName,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              
                              if (profile.department != null || profile.academicYear != null)
                                Text(
                                  '${profile.department ?? ''} ${profile.department != null && profile.academicYear != null ? '•' : ''} ${profile.academicYear ?? ''}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                            ],
                          ),
                        ).animate().fadeIn().slideY(begin: 0.1, end: 0),
                        const SizedBox(height: AppDimensions.spacing16),

                        // ─── Profile Completion Tracker ─────────────
                        SeemeCard(
                          child: Row(
                            children: [
                              CircularProgressIndicator(
                                value: profile.profileCompletion / 100.0,
                                backgroundColor: isDark ? AppColors.darkSurfaceVariant : AppColors.lightBorder,
                                strokeWidth: 6,
                              ),
                              const SizedBox(width: AppDimensions.spacing16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Profile Strength: ${profile.profileCompletion}%',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Add links, avatar, and skills to verify and complete your profile.',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 100.ms),
                        const SizedBox(height: AppDimensions.spacing16),

                        // ─── Bio Section ───────────────────────────
                        if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                          SeemeCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'About Me',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: AppDimensions.spacing8),
                                Text(
                                  profile.bio!,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                      ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: 200.ms),
                          const SizedBox(height: AppDimensions.spacing16),
                        ],

                        // ─── Skills Section ────────────────────────
                        if (profile.skills.isNotEmpty) ...[
                          SeemeCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Skills',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: AppDimensions.spacing12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: profile.skills.map((skill) {
                                    return Chip(
                                      label: Text(skill),
                                      backgroundColor: isDark
                                          ? AppColors.darkSurfaceVariant
                                          : AppColors.lightSurfaceVariant,
                                      side: BorderSide(
                                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: 300.ms),
                          const SizedBox(height: AppDimensions.spacing16),
                        ],

                        // ─── Social Links Section ──────────────────
                        SeemeCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Social & Contact Links',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  TextButton(
                                    onPressed: () => context.push('/profile/links'),
                                    child: const Text('Manage'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppDimensions.spacing8),
                              linksAsync.when(
                                loading: () => const Center(child: CircularProgressIndicator()),
                                error: (err, stack) => Text('Error loading links: $err'),
                                data: (links) {
                                  if (links.isEmpty) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacing16),
                                      child: Text(
                                        'No links added yet. Let students know where to find you!',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                                              fontStyle: FontStyle.italic,
                                            ),
                                        textAlign: TextAlign.center,
                                      ),
                                    );
                                  }

                                  return ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: links.length,
                                    separatorBuilder: (context, index) => const Divider(),
                                    itemBuilder: (context, index) {
                                      final link = links[index];
                                      return ListTile(
                                        leading: Icon(
                                          _getPlatformIcon(link.platform.name),
                                          color: AppColors.primary,
                                        ),
                                        title: Text(link.displayName ?? link.platform.displayName),
                                        subtitle: Text(
                                          link.url,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: Colors.grey,
                                              ),
                                        ),
                                        trailing: Icon(
                                          link.isVisible
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          size: 18,
                                          color: Colors.grey,
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 400.ms),
                        const SizedBox(height: AppDimensions.spacing32),

                        // ─── Secondary Settings Route ──────────────
                        SeemeButton(
                          label: 'Go to Settings',
                          icon: Icons.settings_outlined,
                          isOutlined: true,
                          onPressed: () => context.go('/settings'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform) {
      case 'phone':
        return Icons.phone_android_rounded;
      case 'whatsapp':
        return Icons.chat_bubble_outline_rounded;
      case 'email':
        return Icons.email_outlined;
      case 'instagram':
        return Icons.camera_alt_outlined;
      case 'linkedin':
        return Icons.work_outline_rounded;
      case 'github':
        return Icons.code_rounded;
      case 'x':
        return Icons.close_rounded;
      case 'portfolio':
        return Icons.language_rounded;
      default:
        return Icons.link_rounded;
    }
  }
}
