import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/errors/error_handler.dart';
import '../../../shared/services/app_config_service.dart';
import '../../../shared/widgets/seeme_button.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../auth/providers/auth_providers.dart';
import '../../qr_resolver/qr_resolver_service.dart';
import '../data/scanner_repository.dart';

class ScannerScreen extends HookConsumerWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cameraPermissionStatus = useState<PermissionStatus>(PermissionStatus.denied);
    final isPermissionLoading = useState(true);
    final scannerController = useMemoized(() => MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    ));
    final isProcessing = useState(false);
    final isTorchOn = useState(false);

    // Check camera permission on mount
    useEffect(() {
      Future<void> checkPermission() async {
        final status = await Permission.camera.status;
        cameraPermissionStatus.value = status;
        isPermissionLoading.value = false;
      }
      checkPermission();
      return () => scannerController.dispose();
    }, []);

    Future<void> requestPermission() async {
      final status = await Permission.camera.request();
      cameraPermissionStatus.value = status;
    }

    Future<void> handleQrDetected(String rawValue) async {
      if (isProcessing.value) return;
      isProcessing.value = true;

      try {
        final myProfile = ref.read(currentUserProfileProvider).valueOrNull;
        if (myProfile == null) throw Exception('User session not found');

        // Check scan rate limits first
        final config = ref.read(appConfigServiceProvider);
        final maxScans = config.maxScansPerHour;
        
        final withinLimit = await ref.read(scannerRepositoryProvider).checkScanRateLimit(myProfile.id, maxScans);
        if (!withinLimit) {
          throw Exception('Hourly scan limit exceeded ($maxScans scans/hr). Please try again later.');
        }

        // 1. Resolve QR code using registry
        final registry = QrResolverRegistry();
        final resolvedIdentity = await registry.resolve(rawValue);
        
        if (resolvedIdentity == null) {
          throw Exception('Invalid QR code scanned');
        }

        // 2. Lookup database profile and log in scan history
        final profile = await ref.read(scannerRepositoryProvider).resolveIdentity(
              scannerId: myProfile.id,
              identity: resolvedIdentity,
            );

        if (profile == null) {
          throw Exception('No student profile matches this QR code');
        }

        // 3. Navigate to scan result screen
        if (context.mounted) {
          context.push('/scan/result', extra: profile);
        }
      } catch (e) {
        if (context.mounted) {
          ErrorHandler.showSnackBar(context, e);
          // Resume scanner after a short delay
          Future.delayed(const Duration(seconds: 2), () {
            isProcessing.value = false;
          });
        }
      }
    }

    if (isPermissionLoading.value) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (cameraPermissionStatus.value.isDenied || cameraPermissionStatus.value.isPermanentlyDenied) {
      return Scaffold(
        appBar: AppBar(title: const Text('Scan QR')),
        body: Padding(
          padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.camera_alt_outlined, size: 80, color: Colors.grey),
              const SizedBox(height: AppDimensions.spacing24),
              Text(
                'Camera Access Required',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.spacing12),
              Text(
                'SeeMe requires camera access to scan other students\' QR codes.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.spacing32),
              SeemeButton(
                label: 'Grant Permission',
                icon: Icons.camera_rounded,
                onPressed: requestPermission,
              ),
              if (cameraPermissionStatus.value.isPermanentlyDenied) ...[
                const SizedBox(height: AppDimensions.spacing12),
                SeemeButton(
                  label: 'Open App Settings',
                  isOutlined: true,
                  onPressed: openAppSettings,
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(isTorchOn.value ? Icons.flash_on_rounded : Icons.flash_off_rounded),
            onPressed: () {
              scannerController.toggleTorch();
              isTorchOn.value = !isTorchOn.value;
            },
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios_rounded),
            onPressed: () => scannerController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ─── Camera Preview ────────────────────────────────
          MobileScanner(
            controller: scannerController,
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  handleQrDetected(barcode.rawValue!);
                  break;
                }
              }
            },
          ),

          // ─── Scanning Framing Overlay ──────────────────────
          Center(
            child: Container(
              width: AppDimensions.qrScannerSize,
              height: AppDimensions.qrScannerSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                border: Border.all(
                  color: isProcessing.value ? AppColors.success : AppColors.primary,
                  width: 3,
                ),
              ),
              child: Stack(
                children: [
                  // Animating scan line
                  if (!isProcessing.value)
                    Container(
                      width: double.infinity,
                      height: 4,
                      color: AppColors.primary,
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .slideY(
                          begin: 0,
                          end: AppDimensions.qrScannerSize / 4,
                          duration: 2000.ms,
                          curve: Curves.easeInOut,
                        ),
                ],
              ),
            ),
          ),

          // Background overlay surrounding viewfinder
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.6),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  color: Colors.black,
                ),
                Center(
                  child: Container(
                    width: AppDimensions.qrScannerSize,
                    height: AppDimensions.qrScannerSize,
                    decoration: BoxDecoration(
                      color: Colors.red, // Destination shape
                      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Loading cover when resolving
          if (isProcessing.value)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: AppDimensions.spacing16),
                    Text(
                      'Resolving student...',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),

          // ─── Search Button ─────────────────────────────────
          Positioned(
            bottom: AppDimensions.spacing40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SeemeButton(
                  label: 'Search Instead',
                  icon: Icons.search_rounded,
                  isOutlined: true,
                  onPressed: () => context.push('/search'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
