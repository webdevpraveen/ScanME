import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../shared/models/enums.dart';
import '../../../shared/models/notification_model.dart';
import '../../../shared/widgets/seeme_card.dart';
import '../../../shared/widgets/seeme_error_view.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import 'notification_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(userNotificationsProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unreadCount > 0)
            TextButton.icon(
              icon: const Icon(Icons.done_all_rounded, size: 18),
              label: const Text('Mark all read', style: TextStyle(fontSize: 12)),
              onPressed: () {
                ref.read(userNotificationsProvider.notifier).markAllAsRead();
              },
            ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(userNotificationsProvider),
          child: notificationsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => SeemeErrorView(
              message: 'Failed to load notifications: $err',
              onRetry: () => ref.invalidate(userNotificationsProvider),
            ),
            data: (list) {
              if (list.isEmpty) {
                return const SeemeEmptyView(
                  icon: Icons.notifications_none_rounded,
                  title: 'No notifications',
                  message: 'When you receive alerts, verifications, or profile views, they will appear here.',
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
                itemCount: list.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final notification = list[index];
                  return _NotificationItem(notification: notification)
                      .animate()
                      .fadeIn(delay: (index * 50).ms)
                      .slideY(begin: 0.1, end: 0);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NotificationItem extends ConsumerWidget {
  const _NotificationItem({required this.notification});

  final NotificationModel notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Choose icon and color based on notification type
    final (icon, iconColor) = switch (notification.type) {
      NotificationType.approval => (Icons.verified_rounded, Colors.green),
      NotificationType.rejection => (Icons.gpp_bad_rounded, AppColors.error),
      NotificationType.profileView => (Icons.visibility_rounded, AppColors.accent),
      NotificationType.system => (Icons.info_outline_rounded, AppColors.primary),
      NotificationType.announcement => (Icons.campaign_rounded, Colors.orange),
    };

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        ref.read(userNotificationsProvider.notifier).markAsRead(notification.id);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
        child: const Icon(Icons.done_rounded, color: Colors.green),
      ),
      child: SeemeCard(
        onTap: () {
          if (!notification.isRead) {
            ref.read(userNotificationsProvider.notifier).markAsRead(notification.id);
          }
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Icon Indicator
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: AppDimensions.spacing16),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
                              ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          height: 1.3,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    timeago.format(notification.createdAt),
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
