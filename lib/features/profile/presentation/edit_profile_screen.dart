import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/utils/logger.dart';
import '../../../shared/widgets/seeme_button.dart';
import '../../../shared/widgets/seeme_text_field.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/profile_repository.dart';

class EditProfileScreen extends HookConsumerWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profileAsync = ref.watch(currentUserProfileProvider);
    final isLoading = useState(false);

    // Form inputs state
    final nameController = useTextEditingController();
    final bioController = useTextEditingController();
    final skillController = useTextEditingController();
    final interestController = useTextEditingController();
    
    final skillsState = useState<List<String>>([]);
    final interestsState = useState<List<String>>([]);
    final newAvatarPath = useState<String?>(null);

    final formKey = useMemoized(() => GlobalKey<FormState>());

    // Initialize fields when profile is fetched
    useMemoized(() {
      profileAsync.whenData((profile) {
        if (profile != null) {
          nameController.text = profile.fullName;
          bioController.text = profile.bio ?? '';
          skillsState.value = List.from(profile.skills);
          interestsState.value = List.from(profile.interests);
        }
      });
    }, [profileAsync]);

    Future<void> pickAvatar(ImageSource source) async {
      try {
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(
          source: source,
          maxWidth: 400,
          maxHeight: 400,
          imageQuality: 80,
        );
        if (pickedFile != null) {
          newAvatarPath.value = pickedFile.path;
        }
      } catch (e) {
        if (context.mounted) {
          ErrorHandler.showSnackBar(context, e);
        }
      }
    }

    void showAvatarPicker() {
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
                  pickAvatar(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  context.pop();
                  pickAvatar(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      );
    }

    Future<void> handleSave() async {
      if (!formKey.currentState!.validate()) return;

      isLoading.value = true;
      try {
        final profile = ref.read(currentUserProfileProvider).valueOrNull;
        if (profile == null) throw Exception('Profile not found');

        final repo = ref.read(profileRepositoryProvider);

        // 1. Upload new avatar if selected
        String? updatedAvatarUrl = profile.avatarUrl;
        if (newAvatarPath.value != null) {
          updatedAvatarUrl = await repo.uploadAvatar(
            userId: profile.id,
            filePath: newAvatarPath.value!,
          );
        }

        // 2. Update profile fields
        final updatedProfile = profile.copyWith(
          fullName: nameController.text.trim(),
          bio: bioController.text.trim(),
          skills: skillsState.value,
          interests: interestsState.value,
          avatarUrl: updatedAvatarUrl,
        );

        final result = await repo.updateProfile(updatedProfile);

        // 3. Update the local state provider
        ref.read(currentUserProfileProvider.notifier).updateState(result);

        AppLogger.info('Profile updated successfully', 'EditProfileScreen');

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
          context.pop();
        }
      } catch (e) {
        if (context.mounted) {
          ErrorHandler.showSnackBar(context, e);
        }
      } finally {
        isLoading.value = false;
      }
    }

    void addSkill() {
      final skill = skillController.text.trim();
      if (skill.isNotEmpty && !skillsState.value.contains(skill)) {
        if (skillsState.value.length >= 20) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Maximum 20 skills allowed')),
          );
          return;
        }
        skillsState.value = [...skillsState.value, skill];
        skillController.clear();
      }
    }

    void addInterest() {
      final interest = interestController.text.trim();
      if (interest.isNotEmpty && !interestsState.value.contains(interest)) {
        if (interestsState.value.length >= 20) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Maximum 20 interests allowed')),
          );
          return;
        }
        interestsState.value = [...interestsState.value, interest];
        interestController.clear();
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (profile) {
            if (profile == null) {
              return const Center(child: Text('No profile found'));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ─── Edit Photo ────────────────────────────────
                    Center(
                      child: GestureDetector(
                        onTap: showAvatarPicker,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 54,
                              backgroundColor: isDark ? AppColors.darkSurfaceVariant : AppColors.lightBorder,
                              backgroundImage: newAvatarPath.value != null
                                  ? FileImage(File(newAvatarPath.value!)) as ImageProvider
                                  : (profile.avatarUrl != null ? NetworkImage(profile.avatarUrl!) : null),
                              child: newAvatarPath.value == null && profile.avatarUrl == null
                                  ? const Icon(Icons.person, size: 54, color: Colors.grey)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacing32),

                    // ─── Name Field ────────────────────────────────
                    SeemeTextField(
                      controller: nameController,
                      label: 'Full Name',
                      hint: 'Enter your full name',
                      prefixIcon: Icons.person_outline_rounded,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppDimensions.spacing16),

                    // ─── Bio Field ─────────────────────────────────
                    SeemeTextField(
                      controller: bioController,
                      label: 'Bio',
                      hint: 'Tell students about yourself (max 500 chars)',
                      prefixIcon: Icons.info_outline_rounded,
                      maxLines: 3,
                      maxLength: 500,
                      textCapitalization: TextCapitalization.sentences,
                      validator: (val) {
                        if (val != null && val.trim().length > 500) {
                          return 'Bio cannot exceed 500 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppDimensions.spacing16),

                    // ─── Skills Dynamic Chip Adder ─────────────────
                    Text(
                      'Skills',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppDimensions.spacing8),
                    Row(
                      children: [
                        Expanded(
                          child: SeemeTextField(
                            controller: skillController,
                            hint: 'Add a skill (e.g. Flutter)',
                            prefixIcon: Icons.construction_rounded,
                            textCapitalization: TextCapitalization.words,
                            onSubmitted: (_) => addSkill(),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spacing12),
                        SeemeButton(
                          label: 'Add',
                          onPressed: addSkill,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacing12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: skillsState.value.map((skill) {
                        return Chip(
                          label: Text(skill),
                          deleteIcon: const Icon(Icons.close_rounded, size: 16),
                          onDeleted: () {
                            skillsState.value = skillsState.value.where((s) => s != skill).toList();
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppDimensions.spacing24),

                    // ─── Interests Dynamic Chip Adder ──────────────
                    Text(
                      'Interests',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppDimensions.spacing8),
                    Row(
                      children: [
                        Expanded(
                          child: SeemeTextField(
                            controller: interestController,
                            hint: 'Add interest (e.g. Startup)',
                            prefixIcon: Icons.favorite_border_rounded,
                            textCapitalization: TextCapitalization.words,
                            onSubmitted: (_) => addInterest(),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spacing12),
                        SeemeButton(
                          label: 'Add',
                          onPressed: addInterest,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacing12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: interestsState.value.map((interest) {
                        return Chip(
                          label: Text(interest),
                          deleteIcon: const Icon(Icons.close_rounded, size: 16),
                          onDeleted: () {
                            interestsState.value = interestsState.value.where((i) => i != interest).toList();
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppDimensions.spacing40),

                    // ─── Action Buttons ────────────────────────────
                    SeemeButton(
                      label: 'Save Changes',
                      icon: Icons.check_rounded,
                      onPressed: handleSave,
                      isLoading: isLoading.value,
                    ),
                    const SizedBox(height: AppDimensions.spacing12),
                    SeemeButton(
                      label: 'Cancel',
                      isOutlined: true,
                      onPressed: () => context.pop(),
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
