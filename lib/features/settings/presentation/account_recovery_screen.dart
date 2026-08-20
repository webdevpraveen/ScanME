import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/network/supabase_client.dart';
import '../../../core/utils/logger.dart';
import '../../../shared/widgets/seeme_button.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../auth/providers/auth_providers.dart';

/// Screen displayed when a logged-in user's account is soft-deleted
class AccountRecoveryScreen extends HookConsumerWidget {
  const AccountRecoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profileAsync = ref.watch(currentUserProfileProvider);
    final isLoading = useState(false);

    Future<void> handleRecover() async {
      isLoading.value = true;
      try {
        final profile = ref.read(currentUserProfileProvider).valueOrNull;
        if (profile == null) throw Exception('Profile not found');

        final client = ref.read(supabaseClientProvider);
        
        // Call recover_account RPC function
        await client.rpc('recover_account', params: {
          'p_user_id': profile.id,
        });

        AppLogger.info('Account recovered successfully: ${profile.id}', 'AccountRecovery');

        // Refresh user profile
        await ref.read(currentUserProfileProvider.notifier).refresh();

        if (context.mounted) {
          context.go('/home');
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
      body: SafeArea(
        child: Center(
          child: profileAsync.when(
            loading: () => const CircularProgressIndicator(),
            error: (err, stack) => Text('Error loading profile: $err'),
            data: (profile) {
              if (profile == null) {
                return const Center(child: Text('No profile found.'));
              }

              final daysRemaining = profile.daysUntilPermanentDeletion ?? 30;

              return Padding(
                padding: const EdgeInsets.all(AppDimensions.spacing32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ─── Warning Icon ─────────────────────────────
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.settings_backup_restore_rounded,
                        color: AppColors.error,
                        size: 48,
                      ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true))
                     .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 1500.ms, curve: Curves.easeInOut),
                    const SizedBox(height: AppDimensions.spacing32),

                    Text(
                      'Account Scheduled for Deletion',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(duration: 400.ms),
                    const SizedBox(height: AppDimensions.spacing12),

                    Text(
                      'Your account is currently deactivated. You have $daysRemaining days left to recover your account and all data before it is permanently deleted.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                    const SizedBox(height: AppDimensions.spacing40),

                    // ─── Recover Button ───────────────────────────
                    SeemeButton(
                      label: 'Recover Account',
                      icon: Icons.restore_rounded,
                      onPressed: handleRecover,
                      isLoading: isLoading.value,
                    ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
                    const SizedBox(height: AppDimensions.spacing16),

                    // ─── Cancel/Sign Out Button ────────────────────
                    SeemeButton(
                      label: 'Cancel & Sign Out',
                      isOutlined: true,
                      onPressed: () async {
                        await ref.read(supabaseAuthProvider).signOut();
                        if (context.mounted) {
                          context.go('/login');
                        }
                      },
                    ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
