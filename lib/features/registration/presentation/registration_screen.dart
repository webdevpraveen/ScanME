import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../shared/widgets/seeme_button.dart';
import '../../../shared/widgets/seeme_text_field.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../core/validators/input_validators.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/debouncer.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/data/auth_repository.dart';
import '../data/registration_repository.dart';

/// Multi-step registration screen for SRMU Single College
/// Step 1: Account info (name, roll number, department, year, email, password)
/// Step 2: ID card upload
class RegistrationScreen extends HookConsumerWidget {
  const RegistrationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStep = useState(0);
    final isLoading = useState(false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Step 1 controllers
    final nameController = useTextEditingController();
    final rollNumberController = useTextEditingController();
    final departmentController = useTextEditingController();
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final confirmPasswordController = useTextEditingController();
    final selectedYear = useState<String?>(null);

    // Form keys
    final step1FormKey = useMemoized(() => GlobalKey<FormState>());

    // Roll number availability
    final rollNumberAvailable = useState<bool?>(null);
    final rollNumberChecking = useState(false);
    final obscurePassword = useState(true);
    final obscureConfirmPassword = useState(true);
    final idCardImagePath = useState<String?>(null);

    // Debounce roll number validation
    final debouncer = useMemoized(() => Debouncer(duration: const Duration(milliseconds: 500)));
    useEffect(() => debouncer.dispose, [debouncer]);

    useEffect(() {
      void listener() {
        final rollNumber = rollNumberController.text.trim();
        if (rollNumber.length != AppConstants.rollNumberLength || !RegExp(r'^[0-9]+$').hasMatch(rollNumber)) {
          rollNumberAvailable.value = null;
          rollNumberChecking.value = false;
          return;
        }

        rollNumberChecking.value = true;
        debouncer.run(() async {
          try {
            final available = await ref.read(registrationRepositoryProvider).isRollNumberAvailable(rollNumber);
            rollNumberAvailable.value = available;
          } catch (_) {
            rollNumberAvailable.value = false;
          } finally {
            rollNumberChecking.value = false;
          }
        });
      }

      rollNumberController.addListener(listener);
      return () => rollNumberController.removeListener(listener);
    }, [rollNumberController, debouncer]);

    final years = ['1st Year', '2nd Year', '3rd Year', '4th Year', '5th Year'];

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

    Future<void> handleRegistration() async {
      isLoading.value = true;
      try {
        // 1. Create auth account
        final authResponse = await ref.read(authRepositoryProvider).signUp(
              email: emailController.text.trim(),
              password: passwordController.text,
              metadata: {
                'full_name': nameController.text.trim(),
                'roll_number': rollNumberController.text.trim(),
              },
            );

        if (authResponse.user == null) {
          throw Exception('Registration failed');
        }

        // 2. Complete profile record
        await ref.read(registrationRepositoryProvider).completeRegistration(
              userId: authResponse.user!.id,
              rollNumber: rollNumberController.text.trim(),
              fullName: nameController.text.trim(),
              email: emailController.text.trim(),
              department: departmentController.text.trim(),
              academicYear: selectedYear.value,
            );

        // 3. Upload ID Card image
        if (idCardImagePath.value != null) {
          await ref.read(registrationRepositoryProvider).uploadIdCard(
                userId: authResponse.user!.id,
                filePath: idCardImagePath.value!,
              );
        }

        AppLogger.auth('Registration complete');

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

    Widget buildStepIndicator() {
      return Row(
        children: List.generate(2, (index) {
          final isActive = index <= currentStep.value;
          final isCurrent = index == currentStep.value;
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < 1 ? 8 : 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: isActive ? AppColors.primaryGradient : null,
                color: isActive
                    ? null
                    : (isDark ? AppColors.darkSurfaceVariant : AppColors.lightBorder),
              ),
            ).animate(target: isCurrent ? 1 : 0).shimmer(
                  duration: 1500.ms,
                  color: AppColors.accent.withValues(alpha: 0.3),
                ),
          );
        }),
      );
    }

