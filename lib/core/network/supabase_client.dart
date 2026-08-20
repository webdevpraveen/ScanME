import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Singleton Supabase client provider
/// Access via ref.read(supabaseClientProvider)
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Supabase Auth convenience provider
final supabaseAuthProvider = Provider<GoTrueClient>((ref) {
  return ref.read(supabaseClientProvider).auth;
});

/// Current authenticated user provider
final currentUserProvider = Provider<User?>((ref) {
  return ref.read(supabaseAuthProvider).currentUser;
});

/// Current user ID provider — throws if not authenticated
final currentUserIdProvider = Provider<String>((ref) {
  final user = ref.read(currentUserProvider);
  if (user == null) throw StateError('User not authenticated');
  return user.id;
});

/// Auth state changes stream provider
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return ref.read(supabaseAuthProvider).onAuthStateChange;
});
