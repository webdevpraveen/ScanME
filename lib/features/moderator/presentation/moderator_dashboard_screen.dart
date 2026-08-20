import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/errors/error_handler.dart';
import '../../../shared/widgets/seeme_avatar.dart';
import '../../../shared/widgets/seeme_button.dart';
import '../../../shared/widgets/seeme_card.dart';
import '../../../shared/widgets/seeme_error_view.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import 'moderator_providers.dart';
import '../../auth/providers/auth_providers.dart';

/// Screen for moderators to review student registrations and IDs
class ModeratorDashboardScreen extends HookConsumerWidget {
  const ModeratorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Access control check
    final userRole = ref.watch(userRoleProvider);
    if (!userRole.isAdminOrModerator) {
      return const Scaffold(
        body: Center(child: Text('Access Denied: Moderator permissions required.')),
      );
    }

    final verificationsAsync = ref.watch(pendingVerificationsProvider);
    final rejectNotesController = useTextEditingController();

    Future<void> handleApprove(String verificationId, String studentId) async {
      try {
        await ref.read(pendingVerificationsProvider.notifier).approve(verificationId, studentId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration approved')),
          );
        }
      } catch (e) {
        if (context.mounted) ErrorHandler.showSnackBar(context, e);
      }
    }

    Future<void> handleReject(String verificationId, String studentId) async {
      rejectNotesController.clear();
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reject Verification'),
          content: TextField(
            controller: rejectNotesController,
            decoration: const InputDecoration(
              labelText: 'Rejection Notes / Reason',
              hintText: 'e.g. ID card blur, roll number mismatch',
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
              child: const Text('Reject', style: TextStyle(color: AppColors.error)),
            ),
          ],
        ),
      );

      if (confirm == true && rejectNotesController.text.trim().isNotEmpty) {
        try {
          await ref.read(pendingVerificationsProvider.notifier).reject(
                verificationId,
                studentId,
                rejectNotesController.text.trim(),
              );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Registration rejected')),
            );
          }
        } catch (e) {
          if (context.mounted) ErrorHandler.showSnackBar(context, e);
        }
      }
    }

    void showImageZoomDialog(String imageUrl) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          insetPadding: const EdgeInsets.all(12),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(imageUrl),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
                style: IconButton.styleFrom(backgroundColor: Colors.black54),
                onPressed: () => context.pop(),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Moderator Dashboard'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(pendingVerificationsProvider),
          child: verificationsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => SeemeErrorView(
              message: 'Failed to load verifications: $err',
              onRetry: () => ref.invalidate(pendingVerificationsProvider),
            ),
            data: (list) {
              if (list.isEmpty) {
                return const SeemeEmptyView(
                  icon: Icons.rate_review_rounded,
                  title: 'All Caught Up!',
                  message: 'No pending student verifications to review right now.',
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
                itemCount: list.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final verification = list[index];
                  final profile = verification['profiles'] as Map<String, dynamic>;
                  final studentName = profile['full_name'] as String;
                  final rollNumber = verification['roll_number_declared'] ?? 'N/A';
                  final imageUrl = verification['id_card_front_url'] as String?;
                  final isResubmitted = verification['status'] == 'resubmitted';
                  final attempt = verification['attempt_number'] ?? 1;

                  return SeemeCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header student info
                        Row(
                          children: [
                            SeemeAvatar(
                              name: studentName,
                              imageUrl: null,
                              size: 40,
                              isVerified: false,
                            ),
                            const SizedBox(width: AppDimensions.spacing12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    studentName,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Attempt $attempt',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            if (isResubmitted)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                                ),
                                child: const Text(
                                  'Resubmitted',
                                  style: TextStyle(color: AppColors.warning, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.spacing16),

                        // Declared Roll Info
                        Text('Declared Roll No: $rollNumber', style: const TextStyle(fontSize: 13)),
                        const SizedBox(height: AppDimensions.spacing16),

                        // ID Card image attachment
                        if (imageUrl != null) ...[
                          GestureDetector(
                            onTap: () => showImageZoomDialog(imageUrl),
                            child: Container(
                              height: 150,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                                image: DecorationImage(
                                  image: NetworkImage(imageUrl),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: Container(
                                alignment: Alignment.bottomRight,
                                padding: const EdgeInsets.all(8),
                                color: Colors.black26,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black87,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppDimensions.spacing20),
                        ],

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: SeemeButton(
                                label: 'Reject',
                                isOutlined: true,
                                isDestructive: true,
                                onPressed: () => handleReject(verification['id'] as String, verification['user_id'] as String),
                              ),
                            ),
                            const SizedBox(width: AppDimensions.spacing12),
                            Expanded(
                              child: SeemeButton(
                                label: 'Approve',
                                onPressed: () => handleApprove(verification['id'] as String, verification['user_id'] as String),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: (index * 60).ms).slideY(begin: 0.1, end: 0);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
