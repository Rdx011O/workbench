import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/services/update_service.dart';
import '../core/theme/colors.dart';
import '../providers/providers.dart';
import '../views/activity/activity_view.dart';
import '../views/calendar/calendar_view.dart';
import '../views/notes/notes_view.dart';
import '../views/reminders/reminders_view.dart';
import '../views/search/search_view.dart';
import '../views/settings/settings_view.dart';
import '../views/tasks/tasks_view.dart';
import '../views/today/today_view.dart';
import 'apple_widgets.dart';
import 'botanical_icons.dart';
import 'quick_add_sheet.dart';
import 'update_dialog.dart';

class AppScaffold extends ConsumerStatefulWidget {
  const AppScaffold({super.key});

  @override
  ConsumerState<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends ConsumerState<AppScaffold> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    TodayView(),
    CalendarView(),
    TasksView(),
    NotesView(),
    _BrowseHubView(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForBackgroundUpdate();
    });
  }

  Future<void> _checkForBackgroundUpdate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final release = await UpdateService.instance.checkForUpdate();
    if (release != null && mounted) {
      UpdateDialog.show(context, release);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? BotanicalColors.darkPrimary : BotanicalColors.lightPrimary;
    final borderColor = isDark ? BotanicalColors.darkBorder : BotanicalColors.lightBorder;
    final surfaceColor = isDark ? BotanicalColors.darkSurface : BotanicalColors.lightSurface;

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 820;

    if (isDesktop) {
      // Desktop / Tablet Companion Interface (macOS / iPadOS Sidebar Layout)
      return Scaffold(
        body: Row(
          children: [
            // Apple macOS Sidebar
            Container(
              width: 270,
              decoration: BoxDecoration(
                color: surfaceColor,
                border: Border(right: BorderSide(color: borderColor, width: 0.75)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Brand & Date Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 28, 22, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Icon(
                                  BotanicalIcons.leaf,
                                  size: 20,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Botanical',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontFamily: 'DM Serif Display',
                                    fontSize: 22,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? BotanicalColors.darkSecondarySurface : BotanicalColors.lightSecondarySurface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            DateFormat('EEEE, d MMMM').format(DateTime.now()),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 0.2),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 0.5),

                  // Desktop Navigation List
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      children: [
                        _buildSidebarItem(0, 'Today', BotanicalIcons.lightMode, CupertinoIcons.sun_max_fill),
                        _buildSidebarItem(1, 'Calendar', BotanicalIcons.calendar, CupertinoIcons.calendar_today),
                        _buildSidebarItem(2, 'Tasks', BotanicalIcons.tasks, BotanicalIcons.tasksFilled),
                        _buildSidebarItem(3, 'Notes', BotanicalIcons.notes, BotanicalIcons.notesFilled),
                        _buildSidebarItem(4, 'Browse Hub', BotanicalIcons.more, BotanicalIcons.moreFilled),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.only(left: 12, bottom: 8),
                          child: Text(
                            'SHORTCUTS',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.8,
                                ),
                          ),
                        ),
                        _buildSecondarySidebarItem(
                          'Reminders & Habits',
                          BotanicalIcons.reminder,
                          () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RemindersView())),
                        ),
                        _buildSecondarySidebarItem(
                          'Activity & Rhythm',
                          BotanicalIcons.activity,
                          () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ActivityView())),
                        ),
                        _buildSecondarySidebarItem(
                          'Search Everything',
                          BotanicalIcons.search,
                          () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchView())),
                        ),
                        _buildSecondarySidebarItem(
                          'Settings',
                          BotanicalIcons.settings,
                          () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsView())),
                        ),
                      ],
                    ),
                  ),

                  // Desktop Quick Create Button
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(BotanicalIcons.add, size: 18),
                        label: const Text('New Item'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(44, 44),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          AppleHaptics.lightImpact();
                          QuickAddSheet.show(context);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Focused Main Content Area
            Expanded(
              child: _pages[_currentIndex],
            ),
          ],
        ),
      );
    }

    // Mobile Navigation (Apple Liquid Glass Floating Tab Bar + Quick Create)
    final pendingOverdue = ref.watch(tasksProvider).where((t) => t.isOverdue).length;

    return Scaffold(
      extendBody: true,
      body: _pages[_currentIndex],
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: AppleGlassContainer(
            borderRadius: 28,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTabItem(0, 'Today', BotanicalIcons.lightMode, CupertinoIcons.sun_max_fill),
                _buildTabItem(1, 'Calendar', BotanicalIcons.calendar, CupertinoIcons.calendar_today),
                _buildTabItem(2, 'Tasks', BotanicalIcons.tasks, BotanicalIcons.tasksFilled, badgeCount: pendingOverdue),
                _buildTabItem(3, 'Notes', BotanicalIcons.notes, BotanicalIcons.notesFilled),
                _buildTabItem(4, 'Browse', BotanicalIcons.more, BotanicalIcons.moreFilled),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 74),
        child: FloatingActionButton.small(
          elevation: 4,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
          tooltip: 'Quick Create',
          onPressed: () {
            AppleHaptics.lightImpact();
            QuickAddSheet.show(context);
          },
          child: const Icon(BotanicalIcons.add, size: 22),
        ),
      ),
    );
  }

  Widget _buildTabItem(
    int index,
    String label,
    IconData icon,
    IconData activeIcon, {
    int badgeCount = 0,
  }) {
    final isSelected = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? BotanicalColors.darkPrimary : BotanicalColors.lightPrimary;
    final unselectedColor = isDark ? BotanicalColors.darkTextSecondary : const Color(0xFF8E8E93);

    return Semantics(
      selected: isSelected,
      label: '$label tab',
      child: InkWell(
        onTap: () {
          AppleHaptics.selection();
          setState(() => _currentIndex = index);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: const BoxConstraints(minWidth: 56, minHeight: 46),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedScale(
                    scale: isSelected ? 1.08 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutBack,
                    child: Icon(
                      isSelected ? activeIcon : icon,
                      size: 22,
                      color: isSelected ? primaryColor : unselectedColor,
                    ),
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      top: -3,
                      right: -7,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: BotanicalColors.lightError,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                        child: Text(
                          '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? primaryColor : unselectedColor,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarItem(int index, String label, IconData icon, IconData activeIcon) {
    final isSelected = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? BotanicalColors.darkPrimary : BotanicalColors.lightPrimary;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isSelected ? primaryColor.withOpacity(0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          isSelected ? activeIcon : icon,
          color: isSelected ? primaryColor : (isDark ? BotanicalColors.darkTextSecondary : const Color(0xFF6E7570)),
          size: 20,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? primaryColor : null,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () {
          AppleHaptics.selection();
          setState(() => _currentIndex = index);
        },
      ),
    );
  }

  Widget _buildSecondarySidebarItem(String label, IconData icon, VoidCallback onTap) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 18, color: CupertinoColors.systemGrey),
      title: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () {
        AppleHaptics.selection();
        onTap();
      },
    );
  }
}

