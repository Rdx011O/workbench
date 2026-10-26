import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../core/theme/colors.dart';
import '../core/theme/typography.dart';
import '../models/journal_entry.dart';
import 'apple_widgets.dart';

enum JournalMood {
  happy('Happy', '😊'),
  neutral('Neutral', '😐'),
  sad('Sad', '😢'),
  angry('Angry', '😠');

  final String label;
  final String emoji;
  const JournalMood(this.label, this.emoji);

  static JournalMood fromString(String val) {
    switch (val.toLowerCase()) {
      case 'happy':
        return JournalMood.happy;
      case 'sad':
        return JournalMood.sad;
      case 'angry':
        return JournalMood.angry;
      case 'neutral':
      default:
        return JournalMood.neutral;
    }
  }
}

/// Calm, personal writing-focused journal editor.
/// Features title, main reflection area, date picker,
/// and the 4 exact mood choices (Happy 😊, Neutral 😐, Sad 😢, Angry 😠).
class JournalEditorSheet extends StatefulWidget {
  final JournalEntry? initialEntry;
  final DateTime? prefilledDate;

  const JournalEditorSheet({
    super.key,
    this.initialEntry,
    this.prefilledDate,
  });

  static Future<JournalEntry?> show(
    BuildContext context, {
    JournalEntry? entry,
    DateTime? prefilledDate,
  }) {
    return showModalBottomSheet<JournalEntry>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => JournalEditorSheet(
        initialEntry: entry,
        prefilledDate: prefilledDate,
      ),
    );
  }

  @override
  State<JournalEditorSheet> createState() => _JournalEditorSheetState();
}

class _JournalEditorSheetState extends State<JournalEditorSheet> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late DateTime _entryDate;
  late JournalMood _selectedMood;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    final entry = widget.initialEntry;
    _titleController = TextEditingController(text: entry?.prompt ?? '');
    _contentController = TextEditingController(text: entry?.thought ?? '');

    if (entry != null) {
      try {
        _entryDate = DateTime.parse(entry.date);
      } catch (_) {
        _entryDate = DateTime.now();
      }
      _selectedMood = JournalMood.fromString(entry.mood);
    } else {
      _entryDate = widget.prefilledDate ?? DateTime.now();
      _selectedMood = JournalMood.neutral;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _entryDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _entryDate = picked);
    }
  }

  void _save() {
    final thought = _contentController.text.trim();
    if (thought.isEmpty) return;

    final now = DateTime.now();
    final dateString =
        "${_entryDate.year.toString().padLeft(4, '0')}-${_entryDate.month.toString().padLeft(2, '0')}-${_entryDate.day.toString().padLeft(2, '0')}";

    final entry = JournalEntry(
      id: widget.initialEntry?.id ?? const Uuid().v4(),
      date: dateString,
      thought: thought,
      mood: _selectedMood.label.toLowerCase(),
      prompt: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
      createdAt: widget.initialEntry?.createdAt ?? now,
      updatedAt: now,
    );

    setState(() => _isSaved = true);
    Navigator.of(context).pop(entry);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? BotanicalColors.darkPrimary : BotanicalColors.lightPrimary;
    final borderColor = isDark ? BotanicalColors.darkBorder : BotanicalColors.lightBorder;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.90,
        decoration: BoxDecoration(
          color: isDark ? BotanicalColors.darkSurface : BotanicalColors.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: borderColor, width: 0.75),
        ),
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Drag Handle
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Header Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: _selectDate,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.calendar, size: 16, color: primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('EEEE, d MMM yyyy').format(_entryDate),
                          style: BotanicalTypography.dateStyle(isDark: isDark, fontSize: 14),
                        ),
                        const SizedBox(width: 4),
                        Icon(CupertinoIcons.chevron_down, size: 12, color: primaryColor),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(CupertinoIcons.xmark_circle_fill, size: 24),
                  color: isDark ? BotanicalColors.darkTextSecondary : BotanicalColors.lightTextSecondary,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 4 Mood Selector (Part E, item 18)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: JournalMood.values.map((mood) {
                  final isSelected = _selectedMood == mood;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      avatar: Text(mood.emoji, style: const TextStyle(fontSize: 16)),
                      label: Text(mood.label),
                      selected: isSelected,
                      selectedColor: primaryColor.withValues(alpha: 0.18),
                      side: BorderSide(
                        color: isSelected ? primaryColor : borderColor,
                        width: isSelected ? 1.5 : 0.8,
                      ),
                      labelStyle: TextStyle(
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? primaryColor
                            : (isDark ? BotanicalColors.darkTextSecondary : BotanicalColors.lightTextSecondary),
                        fontSize: 13,
                      ),
                      onSelected: (_) {
                        AppleHaptics.selection();
                        setState(() => _selectedMood = mood);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Title Field
            TextField(
              controller: _titleController,
              style: BotanicalTypography.journalHeadingStyle(isDark: isDark, fontSize: 20),
              decoration: const InputDecoration(
                hintText: 'Entry Title or Theme (optional)...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            Divider(height: 16, color: borderColor),

            // Main Writing Area
            Expanded(
              child: TextField(
                controller: _contentController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
                decoration: const InputDecoration(
                  hintText: 'Write your thoughts, reflections, or quiet observations...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Bottom Save Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isSaved ? '✓ Saved' : '${_contentController.text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length} words',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? BotanicalColors.darkTextSecondary : BotanicalColors.lightTextSecondary,
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(CupertinoIcons.checkmark, size: 16),
                  label: const Text('Save Entry'),
                  onPressed: _save,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
