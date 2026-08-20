import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../shared/widgets/seeme_avatar.dart';
import '../../../shared/widgets/seeme_button.dart';
import '../../../shared/widgets/seeme_card.dart';
import '../../../shared/widgets/seeme_error_view.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import 'search_providers.dart';

class SearchScreen extends HookConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);
    final String? selectedDept = ref.watch(searchDepartmentFilterProvider);
    final resultsAsync = ref.watch(searchResultsProvider);

    final searchController = useTextEditingController(text: query);

    void showFiltersBottomSheet() {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => const _FiltersBottomSheet(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Students'),
        actions: [
          IconButton(
            icon: Icon(
              selectedDept != null
                  ? Icons.filter_alt_rounded
                  : Icons.filter_alt_outlined,
              color: selectedDept != null
                  ? AppColors.primary
                  : null,
            ),
            tooltip: 'Filters',
            onPressed: showFiltersBottomSheet,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ─── Search Bar ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.pagePaddingH,
                vertical: AppDimensions.spacing8,
              ),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search name, roll number, skill...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            searchController.clear();
                            ref.read(searchQueryProvider.notifier).state = '';
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                ),
                onChanged: (val) {
                  ref.read(searchQueryProvider.notifier).state = val;
                },
              ),
            ),

            // ─── Filter Chips Row ──────────────────────────────
            if (selectedDept != null)
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pagePaddingH),
                alignment: Alignment.centerLeft,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InputChip(
                        label: Text(selectedDept),
                        onDeleted: () {
                          ref.read(searchDepartmentFilterProvider.notifier).state = null;
                        },
                      ),
                    ),
                  ],
                ),
              ),

            // ─── Search Results ────────────────────────────────
            Expanded(
              child: query.trim().length < 2
                  ? const SeemeEmptyView(
                      icon: Icons.person_search_outlined,
                      title: 'Discover Students',
                      message: 'Search for other students by name, roll number, department, or skills.',
                    )
                  : resultsAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => SeemeErrorView(
                        message: 'Search failed: $err',
                        onRetry: () => ref.invalidate(searchResultsProvider),
                      ),
                      data: (results) {
                        if (results.isEmpty) {
                          return const SeemeEmptyView(
                            icon: Icons.search_off_rounded,
                            title: 'No Students Found',
                            message: 'We couldn\'t find anyone matching your search terms. Try refining filters or checking spelling.',
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
                          itemCount: results.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final profile = results[index];
                            return SeemeCard(
                              onTap: () => context.push('/u/${profile.rollNumber}'),
                              child: Row(
                                children: [
                                  SeemeAvatar(
                                    imageUrl: profile.avatarUrl,
                                    name: profile.fullName,
                                    size: 48,
                                    isVerified: profile.isVerified,
                                  ),
                                  const SizedBox(width: AppDimensions.spacing16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          profile.fullName,
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        Text(
                                          profile.rollNumber,
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: AppColors.primary,
                                              ),
                                        ),
                                        if (profile.department != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            profile.department!,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: Colors.grey,
                                                ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.1, end: 0);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FiltersBottomSheet extends HookConsumerWidget {
  const _FiltersBottomSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final departmentsAsync = ref.watch(departmentsListProvider);

    final selectedDept = ref.watch(searchDepartmentFilterProvider);

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacing24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLg)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Filter Search',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppDimensions.spacing20),


            // Department Filter Dropdown
            departmentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('Error: $err'),
              data: (depts) {
                return DropdownButtonFormField<String?>(
                  value: selectedDept,
                  decoration: InputDecoration(
                    labelText: 'Department',
                    prefixIcon: const Icon(Icons.domain_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Departments')),
                    ...depts.map((d) {
                      return DropdownMenuItem(
                        value: d,
                        child: Text(d),
                      );
                    }),
                  ],
                  onChanged: (val) {
                    ref.read(searchDepartmentFilterProvider.notifier).state = val;
                  },
                );
              },
            ),
            const SizedBox(height: AppDimensions.spacing24),

            SeemeButton(
              label: 'Apply Filters',
              onPressed: () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }
}
