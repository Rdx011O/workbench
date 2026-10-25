import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/colors.dart';
import '../providers/providers.dart';
import '../views/calendar/calendar_view.dart';
import '../views/home/home_view.dart';
import '../views/notes_journal/notes_journal_view.dart';
import '../views/profile/profile_view.dart';
import '../views/search/search_view.dart';
import '../views/tasks_reminders/tasks_reminders_view.dart';
import 'apple_widgets.dart';
import 'quick_add_sheet.dart';
import 'workspace_sheet.dart';

class AppScaffold extends ConsumerStatefulWidget {
  const AppScaffold({super.key});

  @override
  ConsumerState<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends ConsumerState<AppScaffold> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeView(),
    CalendarView(),
    TasksAndRemindersView(),
    NotesAndJournalsView(),
  ];



  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? BotanicalColors.darkPrimary : BotanicalColors.lightPrimary;
    final borderColor = isDark ? BotanicalColors.darkBorder : BotanicalColors.lightBorder;
    final surfaceColor = isDark ? BotanicalColors.darkSurface : BotanicalColors.lightSurface;
    final activeWorkspace = ref.watch(activeWorkspaceProvider);

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 820;

    if (isDesktop) {
      // Desktop / Tablet Sidebar Layout
      return Scaffold(
        body: Row(
          children: [
            Container(
              width: 270,
              decoration: BoxDecoration(
                color: surfaceColor,
                border: Border(right: BorderSide(color: borderColor, width: 0.75)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Brand & Workspace Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 26, 20, 16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => WorkspaceSheet.show(context),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Icon(
                                  CupertinoIcons.tray_fill,
                                  size: 20,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    activeWorkspace,
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const Text(
                                    'Click to switch',
                                    style: TextStyle(fontSize: 11, color: CupertinoColors.systemGrey),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(CupertinoIcons.chevron_up_chevron_down, size: 14, color: CupertinoColors.systemGrey),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 0.5),

                  // Desktop Navigation List (Home, Calendar, Tasks & Reminders, Notes & Journals)
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      children: [
                        _buildSidebarItem(0, 'Home', CupertinoIcons.house, CupertinoIcons.house_fill),
                        _buildSidebarItem(1, 'Calendar', CupertinoIcons.calendar, CupertinoIcons.calendar_today),
                        _buildSidebarItem(2, 'Tasks & Reminders', CupertinoIcons.doc_plaintext, CupertinoIcons.checkmark_square_fill),
                        _buildSidebarItem(3, 'Notes & Journals', CupertinoIcons.book, CupertinoIcons.book_fill),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.only(left: 12, bottom: 8),
                          child: Text(
                            'QUICK ACCESS',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                          ),
                        ),
                        _buildSecondarySidebarItem(
                          'Search Everything',
                          CupertinoIcons.search,
                          () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchView())),
                        ),
                        _buildSecondarySidebarItem(
                          'Profile & Settings',
                          CupertinoIcons.person_crop_circle,
                          () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileView())),
                        ),
                      ],
                    ),
                  ),

                  // Quick Create Button
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(CupertinoIcons.add, size: 18),
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

            // Content Area
            Expanded(
              child: _pages[_currentIndex],
            ),
          ],
        ),
      );
    }

    // Mobile Navigation (Floating Modern Pill Bar matching Fresh UI Screenshot)
    return Scaffold(
      extendBody: true,
      body: _pages[_currentIndex],
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? BotanicalColors.darkSurface.withValues(alpha: 0.92)
                  : BotanicalColors.navBarLight.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(36),
              border: Border.all(
                color: isDark ? BotanicalColors.darkBorder : BotanicalColors.navBarBorder,
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, 'home', CupertinoIcons.house, CupertinoIcons.house_fill),
                _buildNavItem(1, 'calendar', CupertinoIcons.calendar, CupertinoIcons.calendar_today),
                _buildNavItem(2, 'tasks', CupertinoIcons.doc_plaintext, CupertinoIcons.checkmark_square_fill),
                _buildNavItem(3, 'notes', CupertinoIcons.book, CupertinoIcons.book_fill),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon, IconData activeIcon) {
    final isSelected = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? BotanicalColors.darkPrimary : BotanicalColors.lightPrimary;
    final unselectedColor = isDark ? BotanicalColors.darkTextSecondary : const Color(0xFF6E687A);

    return InkWell(
      onTap: () {
        AppleHaptics.selection();
        setState(() => _currentIndex = index);
      },
      borderRadius: BorderRadius.circular(28),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: isSelected
            ? const EdgeInsets.symmetric(horizontal: 18, vertical: 6)
            : const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.85))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 24,
              color: isSelected ? primaryColor : unselectedColor,
            ),
            if (isSelected) ...[
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ],
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
        color: isSelected ? primaryColor.withValues(alpha: 0.12) : Colors.transparent,
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
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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
