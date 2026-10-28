import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/theme/colors.dart';
import '../core/theme/typography.dart';
import '../providers/providers.dart';
import 'apple_widgets.dart';
import 'journal_curtain_canvas.dart';
import 'mood_slider.dart';

/// Bottom sheet displaying all archived journal entries
class JournalArchiveSheet extends ConsumerStatefulWidget {
  const JournalArchiveSheet({super.key});

  static Future<void> show(BuildContext context) {
    AppleHaptics.lightImpact();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (_) => const JournalArchiveSheet(),
    );
  }

  @override
  ConsumerState<JournalArchiveSheet> createState() => _JournalArchiveSheetState();
}

class _JournalArchiveSheetState extends ConsumerState<JournalArchiveSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return '$mins ${mins == 1 ? "min" : "mins"} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? "hour" : "hours"} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? "day" : "days"} ago';
    } else {
      return DateFormat('d MMM yyyy').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? BotanicalColors.darkPrimary : BotanicalColors.lightPrimary;
    final borderColor = isDark ? BotanicalColors.darkBorder : BotanicalColors.lightBorder;
    final surfaceColor = isDark ? BotanicalColors.darkSurface : BotanicalColors.lightSurface;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final archivedEntries = ref.watch(archivedJournalProvider);
    final filteredEntries = archivedEntries.where((entry) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      final title = entry.displayTitle.toLowerCase();
      final thought = entry.thought.toLowerCase();
      final tags = entry.tags.join(' ').toLowerCase();
      return title.contains(q) || thought.contains(q) || tags.contains(q);
    }).toList();

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: borderColor, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
              blurRadius: 30,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Drag handle
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Archive Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7A58A5).withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(CupertinoIcons.folder_fill, size: 22, color: Color(0xFF7A58A5)),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Archive Content',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                          ),
                          Text(
                            '${archivedEntries.length} preserved items',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? BotanicalColors.darkTextSecondary : BotanicalColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(CupertinoIcons.xmark_circle_fill, size: 24),
                    color: isDark ? BotanicalColors.darkTextSecondary : BotanicalColors.lightTextSecondary,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Search Filter inside Archive
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF7F5FA),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor, width: 0.8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    Icon(CupertinoIcons.search, size: 16, color: isDark ? BotanicalColors.darkTextSecondary : BotanicalColors.lightTextSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _query = val.trim()),
                        style: const TextStyle(fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: 'Search archive...',
                          hintStyle: TextStyle(fontSize: 13),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_query.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        child: const Icon(CupertinoIcons.xmark_circle_fill, size: 16, color: CupertinoColors.systemGrey),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),

            // List of archived items
            Expanded(
              child: filteredEntries.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.archivebox, size: 48, color: borderColor),
                          const SizedBox(height: 12),
                          Text(
                            _query.isNotEmpty ? 'No matches in archive' : 'Archive is empty',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _query.isNotEmpty
                                ? 'Try searching another keyword'
                                : 'Save reflections using the input bar to store here.',
                            style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
                      itemCount: filteredEntries.length,
                      itemBuilder: (context, index) {
                        final entry = filteredEntries[index];
                        final moodItem = MoodSlider.fromMoodString(entry.mood);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: borderColor, width: 0.8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () async {
                              AppleHaptics.lightImpact();
                              final updated = await JournalCurtainCanvas.show(
                                context,
                                initialEntry: entry,
                                initialArchiveState: true,
                              );
                              if (updated != null) {
                                ref.read(journalProvider.notifier).saveEntry(updated);
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top row: Title and Mood Badge
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              entry.displayTitle,
                                              style: BotanicalTypography.journalHeadingStyle(isDark: isDark, fontSize: 16),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Text(
                                                  DateFormat('EEE d MMM').format(entry.createdAt),
                                                  style: BotanicalTypography.dateStyle(isDark: isDark, fontSize: 12),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  '·  ${_formatRelativeTime(entry.createdAt)}',
                                                  style: const TextStyle(fontSize: 11, color: CupertinoColors.systemGrey),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: moodItem.color.withValues(alpha: 0.14),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(moodItem.emoji, style: const TextStyle(fontSize: 12)),
                                            const SizedBox(width: 4),
                                            Text(
                                              moodItem.label,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: moodItem.color,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // Context Thought Text
                                  Text(
                                    entry.thought,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.4,
                                      color: isDark ? BotanicalColors.darkTextPrimary : BotanicalColors.lightTextPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Bottom Row: Tags + Options
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      if (entry.tags.isNotEmpty)
                                        Wrap(
                                          spacing: 4,
                                          children: entry.tags.take(3).map((t) {
                                            return Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                '#$t',
                                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                                              ),
                                            );
                                          }).toList(),
                                        )
                                      else
                                        const SizedBox.shrink(),

                                      Row(
                                        children: [
                                          TextButton.icon(
                                            icon: const Icon(CupertinoIcons.arrow_up_doc, size: 14),
                                            label: const Text('Unarchive', style: TextStyle(fontSize: 12)),
                                            style: TextButton.styleFrom(
                                              foregroundColor: primaryColor,
                                              visualDensity: VisualDensity.compact,
                                              padding: const EdgeInsets.symmetric(horizontal: 8),
                                            ),
                                            onPressed: () {
                                              AppleHaptics.selection();
                                              ref.read(journalProvider.notifier).toggleArchive(entry.id, false);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Restored to Recents'),
                                                  duration: Duration(seconds: 2),
                                                  behavior: SnackBarBehavior.floating,
                                                ),
                                              );
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(CupertinoIcons.trash, size: 15, color: Colors.red),
                                            onPressed: () {
                                              AppleHaptics.mediumImpact();
                                              ref.read(journalProvider.notifier).deleteEntry(entry.id);
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
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
