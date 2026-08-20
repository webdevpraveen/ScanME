import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../shared/widgets/seeme_avatar.dart';
import '../../../shared/widgets/seeme_button.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../auth/providers/auth_providers.dart';

/// Screen showing the logged-in student's SeeMe QR code
class MyQrScreen extends ConsumerWidget {
  const MyQrScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;

    if (profile == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    void handleShare() {
      Share.share(
        'Scan my SeeMe QR code or check out my profile here: ${profile.publicProfileUrl}',
        subject: 'Connect with me on SeeMe!',
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My QR Code'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pagePaddingH),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ─── Glow & QR Card ─────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.spacing24),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.05),
                          blurRadius: 32,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SeemeAvatar(
                          name: profile.fullName,
                          imageUrl: profile.avatarUrl,
                          size: 64,
                          isVerified: profile.isVerified,
                        ),
                        const SizedBox(height: AppDimensions.spacing16),
                        Text(
                          profile.fullName,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          profile.rollNumber,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppDimensions.spacing24),

                        // QR Graphic
                        Container(
                          padding: const EdgeInsets.all(AppDimensions.spacing16),
                          decoration: BoxDecoration(
                            color: Colors.white, // Standard white background for high QR contrast
                            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                          ),
                          child: QrImageView(
                            data: profile.qrContent,
                            version: QrVersions.auto,
                            size: 200.0,
                            gapless: false,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Color(0xFF0F172A),
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spacing16),
                        Text(
                          'Let other students scan this to instantly connect.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9), duration: 400.ms, curve: Curves.easeOut),
                  const SizedBox(height: AppDimensions.spacing32),

                  // ─── Share Button ───────────────────────────────
                  SeemeButton(
                    label: 'Share Profile Link',
                    icon: Icons.share_rounded,
                    onPressed: handleShare,
                  ).animate().fadeIn(delay: 200.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
