import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../core/theme/colors.dart';
import '../models/note.dart';
import 'botanical_icons.dart';

// ---------------------------------------------------------------------------
// NoteEditorSheet
// ---------------------------------------------------------------------------

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
    final primaryColor =
        isDark ? BotanicalColors.darkPrimary : BotanicalColors.lightPrimary;
    final borderColor =
        isDark ? BotanicalColors.darkBorder : BotanicalColors.lightBorder;
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
            // Drag handle
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _isSaving
                              ? BotanicalColors.lightAccent
                                  .withValues(alpha: 0.15)
                              : BotanicalColors.lightCompletedSurface
                                  .withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _isSaving ? 'Autosaving...' : 'Saved',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: _isSaving
                                    ? BotanicalColors.lightAccent
                                    : (isDark
                                        ? BotanicalColors.darkCompletedText
                                        : BotanicalColors.lightCompletedText),
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

            // ── Formatting toolbar ──────────────────────────────────────────
            _FormattingToolbar(
              controller: _contentController,
              parentContext: context,
              isDark: isDark,
              borderColor: borderColor,
            ),
            const SizedBox(height: 12),

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
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
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
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(height: 1.6),
                  decoration: const InputDecoration(
                    hintText:
                        'Write your thoughts, checklist, or ideas freely...\n- Use dashes for list items',
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

// ---------------------------------------------------------------------------
// _FormattingToolbar
// ---------------------------------------------------------------------------

class _FormattingToolbar extends StatelessWidget {
  final TextEditingController controller;
  final BuildContext parentContext;
  final bool isDark;
  final Color borderColor;

  const _FormattingToolbar({
    required this.controller,
    required this.parentContext,
    required this.isDark,
    required this.borderColor,
  });

  // ── Core text-manipulation helpers ──────────────────────────────────────

  /// Wraps the current selection with [prefix] and [suffix].
  void _wrapSelection(String prefix, String suffix) {
    final text = controller.text;
    final selection = controller.selection;
    if (!selection.isValid) return;

    final selectedText = selection.textInside(text);
    final newText = text.replaceRange(
      selection.start,
      selection.end,
      '$prefix$selectedText$suffix',
    );
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset:
            selection.start + prefix.length + selectedText.length + suffix.length,
      ),
    );
  }

  /// Inserts [prefix] at the beginning of the line that contains the cursor.
  void _insertAtLineStart(String prefix) {
    final text = controller.text;
    final selection = controller.selection;
    if (!selection.isValid) return;

    final lineStart = text.lastIndexOf('\n', selection.start - 1) + 1;
    final newText =
        text.substring(0, lineStart) + prefix + text.substring(lineStart);
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
          offset: selection.start + prefix.length),
    );
  }

  /// Replaces the current selection (or inserts at cursor) with [insertion].
  void _insertAtCursor(String insertion) {
    final text = controller.text;
    final selection = controller.selection;
    if (!selection.isValid) return;

    final newText =
        text.replaceRange(selection.start, selection.end, insertion);
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
          offset: selection.start + insertion.length),
    );
  }

  // ── Specific action handlers ─────────────────────────────────────────────

  void _onBold() => _wrapSelection('**', '**');

  void _onItalic() => _wrapSelection('_', '_');

  void _onHighlight() => _wrapSelection('==', '==');

  void _onCodeBlock() => _wrapSelection('```\n', '\n```');

  void _onCheckbox() => _insertAtLineStart('- [ ] ');

  void _onBullet() => _insertAtLineStart('• ');

  void _onList() => _insertAtLineStart('- ');

  void _onQuote() => _insertAtLineStart('> ');

  void _onFlag() => _insertAtCursor('🚩 ');

  void _onMention() => _insertAtCursor('@');

  void _onAlphabetList() => _insertAtLineStart('a. ');

  /// Auto-increments ordered list numbers if the previous line already has one.
  void _onNumberList() {
    final text = controller.text;
    final selection = controller.selection;
    if (!selection.isValid) return;

    final lineStart = text.lastIndexOf('\n', selection.start - 1) + 1;
    // Look at the previous line to detect an existing number.
    int nextNumber = 1;
    if (lineStart > 0) {
      final prevLineEnd = lineStart - 1; // the '\n' itself
      final prevLineStart = text.lastIndexOf('\n', prevLineEnd - 1) + 1;
      final prevLine = text.substring(prevLineStart, prevLineEnd);
      final match = RegExp(r'^(\d+)\.\s').firstMatch(prevLine);
      if (match != null) {
        nextNumber = int.parse(match.group(1)!) + 1;
      }
    }
    _insertAtLineStart('$nextNumber. ');
  }

  void _onTable() {
    const tableTemplate =
        '| Column 1 | Column 2 | Column 3 |\n'
        '|----------|----------|----------|\n'
        '| Cell     | Cell     | Cell     |\n';
    _insertAtCursor(tableTemplate);
  }

  Future<void> _onHyperlink() async {
    final text = controller.text;
    final selection = controller.selection;
    if (!selection.isValid) return;

    final selectedText = selection.textInside(text);
    final labelController =
        TextEditingController(text: selectedText.isNotEmpty ? selectedText : '');
    final urlController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: parentContext,
      builder: (ctx) => AlertDialog(
        title: const Text('Insert Hyperlink'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelController,
              decoration: const InputDecoration(
                labelText: 'Link text',
                hintText: 'Display text',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'URL',
                hintText: 'https://example.com',
              ),
              keyboardType: TextInputType.url,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Insert'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final label =
          labelController.text.isNotEmpty ? labelController.text : urlController.text;
      final url = urlController.text.trim();
      if (url.isNotEmpty) {
        // Replace selection with the markdown link.
        final newText =
            text.replaceRange(selection.start, selection.end, '[$label]($url)');
        controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(
            offset: selection.start + '[$label]($url)'.length,
          ),
        );
      }
    }

    labelController.dispose();
    urlController.dispose();
  }

  // ── Button builder helper ─────────────────────────────────────────────────

  Widget _btn({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: 20),
        onPressed: onPressed,
        splashRadius: 20,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.02),
        border: Border(
          top: BorderSide(color: borderColor, width: 0.5),
          bottom: BorderSide(color: borderColor, width: 0.5),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          // 1. Bold
          _btn(
            icon: CupertinoIcons.bold,
            tooltip: 'Bold (**text**)',
            onPressed: _onBold,
          ),
          // 2. Italic
          _btn(
            icon: CupertinoIcons.italic,
            tooltip: 'Italic (_text_)',
            onPressed: _onItalic,
          ),
          // 3. Highlight
          _btn(
            icon: CupertinoIcons.paintbrush,
            tooltip: 'Highlight (==text==)',
            onPressed: _onHighlight,
          ),
          // 4. Hyperlink
          _btn(
            icon: CupertinoIcons.link,
            tooltip: 'Hyperlink ([text](url))',
            onPressed: _onHyperlink,
          ),
          // 5. Checkbox
          _btn(
            icon: CupertinoIcons.checkmark_square,
            tooltip: 'Checkbox (- [ ] )',
            onPressed: _onCheckbox,
          ),
          // 6. Bullet (dots)
          _btn(
            icon: CupertinoIcons.circle_fill,
            tooltip: 'Bullet point (• )',
            onPressed: _onBullet,
          ),
          // 7. Flag
          _btn(
            icon: CupertinoIcons.flag,
            tooltip: 'Flag (🚩)',
            onPressed: _onFlag,
          ),
          // 8. Mention
          _btn(
            icon: CupertinoIcons.at,
            tooltip: 'Mention (@)',
            onPressed: _onMention,
          ),
          // 9. List (dash)
          _btn(
            icon: CupertinoIcons.list_bullet,
            tooltip: 'List item (- )',
            onPressed: _onList,
          ),
          // 10. Number list
          _btn(
            icon: CupertinoIcons.list_number,
            tooltip: 'Numbered list (1. )',
            onPressed: _onNumberList,
          ),
          // 11. Alphabet list
          _btn(
            icon: CupertinoIcons.textformat_abc,
            tooltip: 'Alphabet list (a. )',
            onPressed: _onAlphabetList,
          ),
          // 12. Table
          _btn(
            icon: CupertinoIcons.table,
            tooltip: 'Insert table',
            onPressed: _onTable,
          ),
          // 13. Code block
          _btn(
            icon: CupertinoIcons.chevron_left_slash_chevron_right,
            tooltip: 'Code block (``` text ```)',
            onPressed: _onCodeBlock,
          ),
          // 14. Quote
          _btn(
            icon: CupertinoIcons.text_quote,
            tooltip: 'Block quote (> )',
            onPressed: _onQuote,
          ),
        ],
      ),
    );
  }
}
