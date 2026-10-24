import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/colors.dart';
import '../../models/journal_entry.dart';
import '../../models/note.dart';
import '../../providers/providers.dart';
import '../../widgets/apple_widgets.dart';
import '../../widgets/note_editor_sheet.dart';

class NotesView extends ConsumerStatefulWidget {
  const NotesView({super.key});

  @override
  ConsumerState<NotesView> createState() => _NotesViewState();
}

class _NotesViewState extends ConsumerState<NotesView> with SingleTickerProviderStateMixin {
  int _selectedTabIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedTag;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? BotanicalColors.darkPrimary : BotanicalColors.lightPrimary;
    final borderColor = isDark ? BotanicalColors.darkBorder : BotanicalColors.lightBorder;
    final surfaceColor = isDark ? BotanicalColors.darkSurface : BotanicalColors.lightSurface;

    final notes = ref.watch(notesProvider);
    final journal = ref.watch(journalProvider);

    // Extract all unique tags
    final allTags = <String>{};
    for (final note in notes) {
      allTags.addAll(note.tags);
    }

    // Filter notes
    final filteredNotes = notes.where((note) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTitle = note.title.toLowerCase().contains(q);
        final matchContent = note.content.toLowerCase().contains(q);
        if (!matchTitle && !matchContent) return false;
      }
      if (_selectedTag != null && !note.tags.contains(_selectedTag)) {
        return false;
      }
      return true;
    }).toList();

    final pinnedNotes = filteredNotes.where((n) => n.isPinned).toList();
    final otherNotes = filteredNotes.where((n) => !n.isPinned).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notebook'),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.plus_circle_fill, size: 24),
            tooltip: _selectedTabIndex == 0 ? 'New Note' : 'Add Thought',
            onPressed: () async {
              AppleHaptics.lightImpact();
              if (_selectedTabIndex == 0) {
                final note = await NoteEditorSheet.show(context);
                if (note != null) {
                  ref.read(notesProvider.notifier).addNote(note);
                }
              } else {
                _showAddReflectionDialog(context);
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Apple Sliding Segmented Control
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoSlidingSegmentedControl<int>(
                  groupValue: _selectedTabIndex,
                  backgroundColor: isDark ? BotanicalColors.darkSecondarySurface : BotanicalColors.lightSecondarySurface,
                  thumbColor: isDark ? BotanicalColors.darkSurface : BotanicalColors.lightSurface,
                  children: {
                    0: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Notes & Lists (${notes.length})',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: _selectedTabIndex == 0 ? FontWeight.w600 : FontWeight.w500,
                          color: _selectedTabIndex == 0
                              ? primaryColor
                              : (isDark ? BotanicalColors.darkTextSecondary : BotanicalColors.lightTextSecondary),
                        ),
                      ),
                    ),
                    1: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Daily Journal (${journal.length})',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: _selectedTabIndex == 1 ? FontWeight.w600 : FontWeight.w500,
                          color: _selectedTabIndex == 1
                              ? primaryColor
                              : (isDark ? BotanicalColors.darkTextSecondary : BotanicalColors.lightTextSecondary),
                        ),
                      ),
                    ),
                  },
                  onValueChanged: (val) {
                    if (val != null) {
                      AppleHaptics.selection();
                      setState(() => _selectedTabIndex = val);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 4),

            // Tab View Body
            Expanded(
              child: _selectedTabIndex == 0
                  ? Column(
                      children: [
                        // Apple Search Field
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                          child: AppleSearchField(
                            controller: _searchController,
                            placeholder: 'Filter notes by keyword or idea...',
                            onChanged: (val) => setState(() => _searchQuery = val.trim()),
                            onClear: () => setState(() => _searchQuery = ''),
                          ),
                        ),

                        // Tag Pills Carousel
                        if (allTags.isNotEmpty)
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: Row(
                              children: [
                                _buildTagPill('All Tags', null, isDark, primaryColor),
                                ...allTags.map((t) => _buildTagPill('#$t', t, isDark, primaryColor)),
                              ],
                            ),
                          ),

                        Expanded(
                          child: filteredNotes.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(CupertinoIcons.book, size: 40, color: CupertinoColors.systemGrey3),
                                      const SizedBox(height: 12),
                                      Text('No notes found.', style: Theme.of(context).textTheme.bodySmall),
                                    ],
                                  ),
                                )
                              : ListView(
                                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                                  children: [
                                    if (pinnedNotes.isNotEmpty) ...[
                                      const AppleSectionHeader('Pinned Notes'),
                                      ...pinnedNotes.map((n) => _buildNoteCard(context, n, borderColor, surfaceColor)),
                                      const SizedBox(height: 10),
                                    ],
                                    if (otherNotes.isNotEmpty) ...[
                                      if (pinnedNotes.isNotEmpty)
                                        const AppleSectionHeader('All Notes'),
                                      ...otherNotes.map((n) => _buildNoteCard(context, n, borderColor, surfaceColor)),
                                    ],
                                  ],
                                ),
                        ),
                      ],
                    )
                  : journal.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(CupertinoIcons.pencil_outline, size: 42, color: CupertinoColors.systemGrey3),
                                const SizedBox(height: 12),
                                Text('Your journal is quiet', style: Theme.of(context).textTheme.titleSmall),
                                const SizedBox(height: 4),
                                const Text(
                                  'Record your daily reflections, thoughts, and small wins.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13, color: CupertinoColors.systemGrey),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                          itemCount: journal.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final entry = journal[index];
                            DateTime dateObj;
                            try {
                              dateObj = DateTime.parse(entry.date);
                            } catch (_) {
                              dateObj = entry.createdAt;
                            }
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: borderColor, width: 0.75),
                                boxShadow: [
                                  BoxShadow(
                                    color: isDark ? Colors.transparent : const Color(0x06000000),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
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
                                        DateFormat('EEEE, d MMMM yyyy').format(dateObj),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: BotanicalColors.lightAccent,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isDark ? BotanicalColors.darkSecondarySurface : BotanicalColors.lightSecondarySurface,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          entry.mood,
                                          style: TextStyle(fontSize: 11, color: isDark ? BotanicalColors.darkTextSecondary : BotanicalColors.lightTextSecondary),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    entry.thought,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.45),
                                  ),
                                ],
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

  Widget _buildTagPill(String label, String? tag, bool isDark, Color primaryColor) {
    final isSelected = _selectedTag == tag;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          AppleHaptics.selection();
          setState(() => _selectedTag = isSelected ? null : tag);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor
                : (isDark ? BotanicalColors.darkSecondarySurface : BotanicalColors.lightSecondarySurface),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : (isDark ? BotanicalColors.darkTextPrimary : BotanicalColors.lightTextPrimary),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoteCard(BuildContext context, Note note, Color borderColor, Color surfaceColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 0.75),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.transparent : const Color(0x06000000),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () async {
            AppleHaptics.selection();
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        note.title,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                    ),
                    if (note.isPinned)
                      const Icon(CupertinoIcons.pin_fill, size: 14, color: BotanicalColors.lightAccent),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  note.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4),
                ),
                if (note.tags.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: note.tags.map((t) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? BotanicalColors.darkSecondarySurface : BotanicalColors.lightSecondarySurface,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '#$t',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? BotanicalColors.darkTextSecondary : BotanicalColors.lightTextSecondary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddReflectionDialog(BuildContext context) {
    final controller = TextEditingController();
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('New Reflection'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: controller,
            maxLines: 4,
            placeholder: 'What is on your mind today?',
            autofocus: true,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                final now = DateTime.now();
                final dateStr = "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
                final entry = JournalEntry(
                  id: const Uuid().v4(),
                  date: dateStr,
                  thought: text,
                  mood: 'calm',
                  createdAt: now,
                  updatedAt: now,
                );
                ref.read(journalProvider.notifier).saveEntry(entry);
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
