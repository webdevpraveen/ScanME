import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/supabase_client.dart';
import '../../../core/utils/logger.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/profile_model.dart';
import '../../profile/data/profile_repository.dart';

/// Stream provider for raw session changes
final supabaseSessionProvider = StreamProvider<Session?>((ref) {
  final authClient = ref.read(supabaseAuthProvider);
  return authClient.onAuthStateChange.map((event) => event.session);
});

/// Notifier to manage the currently logged-in user's profile.
/// Automatically updates when the auth session changes, and provides methods to refresh/reload.
class CurrentUserProfileNotifier extends AsyncNotifier<ProfileModel?> {
  @override
  FutureOr<ProfileModel?> build() async {
    final session = ref.watch(supabaseSessionProvider).valueOrNull;
    if (session == null) {
      return null;
    }

    return _fetchProfile(session.user.id);
  }

  Future<ProfileModel?> _fetchProfile(String userId) async {
    try {
      final repository = ref.read(profileRepositoryProvider);
      final profile = await repository.getProfile(userId);
      return profile;
    } catch (e, stack) {
      AppLogger.error('Failed to fetch user profile in notifier', e, stack, 'CurrentUserProfileNotifier');
      return null;
    }
  }

  /// Manually reload the user's profile from the database
  Future<void> refresh() async {
    final session = ref.read(supabaseSessionProvider).valueOrNull;
    if (session == null) {
      state = const AsyncValue.data(null);
      return;
    }

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchProfile(session.user.id));
  }

  /// Update the current profile state locally (after successful repository updates)
  void updateState(ProfileModel profile) {
    state = AsyncValue.data(profile);
  }
}

/// Provider for the currently logged-in user's profile
final currentUserProfileProvider =
    AsyncNotifierProvider<CurrentUserProfileNotifier, ProfileModel?>(
        CurrentUserProfileNotifier.new);

/// Provider to get the current verification status for the logged-in student.
/// Fetches the latest entry from the student_verifications table.
final latestVerificationProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final profile = ref.watch(currentUserProfileProvider).valueOrNull;
  if (profile == null) return null;

  final client = ref.read(supabaseClientProvider);
  
  try {
    final response = await client
        .from('student_verifications')
        .select('*')
        .eq('user_id', profile.id)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return response;
  } catch (e, stack) {
    AppLogger.error('Failed to fetch latest verification status', e, stack, 'VerificationStatusProvider');
    return null;
  }
});

/// Derived provider checking if user is fully verified
final isVerifiedProvider = Provider<bool>((ref) {
  final profile = ref.watch(currentUserProfileProvider).valueOrNull;
  return profile?.isVerified ?? false;
});

/// Derived provider checking the user's role
final userRoleProvider = Provider<UserRole>((ref) {
  final profile = ref.watch(currentUserProfileProvider).valueOrNull;
  return profile?.role ?? UserRole.student;
});
