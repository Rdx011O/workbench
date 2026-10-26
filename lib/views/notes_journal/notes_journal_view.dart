import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/services/speech_service.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../models/journal_entry.dart';
import '../../models/note.dart';
import '../../providers/providers.dart';
import '../../widgets/apple_widgets.dart';
import '../../widgets/journal_editor_sheet.dart';
import '../../widgets/links_table_sheet.dart';
import '../../widgets/note_editor_sheet.dart';

class NotesAndJournalsView extends ConsumerStatefulWidget {
  final int initialTab;
  const NotesAndJournalsView({super.key, this.initialTab = 0});

  @override
  ConsumerState<NotesAndJournalsView> createState() => _NotesAndJournalsViewState();
}

class _NotesAndJournalsViewState extends ConsumerState<NotesAndJournalsView> {
  late int _selectedTab; // 0: Notes, 1: Journal

  // Journal Search & Mood Filter
  final TextEditingController _journalSearchController = TextEditingController();
  String _journalQuery = '';
  String? _selectedMoodFilter; // null: all, or 'happy', 'neutral', 'sad', 'angry'

  // Quick Reflection Input
  final TextEditingController _thoughtController = TextEditingController();
  bool _isListening = false;
  bool _isSpeechAvailable = false;
  JournalMood _quickMood = JournalMood.neutral;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    _initSpeech();
    _loadExistingThought();
  }

  Future<void> _initSpeech() async {
    final available = await SpeechService.instance.initialize();
    if (mounted) {
      setState(() => _isSpeechAvailable = available);
    }
  }

  void _loadExistingThought() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final today = DateTime.now();
      final existing = ref.read(journalProvider.notifier).getEntryForDate(today);
      if (existing != null && _thoughtController.text.isEmpty) {
        _thoughtController.text = existing.thought;
        setState(() => _quickMood = JournalMood.fromString(existing.mood));
      }
    });
  }

  @override
  void dispose() {
    _journalSearchController.dispose();
    _thoughtController.dispose();
    super.dispose();
  }

  void _toggleListening() async {
    AppleHaptics.lightImpact();
    if (_isListening) {
      await SpeechService.instance.stopListening();
      setState(() => _isListening = false);
    } else {
      if (!_isSpeechAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speech recognition is not available or enabled.')),
        );
        return;
      }
      await SpeechService.instance.startListening(
        onResult: (words) {
          setState(() => _thoughtController.text = words);
        },
        onStatusChange: (listening) {
          setState(() => _isListening = listening);
        },
      );
    }
  }

  Future<void> _saveQuickThought() async {
    AppleHaptics.selection();
    final text = _thoughtController.text.trim();
    if (text.isEmpty) return;

    final now = DateTime.now();
    final dateString =
        "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final entry = JournalEntry(
      id: 'reflection-$dateString',
      date: dateString,
      thought: text,
      mood: _quickMood.label.toLowerCase(),
      prompt: 'Daily Reflection',
      createdAt: now,
      updatedAt: now,
    );

    await ref.read(journalProvider.notifier).saveEntry(entry);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reflection saved'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? BotanicalColors.darkPrimary : BotanicalColors.lightPrimary;

    return Scaffold(
      appBar: AppBar(
        title: CupertinoSlidingSegmentedControl<int>(
          groupValue: _selectedTab,
          backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
          thumbColor: isDark ? BotanicalColors.darkSurface : Colors.white,
          children: {
            0: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
              setState(() => _selectedTab = val);
            }
          },
        ),
        actions: [
          if (_selectedTab == 0)
            IconButton(
              icon: const Icon(CupertinoIcons.plus_circle_fill, size: 26),
              color: primaryColor,
              tooltip: 'New Note',
              onPressed: () async {
                AppleHaptics.lightImpact();
                final note = await NoteEditorSheet.show(context);
                if (note != null) {
                  ref.read(notesProvider.notifier).addNote(note);
                }
              },
            )
          else
            IconButton(
              icon: const Icon(CupertinoIcons.square_pencil_fill, size: 24),
              color: primaryColor,
              tooltip: 'New Journal Entry',
              onPressed: () async {
                AppleHaptics.lightImpact();
                final entry = await JournalEditorSheet.show(context);
                if (entry != null) {
                  ref.read(journalProvider.notifier).saveEntry(entry);
                }
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: _selectedTab == 0 ? _buildNotesTab(context) : _buildJournalTab(context),
      ),
    );
  }

  // --- Notes Tab ---
  Widget _buildNotesTab(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notes = ref.watch(notesProvider);

    final pinnedNotes = notes.where((n) => n.isPinned).toList();
    final otherNotes = notes.where((n) => !n.isPinned).toList();

    if (notes.isEmpty) {
      return const Center(
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
      );
    }

    return ListView(
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

  // --- Journal Tab (Redesigned per Part E, item 18) ---
  Widget _buildJournalTab(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? BotanicalColors.darkPrimary : BotanicalColors.lightPrimary;
    final borderColor = isDark ? BotanicalColors.darkBorder : BotanicalColors.lightBorder;
    final allEntries = ref.watch(journalProvider);

    // Apply Real-time search query and mood filter
    final filteredEntries = allEntries.where((entry) {
      if (_selectedMoodFilter != null && entry.mood.toLowerCase() != _selectedMoodFilter) {
        return false;
      }
      if (_journalQuery.isNotEmpty) {
        final q = _journalQuery.toLowerCase();
        final matchesThought = entry.thought.toLowerCase().contains(q);
        final matchesPrompt = entry.prompt?.toLowerCase().contains(q) ?? false;
        final matchesDate = entry.date.toLowerCase().contains(q);
        if (!matchesThought && !matchesPrompt && !matchesDate) return false;
      }
      return true;
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
      children: [
        // Journal Search Bar (Part E, item 18)
        Container(
          height: 40,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? BotanicalColors.darkSurface : BotanicalColors.lightSurface,
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
                  controller: _journalSearchController,
                  onChanged: (val) => setState(() => _journalQuery = val.trim()),
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Search reflections & journal entries...',
                    hintStyle: TextStyle(fontSize: 13),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (_journalQuery.isNotEmpty)
                IconButton(
                  icon: const Icon(CupertinoIcons.xmark_circle_fill, size: 16),
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    _journalSearchController.clear();
                    setState(() => _journalQuery = '');
                  },
                ),
            ],
          ),
        ),

        // 4 Mood Filter Choices (Happy, Neutral, Sad, Angry)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  label: const Text('All Moods'),
                  selected: _selectedMoodFilter == null,
                  selectedColor: primaryColor.withValues(alpha: 0.16),
                  side: BorderSide(color: _selectedMoodFilter == null ? primaryColor : borderColor),
                  onSelected: (_) => setState(() => _selectedMoodFilter = null),
                ),
              ),
              ...JournalMood.values.map((mood) {
                final isSelected = _selectedMoodFilter == mood.label.toLowerCase();
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    avatar: Text(mood.emoji, style: const TextStyle(fontSize: 14)),
                    label: Text(mood.label),
                    selected: isSelected,
                    selectedColor: primaryColor.withValues(alpha: 0.16),
                    side: BorderSide(color: isSelected ? primaryColor : borderColor),
                    onSelected: (_) {
                      setState(() {
                        _selectedMoodFilter = isSelected ? null : mood.label.toLowerCase();
                      });
                    },
                  ),
                );
              }),
            ],
          ),
        ),

        // Daily Quick Reflection Card (Calm, personal, writing-focused)
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? BotanicalColors.darkSurface : BotanicalColors.lightSurface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor, width: 0.75),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Today’s Reflection',
                    style: BotanicalTypography.journalHeadingStyle(isDark: isDark, fontSize: 17),
                  ),
                  Text(
                    DateFormat('EEEE, d MMM').format(DateTime.now()),
                    style: BotanicalTypography.dateStyle(isDark: isDark, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 4 Mood Selector for quick reflection
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: JournalMood.values.map((m) {
                    final isSelected = m == _quickMood;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        avatar: Text(m.emoji, style: const TextStyle(fontSize: 14)),
                        label: Text(m.label),
                        selected: isSelected,
                        selectedColor: primaryColor.withValues(alpha: 0.16),
                        side: BorderSide(color: isSelected ? primaryColor : borderColor),
                        onSelected: (_) => setState(() => _quickMood = m),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),

              // Input field
              TextField(
                controller: _thoughtController,
                maxLines: 3,
                style: Theme.of(context).textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'What was your genuine rhythm or reflection today?',
                  hintStyle: const TextStyle(fontSize: 13),
                  filled: true,
                  fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF7F5FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: borderColor, width: 0.6),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton.filledTonal(
                    icon: Icon(_isListening ? CupertinoIcons.stop_fill : CupertinoIcons.mic_fill, size: 18),
                    color: _isListening ? Colors.red : primaryColor,
                    tooltip: 'Voice Input',
                    onPressed: _toggleListening,
                  ),
                  Row(
                    children: [
                      TextButton.icon(
                        icon: const Icon(CupertinoIcons.pencil, size: 15),
                        label: const Text('Full Editor'),
                        onPressed: () async {
                          final entry = await JournalEditorSheet.show(context);
                          if (entry != null) {
                            ref.read(journalProvider.notifier).saveEntry(entry);
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(CupertinoIcons.checkmark, size: 15),
                        label: const Text('Save'),
                        onPressed: _saveQuickThought,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Past Entries List
        if (filteredEntries.isEmpty)
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: isDark ? BotanicalColors.darkSurface : BotanicalColors.lightSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: 0.75),
            ),
            child: Center(
              child: Text(
                _journalQuery.isNotEmpty
                    ? 'No entries match "$_journalQuery".'
                    : 'No reflections in this mood yet.',
                style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 13),
              ),
            ),
          )
        else ...[
          AppleSectionHeader('Reflections (${filteredEntries.length})'),
          ...filteredEntries.reversed.map((entry) {
            final moodEnum = JournalMood.fromString(entry.mood);
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: isDark ? BotanicalColors.darkSurface : BotanicalColors.lightSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor, width: 0.75),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () async {
                  AppleHaptics.lightImpact();
                  final updated = await JournalEditorSheet.show(context, entry: entry);
                  if (updated != null) {
                    ref.read(journalProvider.notifier).saveEntry(updated);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            entry.prompt ?? entry.date,
                            style: BotanicalTypography.journalHeadingStyle(isDark: isDark, fontSize: 15),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark ? BotanicalColors.darkSecondarySurface : BotanicalColors.lightSecondarySurface,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(moodEnum.emoji, style: const TextStyle(fontSize: 12)),
                                const SizedBox(width: 4),
                                Text(
                                  moodEnum.label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? BotanicalColors.darkTextSecondary : BotanicalColors.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        entry.thought,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: isDark ? BotanicalColors.darkTextPrimary : BotanicalColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        entry.date,
                        style: BotanicalTypography.dateStyle(isDark: isDark, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ],
    );
  }
}