    Widget buildStep1() {
      return Form(
        key: step1FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Create your SRMU account',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppDimensions.spacing8),
            Text(
              'Enter your SRMU details to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
            ),
            const SizedBox(height: AppDimensions.spacing32),

            SeemeTextField(
              controller: nameController,
              label: 'Full Name',
              hint: 'Enter your full name',
              prefixIcon: Icons.person_outline_rounded,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              validator: InputValidators.fullName,
            ),
            const SizedBox(height: AppDimensions.spacing16),

            SeemeTextField(
              controller: rollNumberController,
              label: 'Roll Number',
              hint: 'Enter your 15-digit roll number',
              prefixIcon: Icons.badge_outlined,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              validator: InputValidators.rollNumber,
              helperText: rollNumberChecking.value
                  ? 'Checking availability...'
                  : rollNumberAvailable.value == true
                      ? '✓ Roll number available'
                      : rollNumberAvailable.value == false
                          ? '✗ Roll number already registered'
                          : 'Must be exactly 15 digits',
            ),
            const SizedBox(height: AppDimensions.spacing16),

            SeemeTextField(
              controller: departmentController,
              label: 'Department',
              hint: 'e.g., Computer Science',
              prefixIcon: Icons.domain_outlined,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              validator: InputValidators.department,
            ),
            const SizedBox(height: AppDimensions.spacing16),

            DropdownButtonFormField<String>(
              value: selectedYear.value,
              decoration: InputDecoration(
                labelText: 'Academic Year',
                hintText: 'Select your year',
                prefixIcon: const Icon(Icons.calendar_today_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
              ),
              items: years.map((year) {
                return DropdownMenuItem(value: year, child: Text(year));
              }).toList(),
              onChanged: (value) => selectedYear.value = value,
              validator: (value) => value == null ? 'Please select a year' : null,
            ),
            const SizedBox(height: AppDimensions.spacing16),

            SeemeTextField(
              controller: emailController,
              label: 'Email',
              hint: 'Enter your email',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: InputValidators.email,
            ),
            const SizedBox(height: AppDimensions.spacing16),

            SeemeTextField(
              controller: passwordController,
              label: 'Password',
              hint: 'Create a strong password',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: obscurePassword.value,
              textInputAction: TextInputAction.next,
              validator: InputValidators.password,
              suffix: IconButton(
                icon: Icon(
                  obscurePassword.value
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: AppDimensions.iconMd,
                ),
                onPressed: () => obscurePassword.value = !obscurePassword.value,
              ),
            ),
            const SizedBox(height: AppDimensions.spacing16),

            SeemeTextField(
              controller: confirmPasswordController,
              label: 'Confirm Password',
              hint: 'Re-enter your password',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: obscureConfirmPassword.value,
              textInputAction: TextInputAction.done,
              validator: (value) => InputValidators.confirmPassword(
                value,
                passwordController.text,
              ),
              suffix: IconButton(
                icon: Icon(
                  obscureConfirmPassword.value
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: AppDimensions.iconMd,
                ),
                onPressed: () => obscureConfirmPassword.value = !obscureConfirmPassword.value,
              ),
            ),
            const SizedBox(height: AppDimensions.spacing32),

            SeemeButton(
              label: 'Continue',
              icon: Icons.arrow_forward_rounded,
              onPressed: () {
                if (step1FormKey.currentState!.validate()) {
                  if (rollNumberAvailable.value == true) {
                    currentStep.value = 1;
                  } else {
                    ErrorHandler.showSnackBar(context, 'Please wait or enter a valid roll number');
                  }
                }
              },
            ),
          ],
        ),
      );
    }

    Widget buildStep2() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Verify your identity',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppDimensions.spacing8),
          Text(
            'Upload the front side of your SRMU ID card',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
          ),
          const SizedBox(height: AppDimensions.spacing32),

          // ID Card Upload Area
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
                    : null,
              ),
              child: idCardImagePath.value == null
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
                          'Tap to upload ID card',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: AppColors.primary,
                              ),
                        ),
                        const SizedBox(height: AppDimensions.spacing4),
                        Text(
                          'JPG, PNG or WebP • Max 10MB',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? AppColors.darkTextTertiary
                                    : AppColors.lightTextTertiary,
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
          const SizedBox(height: AppDimensions.spacing16),

          Container(
            padding: const EdgeInsets.all(AppDimensions.spacing12),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(
                color: AppColors.info.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.info,
                  size: 20,
                ),
                const SizedBox(width: AppDimensions.spacing12),
                Expanded(
                  child: Text(
                    'Your ID card will be reviewed by a moderator. This usually takes 24-48 hours.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.info,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spacing32),

          Row(
            children: [
              Expanded(
                child: SeemeButton(
                  label: 'Back',
                  onPressed: () => currentStep.value = 0,
                  isOutlined: true,
                ),
              ),
              const SizedBox(width: AppDimensions.spacing12),
              Expanded(
                flex: 2,
                child: SeemeButton(
                  label: 'Submit for Review',
                  icon: Icons.check_circle_outline_rounded,
                  onPressed: () {
                    if (idCardImagePath.value == null) {
                      ErrorHandler.showSnackBar(context, 'Please upload your ID card');
                      return;
                    }
                    handleRegistration();
                  },
                  isLoading: isLoading.value,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: currentStep.value > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => currentStep.value = currentStep.value - 1,
              )
            : IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => context.pop(),
              ),
        title: Text('Step ${currentStep.value + 1} of 2'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
               padding: const EdgeInsets.symmetric(
                 horizontal: AppDimensions.pagePaddingH,
               ),
               child: buildStepIndicator(),
            ),
            const SizedBox(height: AppDimensions.spacing24),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.pagePaddingH,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppDimensions.maxFormWidth,
                  ),
                  child: AnimatedSwitcher(
                    duration: AppDimensions.animNormal,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.1, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: switch (currentStep.value) {
                      0 => buildStep1(),
                      1 => buildStep2(),
                      _ => buildStep1(),
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
