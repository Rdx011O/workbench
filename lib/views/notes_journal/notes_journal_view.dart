import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/colors.dart';
import '../../models/journal_entry.dart';
import '../../models/note.dart';
import '../../providers/providers.dart';
import '../../widgets/apple_widgets.dart';
import '../../widgets/journal_archive_sheet.dart';
import '../../widgets/journal_curtain_canvas.dart';
import '../../widgets/links_table_sheet.dart';
import '../../widgets/mood_slider.dart';
import '../../widgets/note_editor_sheet.dart';

class NotesAndJournalsView extends ConsumerStatefulWidget {
  final int initialTab;
  const NotesAndJournalsView({super.key, this.initialTab = 0});

  @override
  ConsumerState<NotesAndJournalsView> createState() => _NotesAndJournalsViewState();
}

class _NotesAndJournalsViewState extends ConsumerState<NotesAndJournalsView> {
  late int _selectedTab; // 0: Notes, 1: Journal

  // Search
  bool _isSearchOpen = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 120), () {
      if (mounted) {
        setState(() => _searchQuery = query.trim().toLowerCase());
      }
    });
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
      return DateFormat('d MMM').format(dateTime);
    }
  }

  Future<void> _openCurtainCanvas(BuildContext context, {JournalEntry? entry}) async {
    AppleHaptics.lightImpact();
    final messenger = ScaffoldMessenger.of(context);
    final result = await JournalCurtainCanvas.show(
      context,
      initialEntry: entry,
      initialArchiveState: entry?.isArchived ?? true,
    );

    if (result != null) {
      await ref.read(journalProvider.notifier).saveEntry(result);
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(result.isArchived ? 'Saved into Archive' : 'Saved to Recents'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? BotanicalColors.darkPrimary : BotanicalColors.lightPrimary;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: CupertinoSlidingSegmentedControl<int>(
          groupValue: _selectedTab,
          backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
          thumbColor: isDark ? BotanicalColors.darkSurface : Colors.white,
          children: {
            0: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              child: Text(
                'Notes',
                style: TextStyle(
                  fontWeight: _selectedTab == 0 ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                  color: isDark ? BotanicalColors.darkTextPrimary : BotanicalColors.lightTextPrimary,
                ),
              ),
            ),
            1: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              child: Text(
                'Journal',
                style: TextStyle(
                  fontWeight: _selectedTab == 1 ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                  color: isDark ? BotanicalColors.darkTextPrimary : BotanicalColors.lightTextPrimary,
                ),
              ),
            ),
          },
          onValueChanged: (val) {
            if (val != null) {
              AppleHaptics.selection();
              setState(() {
                _selectedTab = val;
                _isSearchOpen = false;
                _searchQuery = '';
                _searchController.clear();
              });
            }
          },
        ),
        actions: [
          // Circular search button as in screenshot
          Container(
            margin: const EdgeInsets.only(right: 14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.04),
            ),
            child: IconButton(
              icon: Icon(
                _isSearchOpen ? CupertinoIcons.xmark : CupertinoIcons.search,
                size: 20,
              ),
              color: primaryColor,
              onPressed: () {
                AppleHaptics.selection();
                setState(() {
                  _isSearchOpen = !_isSearchOpen;
                  if (!_isSearchOpen) {
                    _searchQuery = '';
                    _searchController.clear();
                  }
                });
              },
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main Body: Notes Tab or Journal Tab
          _selectedTab == 0 ? _buildNotesTab(context) : _buildJournalTab(context),

          // Floating Input Pill Bar (matching screenshot: above bottom nav bar in Journal tab)
          if (_selectedTab == 1)
            Positioned(
              left: 28,
              right: 28,
              bottom: 84, // positioned nicely above the floating capsule navigation bar
              child: _buildExpressPill(context, isDark),
            ),
        ],
      ),
    );
  }

  // --- Floating "express yourself" Input Bar (Reference Screenshot) ---
  Widget _buildExpressPill(BuildContext context, bool isDark) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2B2635) : Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.08),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () => _openCurtainCanvas(context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 6, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'express youself',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: isDark ? BotanicalColors.darkTextSecondary : const Color(0xFF6B6575),
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                // Dark slate/aubergine circular microphone button
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4A3B5A), // exact deep purple aubergine from screenshot
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      CupertinoIcons.mic_fill,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Journal Tab (Matching Screenshot: Archive Folder Card + Recents) ---
  Widget _buildJournalTab(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? BotanicalColors.darkBorder : BotanicalColors.lightBorder;

    final archivedEntries = ref.watch(archivedJournalProvider);
    final recentEntries = ref.watch(recentJournalProvider);

    // Apply optional search filter
    final filteredRecents = recentEntries.where((e) {
      if (_searchQuery.isEmpty) return true;
      final t = e.displayTitle.toLowerCase();
      final c = e.thought.toLowerCase();
      return t.contains(_searchQuery) || c.contains(_searchQuery);
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 160), // extra bottom padding for floating pill
      children: [
        // Optional Search Bar when toggled
        if (_isSearchOpen) ...[
          Container(
            height: 42,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: isDark ? BotanicalColors.darkSurface : BotanicalColors.lightSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 0.8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(CupertinoIcons.search, size: 16, color: CupertinoColors.systemGrey),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    autofocus: true,
                    style: const TextStyle(fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Search journal reflections...',
                      hintStyle: TextStyle(fontSize: 13),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // 1. Archive Folder Card (Exact Screenshot Match)
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF282432) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.05),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => JournalArchiveSheet.show(context),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Row(
                  children: [
                    // Purple folder outline/fill icon
                    Icon(
                      CupertinoIcons.folder,
                      size: 32,
                      color: isDark ? const Color(0xFFBCA6D8) : const Color(0xFF4A3B5A),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Archive',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 19,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'items: ${archivedEntries.length}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? BotanicalColors.darkTextSecondary
                                : const Color(0xFF756F82),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 26),

        // 2. Section Header: Recents (Exact Screenshot Match)
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Recents',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: isDark ? const Color(0xFFD6C8E8) : const Color(0xFF4A3B5A),
            ),
          ),
        ),

        // 3. Recent Cards List (Exact Screenshot Match: Title of journal, Mon 12 Oct, 2 mins ago)
        if (filteredRecents.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? BotanicalColors.darkSurface : BotanicalColors.lightSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: 0.75),
            ),
            child: Center(
              child: Text(
                _searchQuery.isNotEmpty
                    ? 'No reflections match "$_searchQuery".'
                    : 'No recent reflections. Tap "express youself" below to write.',
                style: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey),
              ),
            ),
          )
        else
          ...filteredRecents.map((entry) {
            final moodItem = MoodSlider.fromMoodString(entry.mood);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF282432) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _openCurtainCanvas(context, entry: entry),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title of journal
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                entry.displayTitle,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(CupertinoIcons.ellipsis, size: 16),
                              onSelected: (val) {
                                if (val == 'archive') {
                                  AppleHaptics.selection();
                                  ref.read(journalProvider.notifier).toggleArchive(entry.id, true);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Moved to Archive'),
                                      duration: Duration(seconds: 2),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                } else if (val == 'delete') {
                                  AppleHaptics.mediumImpact();
                                  ref.read(journalProvider.notifier).deleteEntry(entry.id);
                                }
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                  value: 'archive',
                                  child: Row(
                                    children: [
                                      Icon(CupertinoIcons.archivebox, size: 16),
                                      SizedBox(width: 8),
                                      Text('Move to Archive', style: TextStyle(fontSize: 13)),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(CupertinoIcons.trash, size: 16, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Delete', style: TextStyle(color: Colors.red, fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Date line: "Mon 12 Oct" (left) and "2 mins ago" (right)
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('EEE d MMM').format(entry.createdAt),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? BotanicalColors.darkTextSecondary : const Color(0xFF6B6575),
                              ),
                            ),
                            Text(
                              _formatRelativeTime(entry.createdAt),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDark ? BotanicalColors.darkTextSecondary : const Color(0xFF756F82),
                              ),
                            ),
                          ],
                        ),

                        // Context snippet
                        if (entry.thought.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            entry.thought,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.35,
                              color: isDark ? BotanicalColors.darkTextPrimary : BotanicalColors.lightTextPrimary,
                            ),
                          ),
                        ],

                        // Tags and Mood Tag if present
                        if (entry.tags.isNotEmpty || entry.mood.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: moodItem.color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(moodItem.emoji, style: const TextStyle(fontSize: 11)),
                                    const SizedBox(width: 4),
                                    Text(
                                      moodItem.label,
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: moodItem.color),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              ...entry.tags.take(2).map((t) {
                                return Container(
                                  margin: const EdgeInsets.only(right: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '#$t',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  // --- Notes Tab ---
  Widget _buildNotesTab(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? BotanicalColors.darkPrimary : BotanicalColors.lightPrimary;
    final notes = ref.watch(notesProvider);

    final pinnedNotes = notes.where((n) => n.isPinned).toList();
    final otherNotes = notes.where((n) => !n.isPinned).toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        tooltip: 'New Note',
        onPressed: () async {
          AppleHaptics.lightImpact();
          final note = await NoteEditorSheet.show(context);
          if (note != null) {
            ref.read(notesProvider.notifier).addNote(note);
          }
        },
        child: const Icon(CupertinoIcons.add, size: 24),
      ),
      body: notes.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.doc_text, size: 48, color: CupertinoColors.systemGrey3),
                  SizedBox(height: 12),
                  Text(
                    'No notes yet',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: CupertinoColors.systemGrey),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Tap + to create your first note.',
                    style: TextStyle(fontSize: 13, color: CupertinoColors.systemGrey2),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
              children: [
                if (pinnedNotes.isNotEmpty) ...[
                  const AppleSectionHeader('Pinned Notes'),
                  ...pinnedNotes.map((n) => _buildNoteCard(n, isDark)),
                  const SizedBox(height: 16),
                ],
                if (otherNotes.isNotEmpty) ...[
                  if (pinnedNotes.isNotEmpty) const AppleSectionHeader('All Notes'),
                  ...otherNotes.map((n) => _buildNoteCard(n, isDark)),
                ],
              ],
            ),
    );
  }

  Widget _buildNoteCard(Note note, bool isDark) {
    final primaryColor = isDark ? BotanicalColors.darkPrimary : BotanicalColors.lightPrimary;
    final isLinksNote = note.title.trim().toLowerCase() == 'links';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? BotanicalColors.darkSurface : BotanicalColors.lightSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? BotanicalColors.darkBorder : BotanicalColors.lightBorder,
          width: 0.75,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          AppleHaptics.lightImpact();
          if (isLinksNote) {
            await LinksTableSheet.show(context, note);
          } else {
            final updated = await NoteEditorSheet.show(context, note: note);
            if (updated != null) {
              ref.read(notesProvider.notifier).updateNote(updated);
            }
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isLinksNote) ...[
                    Icon(CupertinoIcons.link_circle_fill, size: 20, color: primaryColor),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      note.title,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ),
                  if (note.isPinned)
                    Icon(CupertinoIcons.pin_fill, size: 14, color: primaryColor),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                isLinksNote ? 'Interactive Table with automatic row continuation · Tap to manage links' : note.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? BotanicalColors.darkTextSecondary : BotanicalColors.lightTextSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('d MMM yyyy').format(note.updatedAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? BotanicalColors.darkTextSecondary : BotanicalColors.lightTextSecondary,
                    ),
                  ),
                  if (note.tags.isNotEmpty)
                    Wrap(
                      spacing: 4,
                      children: note.tags.take(3).map((t) {
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
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
