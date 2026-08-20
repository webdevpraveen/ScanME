import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/errors/error_handler.dart';
import '../../../shared/widgets/seeme_avatar.dart';
import '../../../shared/widgets/seeme_button.dart';
import '../../../shared/widgets/seeme_card.dart';
import '../../../shared/widgets/seeme_text_field.dart';
import '../../../shared/widgets/seeme_error_view.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/admin_repository.dart';
import 'admin_providers.dart';

class AdminDashboardScreen extends HookConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Auth role guard check
    final userRole = ref.watch(userRoleProvider);
    if (!userRole.isAdmin) {
      return const Scaffold(
        body: Center(child: Text('Access Denied: Admin permissions required.')),
      );
    }

    final activeTab = useState<int>(0);

    final tabs = [
      'Overview',
      'Users',
      'App Config',
      'Features',
      'Audit Logs',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(adminMetricsProvider);
              ref.invalidate(adminUsersProvider);
              ref.invalidate(adminConfigsProvider);
              ref.invalidate(adminFeatureFlagsProvider);
              ref.invalidate(adminAuditLogsProvider);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ─── Scrollable Tab Pills ────────────────────────────────
            Container(
              height: 54,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pagePaddingH),
                itemCount: tabs.length,
                itemBuilder: (context, index) {
                  final isSelected = activeTab.value == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(tabs[index]),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white70 : Colors.black87),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (_) => activeTab.value = index,
                    ),
                  );
                },
              ),
            ),
            
            // ─── Main Content Views ──────────────────────────────────
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: switch (activeTab.value) {
                  0 => const _OverviewTab(),
                  1 => const _UsersTab(),
                  2 => const _ConfigTab(),
                  3 => const _FeaturesTab(),
                  4 => const _AuditTab(),
                  _ => const SizedBox.shrink(),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. OVERVIEW TAB
// ─────────────────────────────────────────────────────────────────────────────
class _OverviewTab extends ConsumerWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(adminMetricsProvider);

    return metricsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => SeemeErrorView(
        message: 'Failed to load dashboard metrics: $err',
        onRetry: () => ref.invalidate(adminMetricsProvider),
      ),
      data: (metrics) {
        final totalUsers = metrics['totalUsers'] ?? 0;
        final verifiedUsers = metrics['verifiedUsers'] ?? 0;
        final pendingReviews = metrics['pendingReviews'] ?? 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'System Performance & Health',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              // Grid of Stats Cards
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _MetricCard(
                    title: 'Total Users',
                    value: '$totalUsers',
                    icon: Icons.people_outline_rounded,
                    color: AppColors.primary,
                  ),
                  _MetricCard(
                    title: 'Verified Students',
                    value: '$verifiedUsers',
                    icon: Icons.verified_user_outlined,
                    color: AppColors.accent,
                  ),
                  _MetricCard(
                    title: 'Pending Reviews',
                    value: '$pendingReviews',
                    icon: Icons.pending_actions_rounded,
                    color: AppColors.warning,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              SeemeCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.shield_outlined, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text(
                          'Moderator Portal Link',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'As an Administrator, you can also view student verifications, review submitted college ID cards, and handle pending registrations directly in the Moderator screen.',
                      style: TextStyle(fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    SeemeButton(
                      label: 'Go to Moderator Portal',
                      onPressed: () => context.push('/moderator'),
                    ),
                  ],
                ),
              ),
            ],
          ).animate().fadeIn(duration: 300.ms),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SeemeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. USERS TAB
