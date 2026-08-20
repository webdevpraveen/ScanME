import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_animate/flutter_animate.dart';
import '../../../shared/widgets/seeme_avatar.dart';
import '../../../shared/widgets/seeme_card.dart';
import '../../../shared/widgets/seeme_error_view.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import 'history_providers.dart';

/// Screen listing all past scanned students with option to delete or clear all
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(scanHistoryProvider);

    Future<void> handleClearAll() async {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Clear Scan History?'),
          content: const Text('This will permanently delete all records of students you have scanned.'),
          actions: [
            TextButton(
              onPressed: () => context.pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => context.pop(true),
              child: const Text('Clear All', style: TextStyle(color: AppColors.error)),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await ref.read(scanHistoryProvider.notifier).clearAll();
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear All',
            onPressed: handleClearAll,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ─── Retention Policy Notice ─────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.pagePaddingH,
                vertical: 8,
              ),
              color: AppColors.info.withValues(alpha: 0.08),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 14, color: AppColors.info),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Scan records are automatically removed after 180 days.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.info),
                    ),
                  ),
                ],
              ),
            ),

            // ─── History List ────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => ref.invalidate(scanHistoryProvider),
                child: historyAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => SeemeErrorView(
                    message: 'Failed to load scan history: $err',
                    onRetry: () => ref.invalidate(scanHistoryProvider),
                  ),
                  data: (history) {
                    if (history.isEmpty) {
                      return const SeemeEmptyView(
                        icon: Icons.history_rounded,
                        title: 'No Scans Yet',
                        message: 'Students you scan will appear here. Start scanning to grow your network.',
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
                      itemCount: history.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final entry = history[index];
                        final profileJson = entry['profiles'] as Map<String, dynamic>?;

                        if (profileJson == null) {
                          return const SizedBox.shrink(); // Scanned profile was purged
                        }

                        // Parse profile data
                        final rollNumber = profileJson['roll_number'] as String;
                        final fullName = profileJson['full_name'] as String;
                        final avatarUrl = profileJson['avatar_url'] as String?;
                        final isVerified = profileJson['is_verified'] as bool? ?? false;
                        final department = profileJson['department'] as String?;
                        final scannedAt = DateTime.parse(entry['created_at'] as String);

                        return Dismissible(
                          key: ValueKey(entry['id']),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            color: AppColors.error,
                            child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                          ),
                          onDismissed: (_) {
                            ref.read(scanHistoryProvider.notifier).deleteEntry(entry['id'] as String);
                          },
                          child: SeemeCard(
                            onTap: () => context.push('/u/$rollNumber'),
                            child: Row(
                              children: [
                                SeemeAvatar(
                                  name: fullName,
                                  imageUrl: avatarUrl,
                                  size: 48,
                                  isVerified: isVerified,
                                ),
                                const SizedBox(width: AppDimensions.spacing16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        fullName,
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      Text(
                                        rollNumber,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: AppColors.primary,
                                            ),
                                      ),
                                      if (department != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          department,
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
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 14,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      timeago.format(scannedAt),
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            fontSize: 10,
                                            color: Colors.grey,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(delay: (index * 40).ms).slideY(begin: 0.1, end: 0);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
