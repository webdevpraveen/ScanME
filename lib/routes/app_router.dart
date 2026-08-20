import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/utils/logger.dart';
import '../shared/models/enums.dart';

// Feature screens
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/providers/auth_providers.dart';
import '../features/registration/presentation/registration_screen.dart';
import '../features/registration/presentation/verification_pending_screen.dart';
import '../features/registration/presentation/verification_rejected_screen.dart';
import '../features/moderator/presentation/moderator_dashboard_screen.dart';
import '../features/admin/presentation/admin_dashboard_screen.dart';
import '../features/notifications/presentation/notifications_screen.dart';
import '../features/settings/presentation/account_recovery_screen.dart';
import '../features/settings/presentation/account_deletion_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/scanner/presentation/scanner_screen.dart';
import '../features/search/presentation/search_screen.dart';
import '../features/history/presentation/history_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/profile/presentation/edit_profile_screen.dart';
import '../features/profile/presentation/public_profile_screen.dart';
import '../features/profile/presentation/manage_links_screen.dart';
import '../features/profile/presentation/my_qr_screen.dart';
import '../features/scanner/presentation/scan_result_screen.dart';
import '../shared/models/profile_model.dart';
import '../shared/widgets/seeme_scaffold_with_nav.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  // Watch session changes stream
  final sessionAsync = ref.watch(supabaseSessionProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn = sessionAsync.valueOrNull != null;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password';
      final isPublicProfile = state.matchedLocation.startsWith('/u/');

      // Allow public profile routes without auth
      if (isPublicProfile) return null;

      // Not logged in → redirect to login (unless already on auth route)
      if (!isLoggedIn && !isAuthRoute) {
        AppLogger.navigation('Redirect: not authenticated → /login');
        return '/login';
      }

      // Logged in but on auth route → redirect to home (or verification/recovery screens)
      if (isLoggedIn) {
        final profileAsync = ref.watch(currentUserProfileProvider);
        if (profileAsync.isLoading) {
          return null; // Stay on current page until profile is loaded
        }

        final profile = profileAsync.valueOrNull;
        if (profile == null) {
          // Profile is null: they logged in but haven't created a profile.
          // Redirect to register step 2/3.
          if (state.matchedLocation != '/register') {
            AppLogger.navigation('Redirect: logged in but profile is null → /register');
            return '/register';
          }
          return null;
        }

        // Account soft-deleted guard
        if (profile.accountStatus == AccountStatus.softDeleted) {
          if (state.matchedLocation != '/account-recovery') {
            AppLogger.navigation('Redirect: soft-deleted → /account-recovery');
            return '/account-recovery';
          }
          return null;
        }

        // Verification status guard
        if (!profile.isVerified) {
          final verificationAsync = ref.watch(latestVerificationProvider);
          if (verificationAsync.isLoading) {
            return null; // Wait for verification status to load
          }

          final verification = verificationAsync.valueOrNull;
          if (verification == null) {
            // No verification request found, redirect to /register to complete step 2/3
            if (state.matchedLocation != '/register') {
              AppLogger.navigation('Redirect: unverified, no verification request → /register');
              return '/register';
            }
            return null;
          }

          final status = verification['status'] as String?;
          if (status == 'rejected') {
            if (state.matchedLocation != '/verification-rejected') {
              AppLogger.navigation('Redirect: verification rejected → /verification-rejected');
              return '/verification-rejected';
            }
            return null;
          } else {
            // pending or resubmitted
            if (state.matchedLocation != '/verification-pending') {
              AppLogger.navigation('Redirect: verification pending → /verification-pending');
              return '/verification-pending';
            }
            return null;
          }
        }

        // User is verified!
        // Prevent them from going to register or verification/recovery screens
        final isRestrictedRoute = isAuthRoute ||
            state.matchedLocation == '/verification-pending' ||
            state.matchedLocation == '/verification-rejected' ||
            state.matchedLocation == '/account-recovery';

        if (isRestrictedRoute) {
          AppLogger.navigation('Redirect: verified user on restricted route → /home');
          return '/home';
        }
      }

      return null;
    },
    routes: [
      // ─── Auth Routes ─────────────────────────────────────
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegistrationScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/verification-pending',
        name: 'verification-pending',
        builder: (context, state) => const VerificationPendingScreen(),
      ),
      GoRoute(
        path: '/verification-rejected',
        name: 'verification-rejected',
        builder: (context, state) => const VerificationRejectedScreen(),
      ),
      GoRoute(
        path: '/account-recovery',
        name: 'account-recovery',
        builder: (context, state) => const AccountRecoveryScreen(),
      ),
      GoRoute(
        path: '/account-delete',
        name: 'account-delete',
        builder: (context, state) => const AccountDeletionScreen(),
      ),
      GoRoute(
        path: '/moderator',
        name: 'moderator',
        builder: (context, state) => const ModeratorDashboardScreen(),
      ),
      GoRoute(
        path: '/admin',
        name: 'admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/scan/result',
        name: 'scan-result',
        builder: (context, state) {
          final profile = state.extra as ProfileModel;
          return ScanResultScreen(profile: profile);
        },
      ),

      // ─── Main App Shell (Bottom Navigation) ──────────────
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return SeemeScaffoldWithNav(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/scan',
            name: 'scan',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ScannerScreen(),
            ),
          ),
          GoRoute(
            path: '/search',
            name: 'search',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SearchScreen(),
            ),
          ),
          GoRoute(
            path: '/history',
            name: 'history',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HistoryScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
        ],
      ),

      // ─── Profile Routes ──────────────────────────────────
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        name: 'edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/profile/links',
        name: 'manage-links',
        builder: (context, state) => const ManageLinksScreen(),
      ),
      GoRoute(
        path: '/profile/qr',
        name: 'my-qr',
        builder: (context, state) => const MyQrScreen(),
      ),

      // ─── Public Profile (Deep Link) ──────────────────────
      GoRoute(
        path: '/u/:rollNumber',
        name: 'public-profile',
        builder: (context, state) {
          final rollNumber = state.pathParameters['rollNumber']!;
          return PublicProfileScreen(rollNumber: rollNumber);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.matchedLocation,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});

