import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../shared/widgets/seeme_button.dart';
import '../../../shared/widgets/seeme_text_field.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../core/validators/input_validators.dart';
import '../../../core/errors/error_handler.dart';
import '../data/auth_repository.dart';

class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final isLoading = useState(false);
    final obscurePassword = useState(true);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Future<void> handleLogin() async {
      if (!formKey.currentState!.validate()) return;

      isLoading.value = true;
      try {
        await ref.read(authRepositoryProvider).signIn(
              email: emailController.text.trim(),
              password: passwordController.text,
            );
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.pagePaddingH,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppDimensions.maxFormWidth,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ─── Logo & Welcome ────────────────────
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusXl,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ).animate().fadeIn(duration: 600.ms).scale(
                          begin: const Offset(0.8, 0.8),
                          end: const Offset(1, 1),
                          duration: 600.ms,
                          curve: Curves.easeOutBack,
                        ),
                    const SizedBox(height: AppDimensions.spacing24),

                    Text(
                      'Welcome back',
                      style: Theme.of(context).textTheme.displaySmall,
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(
                          begin: 0.3,
                          end: 0,
                          duration: 400.ms,
                          curve: Curves.easeOut,
                        ),
                    const SizedBox(height: AppDimensions.spacing8),

                    Text(
                      'Sign in to your SeeMe account',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

                    const SizedBox(height: AppDimensions.spacing40),

                    // ─── Email Field ───────────────────────
                    SeemeTextField(
                      controller: emailController,
                      label: 'Email',
                      hint: 'Enter your email',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: InputValidators.email,
                    ).animate().fadeIn(delay: 400.ms, duration: 400.ms).slideX(
                          begin: -0.1,
                          end: 0,
                          duration: 400.ms,
                        ),
                    const SizedBox(height: AppDimensions.spacing16),

                    // ─── Password Field ────────────────────
                    SeemeTextField(
                      controller: passwordController,
                      label: 'Password',
                      hint: 'Enter your password',
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: obscurePassword.value,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => handleLogin(),
                      suffix: IconButton(
                        icon: Icon(
                          obscurePassword.value
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: AppDimensions.iconMd,
                        ),
                        onPressed: () {
                          obscurePassword.value = !obscurePassword.value;
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password is required';
                        }
                        return null;
                      },
                    ).animate().fadeIn(delay: 500.ms, duration: 400.ms).slideX(
                          begin: -0.1,
                          end: 0,
                          duration: 400.ms,
                        ),

                    // ─── Forgot Password ───────────────────
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.push('/forgot-password'),
                        child: const Text('Forgot password?'),
                      ),
                    ).animate().fadeIn(delay: 550.ms, duration: 400.ms),
                    const SizedBox(height: AppDimensions.spacing8),

                    // ─── Login Button ──────────────────────
                    SeemeButton(
                      label: 'Sign In',
                      onPressed: handleLogin,
                      isLoading: isLoading.value,
                      icon: Icons.login_rounded,
                    ).animate().fadeIn(delay: 600.ms, duration: 400.ms).slideY(
                          begin: 0.2,
                          end: 0,
                          duration: 400.ms,
                        ),
                    const SizedBox(height: AppDimensions.spacing24),

                    // ─── Register Link ─────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/register'),
                          child: const Text('Sign Up'),
                        ),
                      ],
                    ).animate().fadeIn(delay: 700.ms, duration: 400.ms),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
