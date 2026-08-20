import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/network/supabase_client.dart';
import '../../../core/utils/logger.dart';
import '../../../shared/widgets/seeme_button.dart';
import '../../../shared/widgets/seeme_text_field.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../auth/providers/auth_providers.dart';

/// Screen displayed when user initiates account deletion
class AccountDeletionScreen extends HookConsumerWidget {
  const AccountDeletionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLoading = useState(false);
    final confirmTextController = useTextEditingController();
    final passwordController = useTextEditingController();
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final obscurePassword = useState(true);

    Future<void> handleDelete() async {
      if (!formKey.currentState!.validate()) return;
      if (confirmTextController.text.trim().toLowerCase() != 'delete') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please type "delete" to confirm')),
        );
        return;
      }

      isLoading.value = true;
      try {
        final profile = ref.read(currentUserProfileProvider).valueOrNull;
        if (profile == null) throw Exception('Profile not found');

        final client = ref.read(supabaseClientProvider);
        
        // 1. Re-authenticate / verify password before deleting (using Supabase auth.signIn)
        try {
          await client.auth.signInWithPassword(
            email: profile.email,
            password: passwordController.text,
          );
        } catch (_) {
          throw Exception('Incorrect password. Please verify and try again.');
        }

        // 2. Call soft_delete_account RPC function
        await client.rpc('soft_delete_account', params: {
          'p_user_id': profile.id,
        });

        AppLogger.info('Account soft-deleted: ${profile.id}', 'AccountDeletion');

        // 3. Sign out the user
        await client.auth.signOut();
        ref.invalidate(currentUserProfileProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account successfully deactivated. You can recover it within 30 days.')),
          );
          context.go('/login');
        }
      } catch (e) {
        if (context.mounted) {
          ErrorHandler.showSnackBar(context, e);
        }
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delete Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── Warning Header ───────────────────────────
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spacing16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
                          const SizedBox(width: AppDimensions.spacing12),
                          Text(
                            'Warning: Deletion is Permanent',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spacing8),
                      Text(
                        'Deleting your account will deactivate your profile and hide it from all other students. After 30 days, your profile, scan history, social links, and ID verification will be permanently and irreversibly purged from our systems.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: -0.1, end: 0),
                const SizedBox(height: AppDimensions.spacing24),

                Text(
                  'Confirm Account Deletion',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppDimensions.spacing16),

                // ─── Password Re-entry ─────────────────────────
                SeemeTextField(
                  controller: passwordController,
                  label: 'Password',
                  hint: 'Enter your password to confirm',
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: obscurePassword.value,
                  textInputAction: TextInputAction.next,
                  suffix: IconButton(
                    icon: Icon(
                      obscurePassword.value
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: AppDimensions.iconMd,
                    ),
                    onPressed: () => obscurePassword.value = !obscurePassword.value,
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Password is required to delete your account';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppDimensions.spacing16),

                // ─── Confirmation Text ────────────────────────
                SeemeTextField(
                  controller: confirmTextController,
                  label: 'Confirm Action',
                  hint: 'Type "delete" here',
                  prefixIcon: Icons.delete_outline_rounded,
                  textInputAction: TextInputAction.done,
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Confirmation text is required';
                    }
                    if (val.trim().toLowerCase() != 'delete') {
                      return 'Must match the word "delete" exactly';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppDimensions.spacing32),

                // ─── Action Buttons ───────────────────────────
                SeemeButton(
                  label: 'Deactivate & Schedule Deletion',
                  icon: Icons.delete_forever_rounded,
                  onPressed: handleDelete,
                  isLoading: isLoading.value,
                  isDestructive: true,
                ),
                const SizedBox(height: AppDimensions.spacing12),
                SeemeButton(
                  label: 'Cancel & Go Back',
                  isOutlined: true,
                  onPressed: () => context.pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
