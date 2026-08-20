import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/network/supabase_client.dart';
import '../../../shared/models/enums.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../auth/providers/auth_providers.dart';
import '../../profile/data/profile_repository.dart';

/// Settings screen with grouped, fully interactive operations
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    final userRole = ref.watch(userRoleProvider);

    Future<void> updateVisibility(VisibilityLevel newLevel) async {
      if (profile == null) return;
      try {
        final updatedProfile = profile.copyWith(visibility: newLevel);
        final result = await ref.read(profileRepositoryProvider).updateProfile(updatedProfile);
        ref.read(currentUserProfileProvider.notifier).updateState(result);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Visibility updated to: ${newLevel.displayName}')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ErrorHandler.showSnackBar(context, e);
        }
      }
    }

    void showVisibilitySelector() {
      if (profile == null) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Profile Visibility'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: VisibilityLevel.values.map((level) {
              return RadioListTile<VisibilityLevel>(
                title: Text(level.displayName),
                subtitle: Text(level.description, style: const TextStyle(fontSize: 12)),
                value: level,
                groupValue: profile.visibility,
                onChanged: (val) {
                  if (val != null) {
                    context.pop();
                    updateVisibility(val);
                  }
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }

    Future<void> handleSignOut() async {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out of SeeMe?'),
          actions: [
            TextButton(
              onPressed: () => context.pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => context.pop(true),
              child: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await ref.read(supabaseAuthProvider).signOut();
        ref.invalidate(currentUserProfileProvider);
        if (context.mounted) {
          context.go('/login');
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
        children: [
          _SettingsSection(
            title: 'Account',
            children: [
              _SettingsTile(
                icon: Icons.person_outline_rounded,
                title: 'Edit Profile',
                onTap: () => context.push('/profile/edit'),
              ),
              _SettingsTile(
                icon: Icons.link_rounded,
                title: 'Social Links',
                onTap: () => context.push('/profile/links'),
              ),
              _SettingsTile(
                icon: Icons.qr_code_rounded,
                title: 'My QR Code',
                onTap: () => context.push('/profile/qr'),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing16),
          _SettingsSection(
            title: 'Privacy',
            children: [
              _SettingsTile(
                icon: Icons.visibility_outlined,
                title: 'Profile Visibility',
                subtitle: profile?.visibility.displayName ?? 'Public',
                onTap: showVisibilitySelector,
              ),
            ],
          ),
          if (userRole.isAdmin) ...[
            const SizedBox(height: AppDimensions.spacing16),
            _SettingsSection(
              title: 'Administration',
              children: [
                _SettingsTile(
                  icon: Icons.admin_panel_settings_outlined,
                  title: 'Admin Dashboard',
                  onTap: () => context.push('/admin'),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppDimensions.spacing16),
          _SettingsSection(
            title: 'About',
            children: [
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                onTap: () {
                  // In production, launches privacy policy URL
                },
              ),
              _SettingsTile(
                icon: Icons.description_outlined,
                title: 'Terms of Service',
                onTap: () {
                  // In production, launches terms URL
                },
              ),
              _SettingsTile(
                icon: Icons.info_outline_rounded,
                title: 'App Version',
                subtitle: '1.0.0 (1)',
                onTap: null,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing16),
          _SettingsSection(
            title: 'Danger Zone',
            children: [
              _SettingsTile(
                icon: Icons.delete_outline_rounded,
                title: 'Delete Account',
                titleColor: AppColors.error,
                onTap: () => context.push('/account-delete'),
              ),
              _SettingsTile(
                icon: Icons.logout_rounded,
                title: 'Sign Out',
                titleColor: AppColors.error,
                onTap: handleSignOut,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                letterSpacing: 1,
              ),
        ),
        const SizedBox(height: AppDimensions.spacing8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.titleColor,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: Icon(
        icon,
        color: titleColor ??
            (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
        size: 22,
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: titleColor,
            ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
                  ),
            )
          : null,
      trailing: onTap != null
          ? Icon(
              Icons.chevron_right_rounded,
              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
              size: 20,
            )
          : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
    );
  }
}
