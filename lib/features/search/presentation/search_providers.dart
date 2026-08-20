import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/search_repository.dart';
import '../../auth/providers/auth_providers.dart';
import '../../../shared/models/profile_model.dart';

/// Provider for the text search query
final searchQueryProvider = StateProvider<String>((ref) => '');


/// Provider for selected department filter
final searchDepartmentFilterProvider = StateProvider<String?>((ref) => null);

/// Provider for the list of departments (for filter dropdown)
final departmentsListProvider = FutureProvider<List<String>>((ref) async {
  // We can fetch unique departments from profiles table or define a static list.
  // A static list is faster and cleaner for standard colleges:
  return [
    'Computer Science',
    'Information Technology',
    'Electronics & Communication',
    'Electrical & Electronics',
    'Mechanical Engineering',
    'Civil Engineering',
    'Chemical Engineering',
    'Biotechnology',
    'Business Administration',
    'Science & Humanities',
  ];
});

/// Future provider that performs search and updates when filters change
final searchResultsProvider = FutureProvider<List<ProfileModel>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  final department = ref.watch(searchDepartmentFilterProvider);
  
  if (query.trim().length < 2) return const [];

  // Delay slightly to debounce consecutive keystrokes
  await Future.delayed(const Duration(milliseconds: 300));
  
  final profile = ref.watch(currentUserProfileProvider).valueOrNull;
  if (profile == null) return const [];

  final repository = ref.read(searchRepositoryProvider);
  return repository.searchStudents(
    queryText: query,
    myUserId: profile.id,
    department: department,
  );
});
