import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/validators/input_validators.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/user_link_model.dart';
import '../../../shared/widgets/seeme_button.dart';
import '../../../shared/widgets/seeme_text_field.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/profile_providers.dart';

class ManageLinksScreen extends HookConsumerWidget {
  const ManageLinksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final linksAsync = ref.watch(myLinksProvider);
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;

    Future<void> showLinkDialog({UserLinkModel? existingLink}) async {
      if (profile == null) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _LinkBottomSheet(
          userId: profile.id,
          existingLink: existingLink,
          onSave: (link) async {
            try {
              if (existingLink == null) {
                await ref.read(myLinksProvider.notifier).addLink(link);
              } else {
                await ref.read(myLinksProvider.notifier).editLink(link);
              }
              if (context.mounted) context.pop();
            } catch (e) {
              if (context.mounted) ErrorHandler.showSnackBar(context, e);
            }
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Links'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Link',
            onPressed: () => showLinkDialog(),
          ),
        ],
      ),
      body: SafeArea(
        child: linksAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (links) {
            if (links.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.spacing32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.link_off_rounded, size: 64, color: Colors.grey),
                      const SizedBox(height: AppDimensions.spacing16),
                      Text(
                        'No Links Added Yet',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add social profiles, phone numbers, or email so students can connect with you.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppDimensions.spacing24),
                      SeemeButton(
                        label: 'Add First Link',
                        icon: Icons.add_rounded,
                        onPressed: () => showLinkDialog(),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppDimensions.spacing16),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Drag handles on the right to reorder links. Swipe or tap edit to modify.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    itemCount: links.length,
                    onReorder: (oldIndex, newIndex) {
                      var index = newIndex;
                      if (oldIndex < index) {
                        index -= 1;
                      }
                      final item = links.removeAt(oldIndex);
                      links.insert(index, item);
                      ref.read(myLinksProvider.notifier).reorder(links);
                    },
                    itemBuilder: (context, index) {
                      final link = links[index];
                      return Dismissible(
                        key: ValueKey(link.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          color: AppColors.error,
                          child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          ref.read(myLinksProvider.notifier).deleteLink(link.id, link.userId);
                        },
                        child: ListTile(
                          key: ValueKey(link.id),
                          leading: Icon(
                            _getPlatformIcon(link.platform.name),
                            color: AppColors.primary,
                          ),
                          title: Text(link.displayName ?? link.platform.displayName),
                          subtitle: Text(
                            link.url,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                onPressed: () => showLinkDialog(existingLink: link),
                              ),
                              ReorderableDragStartListener(
                                index: index,
                                child: const Icon(Icons.drag_handle_rounded, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform) {
      case 'phone':
        return Icons.phone_android_rounded;
      case 'whatsapp':
        return Icons.chat_bubble_outline_rounded;
      case 'email':
        return Icons.email_outlined;
      case 'instagram':
        return Icons.camera_alt_outlined;
      case 'linkedin':
        return Icons.work_outline_rounded;
      case 'github':
        return Icons.code_rounded;
      case 'x':
        return Icons.close_rounded;
      case 'portfolio':
        return Icons.language_rounded;
      default:
        return Icons.link_rounded;
    }
  }
}

class _LinkBottomSheet extends HookConsumerWidget {
  const _LinkBottomSheet({
    required this.userId,
    this.existingLink,
    required this.onSave,
  });

  final String userId;
  final UserLinkModel? existingLink;
  final Future<void> Function(UserLinkModel) onSave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final selectedPlatform = useState<LinkPlatform>(existingLink?.platform ?? LinkPlatform.github);
    final displayNameController = useTextEditingController(text: existingLink?.displayName ?? '');
    final urlController = useTextEditingController(text: existingLink?.url ?? '');
    final isVisible = useState<bool>(existingLink?.isVisible ?? true);
    
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final isSaving = useState(false);

    Future<void> handleSave() async {
      if (!formKey.currentState!.validate()) return;
      isSaving.value = true;
      
      final link = UserLinkModel(
        id: existingLink?.id ?? '',
        userId: userId,
        platform: selectedPlatform.value,
        url: urlController.text.trim(),
        displayName: displayNameController.text.trim().isEmpty ? null : displayNameController.text.trim(),
        isVisible: isVisible.value,
        createdAt: existingLink?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await onSave(link);
      isSaving.value = false;
    }

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + AppDimensions.spacing24,
        top: AppDimensions.spacing24,
        left: AppDimensions.pagePaddingH,
        right: AppDimensions.pagePaddingH,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLg)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                existingLink == null ? 'Add Social Link' : 'Edit Social Link',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppDimensions.spacing20),

              // ─── Platform Selector ─────────────────────────
              DropdownButtonFormField<LinkPlatform>(
                value: selectedPlatform.value,
                decoration: InputDecoration(
                  labelText: 'Platform',
                  prefixIcon: const Icon(Icons.apps_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                ),
                items: LinkPlatform.values.map((p) {
                  return DropdownMenuItem<LinkPlatform>(
                    value: p,
                    child: Text(p.displayName),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    selectedPlatform.value = val;
                    // Reset URL field if switching to non-URL or URL
                    urlController.clear();
                  }
                },
              ),
              const SizedBox(height: AppDimensions.spacing16),

              // ─── Display Name (Optional) ────────────────────
              SeemeTextField(
                controller: displayNameController,
                label: 'Label / Display Name (Optional)',
                hint: 'e.g. My GitHub or Personal WhatsApp',
                prefixIcon: Icons.label_outline_rounded,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: AppDimensions.spacing16),

              // ─── URL / Input Field ──────────────────────────
              SeemeTextField(
                controller: urlController,
                label: selectedPlatform.value.isUrlType ? 'URL' : 'Contact Value',
                hint: selectedPlatform.value.placeholder,
                prefixIcon: Icons.link_rounded,
                keyboardType: selectedPlatform.value == LinkPlatform.phone ||
                        selectedPlatform.value == LinkPlatform.whatsapp
                    ? TextInputType.phone
                    : (selectedPlatform.value == LinkPlatform.email
                        ? TextInputType.emailAddress
                        : TextInputType.url),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'This field is required';
                  }
                  
                  if (selectedPlatform.value.isUrlType) {
                    return InputValidators.url(val);
                  }
                  
                  if (selectedPlatform.value == LinkPlatform.email) {
                    return InputValidators.email(val);
                  }

                  if (selectedPlatform.value == LinkPlatform.phone || selectedPlatform.value == LinkPlatform.whatsapp) {
                    final cleanNum = val.replaceAll(RegExp(r'[\s+()-]'), '');
                    if (cleanNum.length < 8) {
                      return 'Please enter a valid phone number';
                    }
                  }
                  
                  return null;
                },
              ),
              const SizedBox(height: AppDimensions.spacing16),

              // ─── Visibility Toggle ──────────────────────────
              SwitchListTile.adaptive(
                title: const Text('Visible to other students'),
                subtitle: const Text('Turn off to temporarily hide this link from your profile'),
                value: isVisible.value,
                onChanged: (val) => isVisible.value = val,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: AppDimensions.spacing24),

              // ─── Action Buttons ─────────────────────────────
              SeemeButton(
                label: existingLink == null ? 'Add Link' : 'Save Changes',
                onPressed: handleSave,
                isLoading: isSaving.value,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
