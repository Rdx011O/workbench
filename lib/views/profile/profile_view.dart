import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/colors.dart';
import '../../providers/providers.dart';
import '../../widgets/apple_widgets.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/workspace_sheet.dart';
import '../settings/settings_view.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  void _showEditNameDialog(BuildContext context, WidgetRef ref, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Edit Display Name'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'e.g. Aaditya Battin',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final newName = controller.text.trim();
                if (newName.isNotEmpty) {
                  ref.read(settingsProvider.notifier).updateUserName(newName);
                }
                Navigator.of(ctx).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? BotanicalColors.darkPrimary : BotanicalColors.lightPrimary;
    final settings = ref.watch(settingsProvider);
    final activeWorkspace = ref.watch(activeWorkspaceProvider);
    final workspaces = ref.watch(workspacesProvider);
    final activity = ref.watch(activitySummaryProvider);
    final notes = ref.watch(notesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.gear_alt, size: 22),
            tooltip: 'Settings',
            onPressed: () {
              AppleHaptics.lightImpact();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsView()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
          children: [
            // User Profile Header Card with Part F Initials
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? BotanicalColors.darkSurface : BotanicalColors.lightSurface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? BotanicalColors.darkBorder : BotanicalColors.lightBorder,
                  width: 0.75,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Avatar with derived initials
                  UserAvatar(
                    name: settings.userName,
                    size: 64,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          settings.userName,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                              ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${settings.userName.toLowerCase().replaceAll(' ', '')}@queue.local',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? BotanicalColors.darkTextSecondary : BotanicalColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark
                                ? BotanicalColors.darkSecondarySurface
                                : BotanicalColors.lightSecondarySurface,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(CupertinoIcons.tray_fill, size: 12, color: primaryColor),
                              const SizedBox(width: 6),
                              Text(
                                'Space: $activeWorkspace',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(CupertinoIcons.pencil_circle_fill, size: 26),
                    tooltip: 'Edit Name',
                    color: primaryColor,
                    onPressed: () => _showEditNameDialog(context, ref, settings.userName),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Workspaces Section
            AppleSectionHeader('Workspaces ($activeWorkspace)'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? BotanicalColors.darkSurface : BotanicalColors.lightSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? BotanicalColors.darkBorder : BotanicalColors.lightBorder,
                  width: 0.75,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Your Workspaces',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      TextButton.icon(
                        icon: const Icon(CupertinoIcons.plus, size: 14),
                        label: const Text('Manage', style: TextStyle(fontSize: 13)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => WorkspaceSheet.show(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: workspaces.map((ws) {
                      final isSelected = ws == activeWorkspace;
                      return ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              (ws == 'Workbench' || ws == 'Queue') ? CupertinoIcons.briefcase_fill : CupertinoIcons.folder_fill,
                              size: 13,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? BotanicalColors.darkTextSecondary : BotanicalColors.lightTextSecondary),
                            ),
                            const SizedBox(width: 6),
                            Text(ws),
                          ],
                        ),
                        selected: isSelected,
                        selectedColor: isDark ? BotanicalColors.darkPrimary : BotanicalColors.lightPrimary,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : null,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 13,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            AppleHaptics.selection();
                            ref.read(settingsProvider.notifier).setActiveWorkspace(ws);
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Productivity & Activity Rhythm
            const AppleSectionHeader('Productivity & Rhythm'),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    '${activity.completedTasksToday}',
                    'Done Today',
                    CupertinoIcons.checkmark_circle_fill,
                    const Color(0xFF5E8B7E),
                    isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    '${activity.pendingTasksToday}',
                    'Due Today',
                    CupertinoIcons.clock_fill,
                    const Color(0xFFC77D5B),
                    isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    '${notes.length}',
                    'Notes',
                    CupertinoIcons.doc_text_fill,
                    const Color(0xFF6E5E8A),
                    isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Navigation to Dedicated Settings Screen
            const AppleSectionHeader('Preferences & Configuration'),
            AppleGroupedCard(
              children: [
                AppleListTile(
                  icon: CupertinoIcons.gear_alt_fill,
                  iconColor: primaryColor,
                  title: const Text('Application Settings', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  subtitle: const Text('Theme, notifications, calendar format & backups', style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey)),
                  trailing: const Icon(CupertinoIcons.chevron_right, size: 16, color: CupertinoColors.systemGrey3),
                  onTap: () {
                    AppleHaptics.lightImpact();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsView()),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String value,
    String label,
    IconData icon,
    Color iconColor,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? BotanicalColors.darkSurface : BotanicalColors.lightSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? BotanicalColors.darkBorder : BotanicalColors.lightBorder,
          width: 0.75,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: iconColor),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? BotanicalColors.darkTextSecondary : BotanicalColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
