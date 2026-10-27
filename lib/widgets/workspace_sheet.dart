import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/colors.dart';
import '../providers/providers.dart';
import 'apple_widgets.dart';

class WorkspaceSheet extends ConsumerWidget {
  const WorkspaceSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const WorkspaceSheet(),
    );
  }

  void _showAddWorkspaceDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Text('New Workspace', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Workspaces help you organize your tasks, reminders, and notes into focused contexts.',
                style: TextStyle(fontSize: 13, color: CupertinoColors.systemGrey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'Workspace name (e.g. Design, Client X)',
                  prefixIcon: const Icon(CupertinoIcons.folder_badge_plus, size: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  ref.read(settingsProvider.notifier).addWorkspace(name);
                  Navigator.of(dialogContext).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? BotanicalColors.darkSurface : BotanicalColors.lightSurface;
    final primaryColor = isDark ? BotanicalColors.darkPrimary : BotanicalColors.lightPrimary;
    final activeWorkspace = ref.watch(activeWorkspaceProvider);
    final workspaces = ref.watch(workspacesProvider);

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4.5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Title & Add
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Workspaces',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Switch active context or create a new space',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? BotanicalColors.darkTextSecondary : BotanicalColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
              IconButton.filledTonal(
                icon: const Icon(CupertinoIcons.plus, size: 20),
                tooltip: 'Add Workspace',
                onPressed: () {
                  AppleHaptics.lightImpact();
                  _showAddWorkspaceDialog(context, ref);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Workspace List
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: workspaces.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final ws = workspaces[index];
                final isSelected = ws == activeWorkspace;

                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    AppleHaptics.selection();
                    ref.read(settingsProvider.notifier).setActiveWorkspace(ws);
                    Navigator.of(context).pop();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark
                              ? BotanicalColors.darkSecondarySurface
                              : BotanicalColors.summaryCardLight)
                          : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? (isDark ? BotanicalColors.darkAccent : BotanicalColors.lightAccent)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark ? BotanicalColors.darkPrimary.withValues(alpha: 0.2) : Colors.white)
                                : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Icon(
                              (ws == 'Workbench' || ws == 'Queue')
                                  ? CupertinoIcons.briefcase_fill
                                  : CupertinoIcons.folder_fill,
                              size: 19,
                              color: isSelected ? primaryColor : (isDark ? Colors.white54 : Colors.black45),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ws,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isDark ? BotanicalColors.darkTextPrimary : BotanicalColors.lightTextPrimary,
                                ),
                              ),
                              if (ws == 'Workbench' || ws == 'Queue')
                                Text(
                                  'Default Workspace & Inbox',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? BotanicalColors.darkTextSecondary : BotanicalColors.lightTextSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isDark ? BotanicalColors.darkPrimary : BotanicalColors.lightPrimary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(CupertinoIcons.checkmark, size: 13, color: Colors.white),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Action button to add
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(CupertinoIcons.add, size: 17),
              label: const Text('Add Workspace'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(44, 46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                AppleHaptics.lightImpact();
                _showAddWorkspaceDialog(context, ref);
              },
            ),
          ),
        ],
      ),
    );
  }
}
