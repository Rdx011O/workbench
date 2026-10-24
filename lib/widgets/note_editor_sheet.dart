import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../core/theme/colors.dart';
import '../models/note.dart';
import 'botanical_icons.dart';

class NoteEditorSheet extends StatefulWidget {
  final Note? initialNote;

  const NoteEditorSheet({
    super.key,
    this.initialNote,
  });

  static Future<Note?> show(BuildContext context, {Note? note}) {
    return showModalBottomSheet<Note>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => NoteEditorSheet(initialNote: note),
    );
  }

  @override
  State<NoteEditorSheet> createState() => _NoteEditorSheetState();
}

class _NoteEditorSheetState extends State<NoteEditorSheet> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _tagController;
  bool _isPinned = false;
  List<String> _tags = [];
  bool _isSaving = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    final note = widget.initialNote;
    _titleController = TextEditingController(text: note?.title ?? '');
    _contentController = TextEditingController(text: note?.content ?? '');
    _tagController = TextEditingController();
    _isPinned = note?.isPinned ?? false;
    _tags = note != null ? List<String>.from(note.tags) : [];

    _titleController.addListener(_onContentChanged);
    _contentController.addListener(_onContentChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _onContentChanged() {
    setState(() => _isSaving = true);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    });
  }

  void _addTag() {
    final text = _tagController.text.trim();
    if (text.isNotEmpty && !_tags.contains(text)) {
      setState(() {
        _tags.add(text);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _saveAndClose() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    final now = DateTime.now();
    final note = Note(
      id: widget.initialNote?.id ?? const Uuid().v4(),
      title: title.isEmpty ? 'Untitled Note' : title,
      content: content,
      tags: _tags,
      isPinned: _isPinned,
      isArchived: widget.initialNote?.isArchived ?? false,
      createdAt: widget.initialNote?.createdAt ?? now,
      updatedAt: now,
    );

    Navigator.of(context).pop(note);
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
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Top action bar
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _isSaving
                              ? BotanicalColors.lightAccent.withValues(alpha: 0.15)
                              : BotanicalColors.lightCompletedSurface.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _isSaving ? 'Autosaving...' : 'Saved',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: _isSaving
                                    ? BotanicalColors.lightAccent
                                    : (isDark ? BotanicalColors.darkCompletedText : BotanicalColors.lightCompletedText),
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: _isPinned ? 'Unpin note' : 'Pin note',
                  icon: Icon(
                    _isPinned ? BotanicalIcons.pinFilled : BotanicalIcons.pin,
                    color: _isPinned ? primaryColor : null,
                  ),
                  onPressed: () => setState(() => _isPinned = !_isPinned),
                ),
                IconButton(
                  icon: const Icon(BotanicalIcons.close),
                  onPressed: _saveAndClose,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Note title input
            TextField(
              controller: _titleController,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontFamily: 'DM Serif Display',
                  ),
              decoration: const InputDecoration(
                hintText: 'Note Title...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const Divider(height: 24),

            // Tags row
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ..._tags.map((tag) {
                  return Chip(
                    label: Text('#$tag'),
                    labelStyle: Theme.of(context).textTheme.labelSmall,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onDeleted: () => _removeTag(tag),
                  );
                }),
                SizedBox(
                  width: 100,
                  height: 32,
                  child: TextField(
                    controller: _tagController,
                    decoration: const InputDecoration(
                      hintText: '+ tag',
                      isDense: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    ),
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Note body editor
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: TextField(
                  controller: _contentController,
                  maxLines: null,
                  expands: true,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
                  decoration: const InputDecoration(
                    hintText: 'Write your thoughts, checklist, or ideas freely...\n- Use dashes for list items',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: _saveAndClose,
              child: const Text('Save Note'),
            ),
          ],
        ),
      ),
    );
  }
}