/// Apple Inset Grouped Browse Hub (Reminders, Activity, Search & Settings)
class _BrowseHubView extends ConsumerWidget {
  const _BrowseHubView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity = ref.watch(activitySummaryProvider);
    final reminders = ref.watch(remindersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse & Settings'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            // Section 1: Productivity & Rhythm
            const AppleSectionHeader('Productivity & Rhythm'),
            AppleGroupedCard(
              children: [
                AppleListTile(
                  icon: BotanicalIcons.reminder,
                  iconColor: BotanicalColors.lightAccent,
                  title: const Text('Reminders & Habits', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  subtitle: Text(
                    '${reminders.where((r) => !r.isCompleted).length} active reminders · Smart snooze',
                    style: const TextStyle(fontSize: 13),
                  ),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RemindersView())),
                ),
                AppleListTile(
                  icon: BotanicalIcons.activity,
                  iconColor: const Color(0xFF328A6E),
                  title: const Text('Activity & Consistency', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  subtitle: Text(
                    '${activity.currentStreakDays} day streak · ${activity.completedTasksToday} done today',
                    style: const TextStyle(fontSize: 13),
                  ),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ActivityView())),
                ),
              ],
            ),

            // Section 2: Discovery & Search
            const AppleSectionHeader('Find & Discover'),
            AppleGroupedCard(
              children: [
                AppleListTile(
                  icon: BotanicalIcons.search,
                  iconColor: const Color(0xFF007AFF),
                  title: const Text('Global Search', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  subtitle: const Text('Instant search across tasks, notes, events, reminders', style: TextStyle(fontSize: 13)),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchView())),
                ),
              ],
            ),

            // Section 3: Preferences
            const AppleSectionHeader('Preferences'),
            AppleGroupedCard(
              children: [
                AppleListTile(
                  icon: BotanicalIcons.settings,
                  iconColor: const Color(0xFF8E8E93),
                  title: const Text('Settings & Personalization', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  subtitle: const Text('Appearance, calendar week start, notifications, backup', style: TextStyle(fontSize: 13)),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsView())),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
