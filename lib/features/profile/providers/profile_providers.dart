import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/profile_repository.dart';
import '../data/user_links_repository.dart';
import '../../auth/providers/auth_providers.dart';
import '../../../shared/models/profile_model.dart';
import '../../../shared/models/user_link_model.dart';

/// Future provider to fetch a public profile by rollNumber
final publicProfileProvider = FutureProvider.family<ProfileModel?, String>((ref, rollNumber) async {
  final repository = ref.read(profileRepositoryProvider);
  return repository.getPublicProfile(rollNumber);
});

/// Future provider to fetch social/contact links for a specific user ID
final userLinksProvider = FutureProvider.family<List<UserLinkModel>, String>((ref, userId) async {
  final repository = ref.read(userLinksRepositoryProvider);
  return repository.getUserLinks(userId);
});

/// Notifier to manage own social links list state (supporting drag reorder, edit, delete)
class MyLinksNotifier extends AutoDisposeAsyncNotifier<List<UserLinkModel>> {
  @override
  Future<List<UserLinkModel>> build() async {
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    if (profile == null) return const [];
    
    return ref.read(userLinksRepositoryProvider).getUserLinks(profile.id);
  }

  /// Create a new link
  Future<void> addLink(UserLinkModel link) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(userLinksRepositoryProvider).createLink(link);
      return ref.read(userLinksRepositoryProvider).getUserLinks(link.userId);
    });
  }

  /// Update an existing link
  Future<void> editLink(UserLinkModel link) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(userLinksRepositoryProvider).updateLink(link);
      return ref.read(userLinksRepositoryProvider).getUserLinks(link.userId);
    });
  }

  /// Delete a link
  Future<void> deleteLink(String linkId, String userId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(userLinksRepositoryProvider).deleteLink(linkId);
      return ref.read(userLinksRepositoryProvider).getUserLinks(userId);
    });
  }

  /// Update sort orders
  Future<void> reorder(List<UserLinkModel> reorderedList) async {
    state = AsyncValue.data(reorderedList);
    try {
      final updatedList = reorderedList.asMap().entries.map((entry) {
        return entry.value.copyWith(sortOrder: entry.key);
      }).toList();

      await ref.read(userLinksRepositoryProvider).updateLinksOrder(updatedList);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

/// Provider for managing own links list
final myLinksProvider = AutoDisposeAsyncNotifierProvider<MyLinksNotifier, List<UserLinkModel>>(
  MyLinksNotifier.new,
);
