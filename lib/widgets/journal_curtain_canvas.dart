import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../core/services/speech_service.dart';
import '../core/theme/colors.dart';
import '../core/theme/typography.dart';
import '../models/journal_entry.dart';
import 'apple_widgets.dart';
import 'mood_slider.dart';

/// Curtain Canvas that expands smoothly from the "express yourself" input bar
class JournalCurtainCanvas extends StatefulWidget {
  final JournalEntry? initialEntry;
  final bool initialArchiveState;

  const JournalCurtainCanvas({
    super.key,
    this.initialEntry,
    this.initialArchiveState = true,
  });

  static Future<JournalEntry?> show(
    BuildContext context, {
    JournalEntry? initialEntry,
    bool initialArchiveState = true,
  }) {
    AppleHaptics.lightImpact();
    return showModalBottomSheet<JournalEntry>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (_) => JournalCurtainCanvas(
        initialEntry: initialEntry,
        initialArchiveState: initialArchiveState,
      ),
    );
  }

  @override
  State<JournalCurtainCanvas> createState() => _JournalCurtainCanvasState();
}

class _JournalCurtainCanvasState extends State<JournalCurtainCanvas>
    with SingleTickerProviderStateMixin {
  late TextEditingController _titleController;
  late TextEditingController _contextController;
  late TextEditingController _customTagController;

  late MoodItem _selectedMood;
  late List<String> _selectedTags;
  late bool _saveToArchive;

  bool _isListening = false;
  bool _speechAvailable = false;
  String _lastSpeechText = '';

  final List<String> _suggestedTags = [
    'Mindfulness',
    'Gratitude',
    'Ideas',
    'Work',
    'Life',
    'Design',
    'Health',
    'Personal',
  ];

  @override
  void initState() {
    super.initState();
    final entry = widget.initialEntry;
    _titleController = TextEditingController(text: entry?.prompt ?? '');
    _contextController = TextEditingController(text: entry?.thought ?? '');
    _customTagController = TextEditingController();

    _selectedMood = MoodSlider.fromMoodString(entry?.mood);
    _selectedTags = entry != null ? List<String>.from(entry.tags) : ['Reflection'];
    _saveToArchive = entry?.isArchived ?? widget.initialArchiveState;

    _checkSpeech();
  }

  Future<void> _checkSpeech() async {
    final available = await SpeechService.instance.initialize();
    if (mounted) setState(() => _speechAvailable = available);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contextController.dispose();
    _customTagController.dispose();
    super.dispose();
  }

  void _toggleSpeech() async {
    AppleHaptics.lightImpact();
    if (_isListening) {
      await SpeechService.instance.stopListening();
      setState(() {
        _isListening = false;
        _lastSpeechText = '';
      });
    } else {
      if (!_speechAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speech recognition is not available.')),
        );
        return;
      }
      await SpeechService.instance.startListening(
        onResult: (text) {
          if (!mounted) return;
          setState(() {
            final existing = _contextController.text;
            // Remove the previous speech segment if present, then append new final result
            if (_lastSpeechText.isNotEmpty && existing.endsWith(_lastSpeechText)) {
              _contextController.text =
                  '${existing.substring(0, existing.length - _lastSpeechText.length).trimRight()} $text'.trim();
            } else {
              _contextController.text = existing.isEmpty ? text : '$existing $text';
            }
            _lastSpeechText = text;
          });
        },
        onStatusChange: (listening) {
          if (mounted) setState(() => _isListening = listening);
        },
      );
    }
  }

  void _addCustomTag() {
    final tag = _customTagController.text.trim().replaceAll('#', '');
    if (tag.isNotEmpty && !_selectedTags.contains(tag)) {
      AppleHaptics.selection();
      setState(() {
        _selectedTags.add(tag);
        _customTagController.clear();
      });
    }
  }

  void _toggleTag(String tag) {
    AppleHaptics.selection();
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  void _saveEntry() {
    final contextText = _contextController.text.trim();
    if (contextText.isEmpty) {
      AppleHaptics.notificationError();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write your reflections or context before saving.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    AppleHaptics.notificationSuccess();
    final now = DateTime.now();
    final dateString =
        "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final title = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : 'Reflection';

    final entry = JournalEntry(
      id: widget.initialEntry?.id ?? const Uuid().v4(),
      date: widget.initialEntry?.date ?? dateString,
      prompt: title,
      thought: contextText,
      mood: _selectedMood.key,
      tags: _selectedTags.isEmpty ? ['Reflection'] : _selectedTags,
      isArchived: _saveToArchive,
      createdAt: widget.initialEntry?.createdAt ?? now,
      updatedAt: now,
    );

    Navigator.of(context).pop(entry);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? BotanicalColors.darkPrimary : BotanicalColors.lightPrimary;
    final borderColor = isDark ? BotanicalColors.darkBorder : BotanicalColors.lightBorder;
    final surfaceColor = isDark ? BotanicalColors.darkSurface : BotanicalColors.lightSurface;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.90,
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
            // Curtain Pull Handle
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

            // Curtain Header Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(CupertinoIcons.pencil_outline, size: 18, color: primaryColor),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.initialEntry != null ? 'Edit Journal' : 'Journal Canvas',
                            style: BotanicalTypography.journalHeadingStyle(isDark: isDark, fontSize: 17),
                          ),
                          Text(
                            DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
                            style: BotanicalTypography.dateStyle(isDark: isDark, fontSize: 11),
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
            const Divider(height: 16),

            // Scrollable Canvas Body
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                children: [
                  // 1. Title of the Page
                  Text(
                    'TITLE OF THE PAGE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.7,
                      color: isDark ? BotanicalColors.darkTextSecondary : BotanicalColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF7F5FA),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor, width: 0.8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    child: TextField(
                      controller: _titleController,
                      style: BotanicalTypography.journalHeadingStyle(isDark: isDark, fontSize: 18),
                      decoration: const InputDecoration(
                        hintText: 'Enter title for this entry...',
                        hintStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 2. Context / Reflection Canvas
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'CONTEXT & REFLECTIONS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.7,
                          color: isDark ? BotanicalColors.darkTextSecondary : BotanicalColors.lightTextSecondary,
                        ),
                      ),
                      InkWell(
                        onTap: _toggleSpeech,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isListening ? CupertinoIcons.stop_fill : CupertinoIcons.mic_fill,
                                size: 14,
                                color: _isListening ? Colors.red : primaryColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _isListening ? 'Listening...' : 'Voice Input',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _isListening ? Colors.red : primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 140,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF7F5FA),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _isListening ? Colors.red.withValues(alpha: 0.6) : borderColor,
                        width: _isListening ? 1.5 : 0.8,
                      ),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: TextField(
                      controller: _contextController,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.45),
                      decoration: const InputDecoration(
                        hintText: 'Write down your context, thoughts, insights, or genuine reflections...',
                        hintStyle: TextStyle(fontSize: 14),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 3. Tags Section
                  Text(
                    'TAGS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.7,
                      color: isDark ? BotanicalColors.darkTextSecondary : BotanicalColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Active Tags Wrap
                  if (_selectedTags.isNotEmpty) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _selectedTags.map((t) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: primaryColor.withValues(alpha: 0.35), width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '#$t',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: primaryColor),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () => _toggleTag(t),
                                child: Icon(CupertinoIcons.xmark, size: 12, color: primaryColor),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Suggested Tag Pills & Add Input
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ..._suggestedTags.where((tag) => !_selectedTags.contains(tag)).map((tag) {
                        return ActionChip(
                          avatar: const Icon(CupertinoIcons.add, size: 12),
                          label: Text(tag, style: const TextStyle(fontSize: 12)),
                          backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                          side: BorderSide(color: borderColor, width: 0.75),
                          onPressed: () => _toggleTag(tag),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Custom Tag Field
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 38,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF7F5FA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor, width: 0.8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: TextField(
                            controller: _customTagController,
                            style: const TextStyle(fontSize: 13),
                            onSubmitted: (_) => _addCustomTag(),
                            decoration: const InputDecoration(
                              hintText: 'Add custom tag (e.g. ProjectX)...',
                              hintStyle: TextStyle(fontSize: 12),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 9),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        icon: const Icon(CupertinoIcons.plus, size: 16),
                        onPressed: _addCustomTag,
                        style: IconButton.styleFrom(
                          minimumSize: const Size(38, 38),
                          backgroundColor: primaryColor.withValues(alpha: 0.15),
                          foregroundColor: primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 4. Mood Selector (in the Slider way: Left: Bad, Right: Super Happy)
                  MoodSlider(
                    initialValue: _selectedMood.value.toDouble(),
                    onMoodChanged: (mood) {
                      setState(() => _selectedMood = mood);
                    },
                  ),
                  const SizedBox(height: 20),

                  // 5. Destination Toggle (Archive vs Recents)
                  AppleGroupedCard(
                    children: [
                      AppleListTile(
                        icon: CupertinoIcons.archivebox_fill,
                        iconColor: const Color(0xFF7A58A5),
                        title: const Text('Save to Archive', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Text(
                          _saveToArchive
                              ? 'Saved to folder archive immediately'
                              : 'Keep in active Recents feed',
                          style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
                        ),
                        trailing: CupertinoSwitch(
                          value: _saveToArchive,
                          activeTrackColor: primaryColor,
                          onChanged: (val) {
                            AppleHaptics.selection();
                            setState(() => _saveToArchive = val);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Bottom CTA Bar
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: BoxDecoration(
                color: surfaceColor,
                border: Border(top: BorderSide(color: borderColor, width: 0.6)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        side: BorderSide(color: borderColor),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      icon: Icon(
                        _saveToArchive ? CupertinoIcons.archivebox_fill : CupertinoIcons.checkmark_alt,
                        size: 18,
                      ),
                      label: Text(
                        _saveToArchive ? 'Save in Archive' : 'Save Reflection',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 2,
                      ),
                      onPressed: _saveEntry,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