// ─────────────────────────────────────────────────────────────────────────────
class _UsersTab extends HookConsumerWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchController = useTextEditingController(text: ref.read(userSearchQueryProvider));
    final usersAsync = ref.watch(adminUsersProvider);
    final activeRole = ref.watch(userRoleFilterProvider);

    return Column(
      children: [
        // Search & Filters Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pagePaddingH, vertical: 8),
          child: Column(
            children: [
              SeemeTextField(
                controller: searchController,
                hint: 'Search by name, roll number, or email...',
                prefixIcon: Icons.search_rounded,
                onChanged: (val) => ref.read(userSearchQueryProvider.notifier).state = val,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Filter by Role:', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 8),
                  Wrap(
                    spacing: 6,
                    children: ['all', 'student', 'moderator', 'admin'].map((role) {
                      final isSelected = activeRole == role;
                      return ChoiceChip(
                        label: Text(role.toUpperCase(), style: const TextStyle(fontSize: 10)),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (_) => ref.read(userRoleFilterProvider.notifier).state = role,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ],
          ),
        ),

        // List of Users
        Expanded(
          child: usersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error loading users: $err')),
            data: (users) {
              if (users.isEmpty) {
                return const SeemeEmptyView(
                  icon: Icons.person_search_rounded,
                  title: 'No users found',
                  message: 'Try modifying your search text or role filters.',
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
                itemCount: users.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final user = users[index];
                  final fullName = user['full_name'] as String? ?? 'N/A';
                  final rollNumber = user['roll_number'] as String? ?? 'N/A';
                  final email = user['email'] as String? ?? 'N/A';
                  final role = user['role'] as String? ?? 'student';
                  final accountStatus = user['account_status'] as String? ?? 'active';
                  final isVerified = user['is_verified'] as bool? ?? false;

                  return SeemeCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            SeemeAvatar(
                              name: fullName,
                              imageUrl: user['avatar_url'] as String?,
                              size: 40,
                              isVerified: isVerified,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fullName,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '$rollNumber • $email',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: role == 'admin'
                                    ? Colors.red.withValues(alpha: 0.1)
                                    : (role == 'moderator'
                                        ? Colors.blue.withValues(alpha: 0.1)
                                        : Colors.green.withValues(alpha: 0.1)),
                                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                              ),
                              child: Text(
                                role.toUpperCase(),
                                style: TextStyle(
                                  color: role == 'admin'
                                      ? Colors.red
                                      : (role == 'moderator' ? Colors.blue : Colors.green),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              accountStatus == 'active' ? 'Status: Active' : 'Status: Suspended',
                              style: TextStyle(
                                fontSize: 12,
                                color: accountStatus == 'active' ? Colors.green : Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Wrap(
                              spacing: 8,
                              children: [
                                TextButton(
                                  onPressed: () => _showRoleDialog(context, ref, user['id'] as String, role),
                                  child: const Text('Change Role', style: TextStyle(fontSize: 12)),
                                ),
                                TextButton(
                                  onPressed: () => _toggleSuspend(context, ref, user['id'] as String, accountStatus),
                                  child: Text(
                                    accountStatus == 'active' ? 'Suspend' : 'Activate',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: accountStatus == 'active' ? Colors.red : Colors.green,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showRoleDialog(BuildContext context, WidgetRef ref, String userId, String currentRole) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change User Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['student', 'moderator', 'admin'].map((role) {
            return RadioListTile<String>(
              title: Text(role.toUpperCase()),
              value: role,
              groupValue: currentRole,
              onChanged: (val) async {
                if (val != null) {
                  context.pop();
                  try {
                    await ref.read(adminRepositoryProvider).updateUserRole(userId, val);
                    ref.invalidate(adminUsersProvider);
                    ref.invalidate(adminMetricsProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('User role updated to $val')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) ErrorHandler.showSnackBar(context, e);
                  }
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _toggleSuspend(BuildContext context, WidgetRef ref, String userId, String currentStatus) async {
    final newStatus = currentStatus == 'active' ? 'soft_deleted' : 'active';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(currentStatus == 'active' ? 'Suspend Account?' : 'Activate Account?'),
        content: Text(
          currentStatus == 'active'
              ? 'This will soft-delete the user profile, preventing them from logging in and accessing their card. It can be recovered.'
              : 'This will restore the user profile to active status.',
        ),
        actions: [
          TextButton(onPressed: () => context.pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => context.pop(true),
            child: Text(
              currentStatus == 'active' ? 'Suspend' : 'Activate',
              style: TextStyle(color: currentStatus == 'active' ? Colors.red : Colors.green),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(adminRepositoryProvider).updateAccountStatus(userId, newStatus);
        ref.invalidate(adminUsersProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Account status updated successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) ErrorHandler.showSnackBar(context, e);
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. CONFIG TAB
// ─────────────────────────────────────────────────────────────────────────────
class _ConfigTab extends ConsumerWidget {
  const _ConfigTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configsAsync = ref.watch(adminConfigsProvider);

    return configsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error loading config: $err')),
      data: (configs) {
        if (configs.isEmpty) {
          return const SeemeEmptyView(
            icon: Icons.settings_applications_rounded,
            title: 'No App Configuration Found',
            message: 'App configs table seems empty.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
          itemCount: configs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final config = configs[index];
            final key = config['key'] as String;
            final val = config['value'];
            final desc = config['description'] as String? ?? 'N/A';

            return SeemeCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        key,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, color: AppColors.primary, size: 20),
                        onPressed: () => _editConfigValue(context, ref, key, val, desc),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Value: ${val.toString()}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.accent),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _editConfigValue(BuildContext context, WidgetRef ref, String key, dynamic currentVal, String description) {
    showDialog(
      context: context,
      builder: (context) => _ConfigEditDialog(configKey: key, currentValue: currentVal, description: description),
    );
  }
}

class _ConfigEditDialog extends HookConsumerWidget {
  const _ConfigEditDialog({
    required this.configKey,
    required this.currentValue,
    required this.description,
  });

  final String configKey;
  final dynamic currentValue;
  final String description;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textController = useTextEditingController(text: currentValue?.toString() ?? '');
    final switchValue = useState<bool>(currentValue is bool ? currentValue as bool : false);

    Future<void> handleSave() async {
      try {
        dynamic parsedVal;
        if (currentValue is bool) {
          parsedVal = switchValue.value;
        } else if (currentValue is num) {
          parsedVal = num.tryParse(textController.text.trim()) ?? currentValue;
        } else {
          parsedVal = textController.text.trim();
        }

        await ref.read(adminConfigsProvider.notifier).updateConfig(configKey, parsedVal);
        
        if (context.mounted) {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Config "$configKey" updated')),
          );
        }
      } catch (e) {
        if (context.mounted) ErrorHandler.showSnackBar(context, e);
      }
    }

    return AlertDialog(
      title: Text('Edit Configuration'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(configKey, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(description, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 16),
          if (currentValue is bool)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Enable / True'),
                Switch(value: switchValue.value, onChanged: (val) => switchValue.value = val),
              ],
            )
          else
            SeemeTextField(
              controller: textController,
              label: 'Config Value',
              keyboardType: currentValue is num ? TextInputType.number : TextInputType.text,
            ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
        TextButton(onPressed: handleSave, child: const Text('Save')),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. FEATURES TAB
// ─────────────────────────────────────────────────────────────────────────────
class _FeaturesTab extends ConsumerWidget {
  const _FeaturesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flagsAsync = ref.watch(adminFeatureFlagsProvider);

    return flagsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error loading flags: $err')),
      data: (flags) {
        if (flags.isEmpty) {
          return const SeemeEmptyView(
            icon: Icons.flag_outlined,
            title: 'No Feature Flags',
            message: 'Features flags table is empty.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
          itemCount: flags.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final flag = flags[index];
            final name = flag['name'] as String;
            final isEnabled = flag['is_enabled'] as bool? ?? false;
            final desc = flag['description'] as String? ?? 'N/A';

            return SeemeCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          desc,
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: isEnabled,
                    activeColor: AppColors.accent,
                    onChanged: (val) async {
                      try {
                        await ref.read(adminFeatureFlagsProvider.notifier).toggleFlag(name, val);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Feature flag "$name" ${val ? 'enabled' : 'disabled'}')),
                        );
                      } catch (e) {
                        ErrorHandler.showSnackBar(context, e);
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 6. AUDIT LOGS TAB
// ─────────────────────────────────────────────────────────────────────────────
class _AuditTab extends HookConsumerWidget {
  const _AuditTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchController = useTextEditingController(text: ref.read(auditLogsSearchQueryProvider));
    final logsAsync = ref.watch(adminAuditLogsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pagePaddingH, vertical: 8),
          child: SeemeTextField(
            controller: searchController,
            hint: 'Search audit logs (action, targets)...',
            prefixIcon: Icons.search_rounded,
            onChanged: (val) => ref.read(auditLogsSearchQueryProvider.notifier).state = val,
          ),
        ),
        Expanded(
          child: logsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error loading audit logs: $err')),
            data: (logs) {
              if (logs.isEmpty) {
                return const SeemeEmptyView(
                  icon: Icons.history_rounded,
                  title: 'No Audit Logs Found',
                  message: 'No events matching search text were found.',
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
                itemCount: logs.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final log = logs[index];
                  final action = log['action'] as String? ?? 'action';
                  final targetType = log['target_type'] as String? ?? 'target';
                  final timestampStr = log['created_at'] as String;
                  final timeStr = DateTime.parse(timestampStr).toLocal().toString().split('.')[0];
                  final metadata = log['new_value']?.toString() ?? log['old_value']?.toString() ?? 'N/A';

                  return SeemeCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              action.toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary),
                            ),
                            Text(
                              timeStr,
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Target: $targetType',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Details: $metadata',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
