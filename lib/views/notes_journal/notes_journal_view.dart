import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/services/speech_service.dart';
import '../../core/theme/colors.dart';
import '../../models/journal_entry.dart';
import '../../models/note.dart';
import '../../providers/providers.dart';
import '../../widgets/apple_widgets.dart';
import '../../widgets/note_editor_sheet.dart';

class NotesAndJournalsView extends ConsumerStatefulWidget {
  final int initialTab;
  const NotesAndJournalsView({super.key, this.initialTab = 0});

  @override
  ConsumerState<NotesAndJournalsView> createState() => _NotesAndJournalsViewState();
}

class _NotesAndJournalsViewState extends ConsumerState<NotesAndJournalsView> {
  late int _selectedTab; // 0: Notes, 1: Journal
  final TextEditingController _thoughtController = TextEditingController();
  bool _isListening = false;
  bool _isSpeechAvailable = false;
  String _selectedMood = 'Calm';

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
        setState(() => _selectedMood = existing.mood);
      }
    });
  }

  @override
  void dispose() {
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

  Future<void> _saveJournalThought() async {
    AppleHaptics.selection();
    final text = _thoughtController.text.trim();
    if (text.isEmpty) return;

    final now = DateTime.now();
    final dateString =
        "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final entry = JournalEntry(
      id: const Uuid().v4(),
      date: dateString,
      thought: text,
      mood: _selectedMood,
      createdAt: now,
      updatedAt: now,
    );

    await ref.read(journalProvider.notifier).saveEntry(entry);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reflection saved for today'),
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
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
          final updated = await NoteEditorSheet.show(context, note: note);
          if (updated != null) {
            ref.read(notesProvider.notifier).updateNote(updated);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
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
                note.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? BotanicalColors.darkTextSecondary : BotanicalColors.lightTextSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('d MMM yyyy').format(note.updatedAt),
                    style: const TextStyle(fontSize: 11, color: CupertinoColors.systemGrey),
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

  // --- Journal Tab ---
  Widget _buildJournalTab(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? BotanicalColors.darkPrimary : BotanicalColors.lightPrimary;
    final allEntries = ref.watch(journalProvider);

    final moods = ['Calm', 'Focused', 'Inspired', 'Grateful', 'Reflective'];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
      children: [
        // Daily Reflection Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? BotanicalColors.darkSurface : BotanicalColors.lightSurface,
            borderRadius: BorderRadius.circular(22),
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
                  Text(
                    'Daily Reflection',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: isDark ? BotanicalColors.darkTextPrimary : BotanicalColors.lightTextPrimary,
                    ),
                  ),
                  Text(
                    DateFormat('EEEE, d MMM').format(DateTime.now()),
                    style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Mood selector
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: moods.map((m) {
                    final isSelected = m == _selectedMood;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(m),
                        selected: isSelected,
                        selectedColor: primaryColor.withValues(alpha: 0.15),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? primaryColor : null,
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _selectedMood = m);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),

              // Input field
              TextField(
                controller: _thoughtController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'What inspired you today? Speak or type your quiet thought...',
                  hintStyle: const TextStyle(fontSize: 13),
                  filled: true,
                  fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton.filledTonal(
                    icon: Icon(_isListening ? CupertinoIcons.stop_fill : CupertinoIcons.mic_fill, size: 18),
                    color: _isListening ? Colors.red : primaryColor,
                    tooltip: 'Voice Record',
                    onPressed: _toggleListening,
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(CupertinoIcons.checkmark, size: 16),
                    label: const Text('Save Reflection'),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _saveJournalThought,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Past Entries
        if (allEntries.isNotEmpty) ...[
          const AppleSectionHeader('Past Reflections'),
          ...allEntries.reversed.map((entry) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? BotanicalColors.darkSurface : BotanicalColors.lightSurface,
                borderRadius: BorderRadius.circular(16),
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
                      Text(
                        entry.date,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          entry.mood,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: primaryColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    entry.thought,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? BotanicalColors.darkTextSecondary : BotanicalColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}
