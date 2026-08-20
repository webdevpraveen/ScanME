import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/network/supabase_client.dart';
import '../../../shared/widgets/seeme_avatar.dart';
import '../../../shared/widgets/seeme_card.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/profile_providers.dart';
import '../data/profile_repository.dart';
import '../../../shared/models/user_link_model.dart';

class PublicProfileScreen extends HookConsumerWidget {
  const PublicProfileScreen({
    super.key,
    required this.rollNumber,
  });

  final String rollNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Watch public profile
    final publicProfileAsync = ref.watch(publicProfileProvider(rollNumber));
    final myProfile = ref.watch(currentUserProfileProvider).valueOrNull;

    // Fetch links when profile is available
    final profileId = publicProfileAsync.valueOrNull?.id;
    final linksAsync = profileId != null
        ? ref.watch(userLinksProvider(profileId))
        : const AsyncValue<List<UserLinkModel>>.loading();

    // Automatically record profile view
    useEffect(() {
      if (myProfile != null && profileId != null && myProfile.id != profileId) {
        ref.read(profileRepositoryProvider).recordProfileView(
              viewerId: myProfile.id,
              viewedId: profileId,
            );
      }
      return null;
    }, [myProfile, profileId]);

    Future<void> launchLink(UserLinkModel link) async {
      try {
        final uri = Uri.parse(link.launchUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw Exception('Could not launch ${link.url}');
        }
      } catch (e) {
        if (context.mounted) {
          ErrorHandler.showSnackBar(context, e);
        }
      }
    }

    Future<void> handleBlock(String blockedId) async {
      if (myProfile == null) return;

      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Block Student?'),
          content: const Text('You will no longer be able to scan or see each other\'s profiles.'),
          actions: [
            TextButton(
              onPressed: () => context.pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => context.pop(true),
              child: const Text('Block', style: TextStyle(color: AppColors.error)),
            ),
          ],
        ),
      );

      if (confirm == true) {
        try {
          final client = ref.read(supabaseClientProvider);
          await client.from('blocked_users').insert({
            'blocker_id': myProfile.id,
            'blocked_id': blockedId,
          });

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Student blocked')),
            );
            context.go('/home');
          }
        } catch (e) {
          if (context.mounted) {
            ErrorHandler.showSnackBar(context, e);
          }
        }
      }
    }

    Future<void> handleReport(String reportedId) async {
      if (myProfile == null) return;

      final reasonController = TextEditingController();
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Report Profile'),
          content: TextField(
            controller: reasonController,
            decoration: const InputDecoration(
              labelText: 'Reason for report',
              hintText: 'e.g. Inappropriate content, fake ID',
            ),
            maxLines: 2,
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => context.pop(true),
              child: const Text('Report', style: TextStyle(color: AppColors.error)),
            ),
          ],
        ),
      );

      if (confirm == true && reasonController.text.trim().isNotEmpty) {
        try {
          final client = ref.read(supabaseClientProvider);
          await client.from('reported_profiles').insert({
            'reporter_id': myProfile.id,
            'reported_id': reportedId,
            'reason': reasonController.text.trim(),
            'status': 'pending',
          });

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile reported. Thank you for keeping SeeMe safe.')),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ErrorHandler.showSnackBar(context, e);
          }
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(rollNumber),
        actions: [
          if (profileId != null && myProfile != null && profileId != myProfile.id)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'block') {
                  handleBlock(profileId);
                } else if (value == 'report') {
                  handleReport(profileId);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'report',
                  child: Text('Report Profile', style: TextStyle(color: AppColors.error)),
                ),
                const PopupMenuItem(
                  value: 'block',
                  child: Text('Block Student', style: TextStyle(color: AppColors.error)),
                ),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: publicProfileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (profile) {
            if (profile == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.spacing32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person_off_rounded, size: 64, color: Colors.grey),
                      const SizedBox(height: AppDimensions.spacing16),
                      Text(
                        'Profile Not Found',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This student\'s profile may have been hidden, deleted, or is not public.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ─── Header ──────────────────────────────────
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

                      // ─── Bio Section ─────────────────────────────
                      if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                        SeemeCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'About',
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
                        ).animate().fadeIn(delay: 100.ms),
                        const SizedBox(height: AppDimensions.spacing16),
                      ],

                      // ─── Skills Section ──────────────────────────
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
                        ).animate().fadeIn(delay: 200.ms),
                        const SizedBox(height: AppDimensions.spacing16),
                      ],

                      // ─── Social Links Section ────────────────────
                      SeemeCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Connect',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: AppDimensions.spacing16),
                            linksAsync.when(
                              loading: () => const Center(child: CircularProgressIndicator()),
                              error: (err, stack) => Text('Error loading links: $err'),
                              data: (links) {
                                final visibleLinks = links.where((l) => l.isVisible).toList();

                                if (visibleLinks.isEmpty) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacing16),
                                    child: Text(
                                      'No visible links shared.',
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
                                  itemCount: visibleLinks.length,
                                  separatorBuilder: (context, index) => const Divider(),
                                  itemBuilder: (context, index) {
                                    final link = visibleLinks[index];
                                    return ListTile(
                                      leading: Icon(
                                        _getPlatformIcon(link.platform.name),
                                        color: AppColors.primary,
                                      ),
                                      title: Text(link.displayName ?? link.platform.displayName),
                                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                                      onTap: () => launchLink(link),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 300.ms),
                    ],
                  ),
                ),
              ),
            );
          },
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
