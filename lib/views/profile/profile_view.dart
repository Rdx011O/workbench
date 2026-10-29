import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/shorebird_service.dart';
import '../../core/theme/colors.dart';
import '../../providers/providers.dart';
import '../../widgets/apple_widgets.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/workspace_sheet.dart';
import '../auth/login_screen.dart';
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
              onPressed: () async {
                final newName = controller.text.trim();
                if (newName.isNotEmpty) {
                  await AuthService.instance.updateUsername(DatabaseService.instance, newName);
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

  void _showLinkGoogleDialog(BuildContext context) {
    final emailCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(CupertinoIcons.globe, color: Colors.blue, size: 20),
            SizedBox(width: 8),
            Text('Connect Google Account'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Link your Google account to automatically synchronize calendar and backup credentials.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Google Email',
                hintText: 'you@gmail.com',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailCtrl.text.trim();
              if (email.isEmpty) return;
              Navigator.of(ctx).pop();
              final current = AuthService.instance.currentUser;
              if (current != null) {
                final updated = AuthUser(
                  id: current.id,
                  email: current.email,
                  username: current.username,
                  googleEmail: email,
                  isGoogleLinked: true,
                  createdAt: current.createdAt,
                );
                await DatabaseService.instance.updateAuthUser(updated);
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Google account linked successfully!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Connect'),
          ),
        ],
      ),
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

    final authUser = AuthService.instance.currentUser;
    final displayName = (authUser?.username.isNotEmpty == true) ? authUser!.username : settings.userName;
    final displayEmail = (authUser?.email.isNotEmpty == true)
        ? authUser!.email
        : '${displayName.toLowerCase().replaceAll(' ', '')}@queue.local';

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
                    name: displayName,
                    size: 64,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                              ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                displayEmail,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? BotanicalColors.darkTextSecondary : BotanicalColors.lightTextSecondary,
                                ),
                              ),
                            ),
                            if (authUser?.isGoogleLinked == true) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(CupertinoIcons.globe, size: 10, color: Colors.blue),
                                    SizedBox(width: 3),
                                    Text(
                                      'Google',
                                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.blue),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
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
                    onPressed: () => _showEditNameDialog(context, ref, displayName),
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
            const SizedBox(height: 20),

            // Over-The-Air Updates (Shorebird)
            const AppleSectionHeader('App Updates (Shorebird OTA)'),
            const _ShorebirdUpdateCard(),
            const SizedBox(height: 20),

            // Account & Cloud Synchronization
            const AppleSectionHeader('Account & Cloud'),
            AppleGroupedCard(
              children: [
                AppleListTile(
                  icon: CupertinoIcons.globe,
                  iconColor: Colors.blue,
                  title: const Text('Google Account', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  subtitle: Text(
                    authUser?.isGoogleLinked == true
                        ? 'Connected: ${authUser?.googleEmail ?? authUser?.email}'
                        : 'Connect your Google account',
                    style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
                  ),
                  trailing: authUser?.isGoogleLinked == true
                      ? const Icon(CupertinoIcons.checkmark_seal_fill, color: Colors.blue, size: 20)
                      : TextButton(
                          onPressed: () => _showLinkGoogleDialog(context),
                          child: const Text('Connect'),
                        ),
                ),
                AppleListTile(
                  icon: CupertinoIcons.calendar,
                  iconColor: Colors.green,
                  title: const Text('Google Calendar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  subtitle: const Text('View and sync agenda events before workspace', style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey)),
                  trailing: const Icon(CupertinoIcons.checkmark_circle_fill, color: Colors.green, size: 20),
                ),
                AppleListTile(
                  icon: CupertinoIcons.arrow_right_square_fill,
                  iconColor: BotanicalColors.alertRed,
                  title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: BotanicalColors.alertRed)),
                  subtitle: const Text('Log out of this device', style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey)),
                  trailing: const Icon(CupertinoIcons.chevron_right, size: 16, color: CupertinoColors.systemGrey3),
                  onTap: () async {
                    AppleHaptics.mediumImpact();
                    await AuthService.instance.signOut(DatabaseService.instance);
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    }
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

class _ShorebirdUpdateCard extends StatelessWidget {
  const _ShorebirdUpdateCard();

  @override
  Widget build(BuildContext context) {
    final shorebird = ShorebirdService.instance;
    return ListenableBuilder(
      listenable: shorebird,
      builder: (context, _) {
        final isAvailable = shorebird.isShorebirdAvailable;
        final currentPatch = shorebird.currentPatchNumber;
        final status = shorebird.status;

        final String patchLabel = currentPatch != null ? 'Patch #$currentPatch' : 'Base Release (v1.3.0+4)';
        String statusDescription = 'Automatic Over-The-Air code patches';

        Widget? actionWidget;

        switch (status) {
          case UpdateStatusState.checking:
            actionWidget = const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            );
            statusDescription = 'Checking Shorebird servers...';
            break;
          case UpdateStatusState.downloading:
            actionWidget = const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            );
            statusDescription = 'Downloading patch in background...';
            break;
          case UpdateStatusState.updateAvailable:
            actionWidget = CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: BotanicalColors.lightSuccess,
              borderRadius: BorderRadius.circular(12),
              onPressed: () => shorebird.downloadPatch(),
              child: const Text('Download Patch', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
            );
            statusDescription = 'New patch ready to install!';
            break;
          case UpdateStatusState.readyToRestart:
            actionWidget = const Icon(CupertinoIcons.checkmark_seal_fill, color: Colors.green, size: 22);
            statusDescription = 'Patch installed! Restart app to apply.';
            break;
          case UpdateStatusState.upToDate:
            actionWidget = CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => shorebird.checkManually(),
              child: const Text('Check Again', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            );
            statusDescription = 'App is up to date!';
            break;
          case UpdateStatusState.error:
            actionWidget = CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => shorebird.checkManually(),
              child: const Text('Retry', style: TextStyle(fontSize: 13, color: BotanicalColors.alertRed)),
            );
            statusDescription = shorebird.errorMessage ?? 'Update check failed';
            break;
          case UpdateStatusState.idle:
            actionWidget = CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => shorebird.checkManually(),
              child: const Text('Check for Updates', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            );
            statusDescription = isAvailable
                ? 'Check for latest OTA patch'
                : 'Active in release builds • Patches push without APK redownload';
            break;
        }

        return AppleGroupedCard(
          children: [
            AppleListTile(
              icon: CupertinoIcons.arrow_down_circle_fill,
              iconColor: BotanicalColors.lightSuccess,
              title: Row(
                children: [
                  const Text('OTA Code Push', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isAvailable ? Colors.green : Colors.blueGrey).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      patchLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isAvailable ? Colors.green.shade800 : Colors.blueGrey,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Text(
                statusDescription,
                style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
              ),
              trailing: actionWidget,
            ),
          ],
        );
      },
    );
  }
}
