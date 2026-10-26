import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme/colors.dart';
import '../models/note.dart';
import '../providers/providers.dart';
import 'apple_widgets.dart';

/// Interactive Table Editor specifically designed for the default "Links" Note.
/// Columns: | No. | Link | Name | Description |
/// Enforces: Exactly one trailing blank row at all times.
/// Recalculates sequential numbers automatically upon delete/edit.
class LinksTableSheet extends ConsumerStatefulWidget {
  final Note note;

  const LinksTableSheet({super.key, required this.note});

  static Future<void> show(BuildContext context, Note note) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LinksTableSheet(note: note),
    );
  }

  @override
  ConsumerState<LinksTableSheet> createState() => _LinksTableSheetState();
}

class _LinkEntry {
  int no;
  String link;
  String name;
  String description;

  _LinkEntry({
    required this.no,
    this.link = '',
    this.name = '',
    this.description = '',
  });

  bool get isEmpty => link.trim().isEmpty && name.trim().isEmpty && description.trim().isEmpty;

  Map<String, dynamic> toJson() => {
        'no': no,
        'link': link.trim(),
        'name': name.trim(),
        'description': description.trim(),
      };

  factory _LinkEntry.fromJson(Map<String, dynamic> json, int fallbackNo) {
    return _LinkEntry(
      no: json['no'] as int? ?? fallbackNo,
      link: json['link'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}

class _LinksTableSheetState extends ConsumerState<LinksTableSheet> {
  final List<_LinkEntry> _rows = [];
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _parseRowsFromContent(widget.note.content);
    _ensureExactlyOneTrailingBlank();
  }

  void _parseRowsFromContent(String content) {
    _rows.clear();
    try {
      final decoded = jsonDecode(content);
      if (decoded is List) {
        for (int i = 0; i < decoded.length; i++) {
          final item = decoded[i];
          if (item is Map<String, dynamic>) {
            _rows.add(_LinkEntry.fromJson(item, i + 1));
          }
        }
      }
    } catch (_) {
      // Fallback: parse markdown or plain text lines
      final lines = content.split('\n').where((l) => l.trim().isNotEmpty).toList();
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.contains('http')) {
          _rows.add(_LinkEntry(no: i + 1, link: line.trim(), name: 'Link ${i + 1}'));
        }
      }
    }

    if (_rows.isEmpty) {
      _rows.add(_LinkEntry(no: 1));
    }
  }

  void _recalculateRowNumbers() {
    for (int i = 0; i < _rows.length; i++) {
      _rows[i].no = i + 1;
    }
  }

  void _ensureExactlyOneTrailingBlank() {
    // Remove all trailing blank rows except one
    while (_rows.length > 1 && _rows[_rows.length - 1].isEmpty && _rows[_rows.length - 2].isEmpty) {
      _rows.removeLast();
    }
    // If the last row is not empty, append exactly one blank row
    if (_rows.isEmpty || !_rows.last.isEmpty) {
      _rows.add(_LinkEntry(no: _rows.length + 1));
    }
    _recalculateRowNumbers();
  }

  Future<void> _saveChanges() async {
    _ensureExactlyOneTrailingBlank();
    final jsonList = _rows.map((r) => r.toJson()).toList();
    final updatedContent = jsonEncode(jsonList);

    final updatedNote = widget.note.copyWith(
      content: updatedContent,
      updatedAt: DateTime.now(),
    );

    await ref.read(notesProvider.notifier).updateNote(updatedNote);
    setState(() => _hasUnsavedChanges = false);
  }

