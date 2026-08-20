import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/logger.dart';

/// Authentication repository — handles all auth operations via Supabase
class AuthRepository {
  AuthRepository(this._auth);

  final GoTrueClient _auth;

  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    AppLogger.auth('Sign in attempt: ${email.split('@').first}***');
    final response = await _auth.signInWithPassword(
      email: email,
      password: password,
    );
    AppLogger.auth('Sign in successful');
    return response;
  }

  /// Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? metadata,
  }) async {
    AppLogger.auth('Sign up attempt: ${email.split('@').first}***');
    final response = await _auth.signUp(
      email: email,
      password: password,
      data: metadata,
    );
    AppLogger.auth('Sign up successful');
    return response;
  }

  /// Sign out
  Future<void> signOut() async {
    AppLogger.auth('Sign out');
    await _auth.signOut();
  }

  /// Send password reset email
  Future<void> resetPassword({required String email}) async {
    AppLogger.auth('Password reset for: ${email.split('@').first}***');
    await _auth.resetPasswordForEmail(email);
  }

  /// Get current session
  Session? get currentSession => _auth.currentSession;

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.id;

  /// Auth state stream
  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  /// Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;

  /// Update user password
  Future<void> updatePassword(String newPassword) async {
    await _auth.updateUser(UserAttributes(password: newPassword));
  }

  /// Delete user account (requires admin function or edge function)
  /// This is called as part of the soft-delete flow
  Future<void> deleteAccount() async {
    AppLogger.auth('Account deletion requested');
    // Account deletion is handled via database soft-delete function
    // The actual auth.users deletion happens via purge_expired_accounts()
  }
}

/// Provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(Supabase.instance.client.auth);
});
