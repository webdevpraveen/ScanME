import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/utils/logger.dart';
import '../../../core/validators/input_validators.dart';
import '../../../shared/widgets/seeme_button.dart';
import '../../../shared/widgets/seeme_text_field.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../auth/providers/auth_providers.dart';
import '../../../core/network/supabase_client.dart';
import '../data/registration_repository.dart';

/// Screen displayed when verification is rejected, allowing the user to resubmit
class VerificationRejectedScreen extends HookConsumerWidget {
  const VerificationRejectedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Fetch latest verification details
    final verificationAsync = ref.watch(latestVerificationProvider);
    
    final rollNumberController = useTextEditingController();
    final idCardImagePath = useState<String?>(null);
    final idCardExistingUrl = useState<String?>(null);
    final isLoading = useState(false);
    final formKey = useMemoized(() => GlobalKey<FormState>());

    // Initialize fields once verification data is loaded
    useMemoized(() {
      verificationAsync.whenData((data) {
        if (data != null) {
          rollNumberController.text = data['roll_number_declared'] ?? '';
          idCardExistingUrl.value = data['id_card_front_url'];
        }
      });
    }, [verificationAsync]);

    Future<void> pickImage(ImageSource source) async {
      try {
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(
          source: source,
          maxWidth: 1200,
          maxHeight: 1200,
          imageQuality: 85,
        );
        if (pickedFile != null) {
          idCardImagePath.value = pickedFile.path;
        }
      } catch (e) {
        if (context.mounted) {
          ErrorHandler.showSnackBar(context, e);
        }
      }
    }

    void showImageSourceSelector() {
      showModalBottomSheet(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take Photo'),
                onTap: () {
                  context.pop();
                  pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  context.pop();
                  pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      );
    }

    Future<void> handleResubmit() async {
      if (!formKey.currentState!.validate()) return;
      if (idCardImagePath.value == null && idCardExistingUrl.value == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please upload an ID card image')),
        );
        return;
      }

      isLoading.value = true;
      try {
        final profile = ref.read(currentUserProfileProvider).valueOrNull;
        if (profile == null) throw Exception('Profile not found');

        final repo = ref.read(registrationRepositoryProvider);
        
        // 1. Upload new image if chosen
        String? finalImageUrl = idCardExistingUrl.value;
        if (idCardImagePath.value != null) {
          finalImageUrl = await repo.uploadIdCard(
            userId: profile.id,
            filePath: idCardImagePath.value!,
          );
        }

        // 2. Resubmit verification
        await repo.resubmitVerification(
          userId: profile.id,
          rollNumber: rollNumberController.text.trim(),
          idCardUrl: finalImageUrl,
        );

        AppLogger.info('Resubmitted verification successfully', 'VerificationRejected');

        // 3. Refresh profile/verification states
        ref.invalidate(latestVerificationProvider);
        await ref.read(currentUserProfileProvider.notifier).refresh();

        if (context.mounted) {
          context.go('/verification-pending');
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
        title: const Text('Re-submit Verification'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await ref.read(supabaseAuthProvider).signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: verificationAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (verification) {
            if (verification == null) {
              return const Center(child: Text('No verification record found.'));
            }

            final reason = verification['review_notes'] ?? 'No reason provided by moderator.';

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ─── Rejection Reason Banner ───────────────────
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
                              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 24),
                              const SizedBox(width: AppDimensions.spacing12),
                              Text(
                                'Verification Rejected',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.spacing8),
                          Text(
                            'Reason: $reason',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn().slideY(begin: -0.1, end: 0),
                    const SizedBox(height: AppDimensions.spacing24),

                    Text(
                      'Update Details & Resubmit',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppDimensions.spacing4),
                    Text(
                      'Please verify and correct the details below.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                          ),
                    ),
                    const SizedBox(height: AppDimensions.spacing24),

                    // ─── Roll Number ───────────────────────────────
                    SeemeTextField(
                      controller: rollNumberController,
                      label: 'Roll Number',
                      hint: 'Enter your correct roll number',
                      prefixIcon: Icons.badge_outlined,
                      textInputAction: TextInputAction.done,
                      validator: InputValidators.rollNumber,
                    ),
                    const SizedBox(height: AppDimensions.spacing24),

                    // ─── ID Card Upload Area ───────────────────────
                    Text(
                      'College ID Card (Front)',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppDimensions.spacing8),
                    GestureDetector(
                      onTap: showImageSourceSelector,
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            width: 2,
                            strokeAlign: BorderSide.strokeAlignInside,
                          ),
                          color: AppColors.primary.withValues(alpha: 0.05),
                          image: idCardImagePath.value != null
                              ? DecorationImage(
                                  image: FileImage(File(idCardImagePath.value!)),
                                  fit: BoxFit.cover,
                                )
                              : (idCardExistingUrl.value != null
                                  ? DecorationImage(
                                      image: NetworkImage(idCardExistingUrl.value!),
                                      fit: BoxFit.cover,
                                    )
                                  : null),
                        ),
                        child: idCardImagePath.value == null && idCardExistingUrl.value == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.add_a_photo_outlined,
                                      color: AppColors.primary,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(height: AppDimensions.spacing16),
                                  Text(
                                    'Tap to upload new ID card photo',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          color: AppColors.primary,
                                        ),
                                  ),
                                ],
                              )
                            : Container(
                                alignment: Alignment.bottomRight,
                                padding: const EdgeInsets.all(AppDimensions.spacing12),
                                color: Colors.black38,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.edit, color: Colors.white, size: 14),
                                      SizedBox(width: 4),
                                      Text(
                                        'Change Photo',
                                        style: TextStyle(color: Colors.white, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacing32),

                    // ─── Resubmit Button ───────────────────────────
                    SeemeButton(
                      label: 'Resubmit for Review',
                      icon: Icons.check_circle_outline_rounded,
                      onPressed: handleResubmit,
                      isLoading: isLoading.value,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