  Future<void> _openUrl(String rawUrl) async {
    String url = rawUrl.trim();
    if (url.isEmpty) return;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      AppleHaptics.lightImpact();
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot open URL: $rawUrl')),
        );
      }
    }
  }

  void _showEditRowModal(int index) {
    final entry = _rows[index];
    final linkCtrl = TextEditingController(text: entry.link);
    final nameCtrl = TextEditingController(text: entry.name);
    final descCtrl = TextEditingController(text: entry.description);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;

        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? BotanicalColors.darkSurface : BotanicalColors.lightSurface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(
                color: isDark ? BotanicalColors.darkBorder : BotanicalColors.lightBorder,
                width: 0.8,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? BotanicalColors.darkBorder : BotanicalColors.lightBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Row #${entry.no}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: linkCtrl,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Link URL',
                    hintText: 'https://example.com',
                    prefixIcon: Icon(CupertinoIcons.link, size: 18),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'Example Reference',
                    prefixIcon: Icon(CupertinoIcons.tag, size: 18),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Brief note about this site...',
                    prefixIcon: Icon(CupertinoIcons.doc_text, size: 18),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    if (!entry.isEmpty) ...[
                      TextButton.icon(
                        icon: const Icon(CupertinoIcons.trash, size: 16, color: BotanicalColors.lightError),
                        label: const Text('Delete', style: TextStyle(color: BotanicalColors.lightError)),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          setState(() {
                            _rows.removeAt(index);
                            _ensureExactlyOneTrailingBlank();
                            _hasUnsavedChanges = true;
                          });
                          _saveChanges();
                        },
                      ),
                      const Spacer(),
                    ] else
                      const Spacer(),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          entry.link = linkCtrl.text.trim();
                          entry.name = nameCtrl.text.trim();
                          entry.description = descCtrl.text.trim();
                          _ensureExactlyOneTrailingBlank();
                          _hasUnsavedChanges = true;
                        });
                        Navigator.of(ctx).pop();
                        _saveChanges();
                      },
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? BotanicalColors.darkPrimary : BotanicalColors.lightPrimary;
    final borderColor = isDark ? BotanicalColors.darkBorder : BotanicalColors.lightBorder;
    final surfaceColor = isDark ? BotanicalColors.darkSurface : BotanicalColors.lightSurface;

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: BoxDecoration(
        color: isDark ? BotanicalColors.darkBackground : BotanicalColors.lightBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: borderColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(CupertinoIcons.link_circle_fill, size: 26, color: primaryColor),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Links Table',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                            ),
                            Text(
                              '${_rows.where((r) => !r.isEmpty).length} saved links · Auto-advancing row',
                              style: TextStyle(
                                fontSize: 11,
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
                      onPressed: () {
                        if (_hasUnsavedChanges) _saveChanges();
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 0.5),

          // Table Header
          Container(
            color: surfaceColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: const Row(
              children: [
                SizedBox(width: 36, child: Text('No.', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                Expanded(flex: 3, child: Text('Link', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                Expanded(flex: 3, child: Text('Name', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                Expanded(flex: 3, child: Text('Description', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                SizedBox(width: 36),
              ],
            ),
          ),
          const Divider(height: 0.5),

          // Table Rows List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 40),
              itemCount: _rows.length,
              separatorBuilder: (_, __) => Divider(height: 0.5, color: borderColor),
              itemBuilder: (context, index) {
                final entry = _rows[index];
                final isBlank = entry.isEmpty;

                return InkWell(
                  onTap: () => _showEditRowModal(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: isBlank
                        ? (isDark ? BotanicalColors.darkSecondarySurface.withValues(alpha: 0.3) : const Color(0xFFFAF9FC))
                        : surfaceColor,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // No.
                        SizedBox(
                          width: 36,
                          child: Text(
                            '${entry.no}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark ? BotanicalColors.darkTextSecondary : BotanicalColors.lightTextSecondary,
                            ),
                          ),
                        ),

                        // Link
                        Expanded(
                          flex: 3,
                          child: InkWell(
                            onTap: isBlank ? null : () => _openUrl(entry.link),
                            child: Text(
                              isBlank ? 'Empty' : entry.link,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: isBlank
                                    ? CupertinoColors.systemGrey
                                    : (isDark ? BotanicalColors.darkPrimary : BotanicalColors.lightPrimary),
                                decoration: isBlank ? null : TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Name
                        Expanded(
                          flex: 3,
                          child: Text(
                            isBlank ? 'Empty' : entry.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isBlank ? FontWeight.normal : FontWeight.w600,
                              color: isBlank ? CupertinoColors.systemGrey : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Description
                        Expanded(
                          flex: 3,
                          child: Text(
                            isBlank ? 'Empty' : entry.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: isBlank ? CupertinoColors.systemGrey : (isDark ? BotanicalColors.darkTextSecondary : BotanicalColors.lightTextSecondary),
                            ),
                          ),
                        ),

                        // Action Icon (Edit / Open)
                        SizedBox(
                          width: 36,
                          child: IconButton(
                            icon: Icon(
                              isBlank ? CupertinoIcons.plus_circle : CupertinoIcons.pencil,
                              size: 16,
                              color: primaryColor,
                            ),
                            padding: EdgeInsets.zero,
                            onPressed: () => _showEditRowModal(index),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
