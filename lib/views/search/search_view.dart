import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/colors.dart';
import '../../models/event.dart';
import '../../models/note.dart';
import '../../models/reminder.dart';
import '../../models/task.dart';
import '../../providers/providers.dart';
import '../../widgets/apple_widgets.dart';
import '../../widgets/botanical_icons.dart';
import '../../widgets/event_editor_sheet.dart';
import '../../widgets/note_editor_sheet.dart';
import '../../widgets/reminder_editor_sheet.dart';
import '../../widgets/task_editor_sheet.dart';

enum SearchCategory { all, tasks, notes, events, reminders }

class SearchView extends ConsumerStatefulWidget {
  const SearchView({super.key});

  @override
  ConsumerState<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends ConsumerState<SearchView> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  SearchCategory _category = SearchCategory.all;
  final List<String> _recentSearches = ['Botanical', 'Walk', 'Sprint', 'Reflections'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(tasksProvider);
    final notes = ref.watch(notesProvider);
    final events = ref.watch(eventsProvider);
    final reminders = ref.watch(remindersProvider);

    final q = _query.toLowerCase();

    // Results
    final matchedTasks = _query.isEmpty
        ? <Task>[]
        : tasks.where((t) {
            return t.title.toLowerCase().contains(q) ||
                (t.description?.toLowerCase().contains(q) ?? false) ||
                t.category.toLowerCase().contains(q);
          }).toList();

    final matchedNotes = _query.isEmpty
        ? <Note>[]
        : notes.where((n) {
            return n.title.toLowerCase().contains(q) ||
                n.content.toLowerCase().contains(q) ||
                n.tags.any((tag) => tag.toLowerCase().contains(q));
          }).toList();

    final matchedEvents = _query.isEmpty
        ? <CalendarEvent>[]
        : events.where((e) {
            return e.title.toLowerCase().contains(q) ||
                (e.description?.toLowerCase().contains(q) ?? false) ||
                (e.location?.toLowerCase().contains(q) ?? false);
          }).toList();

    final matchedReminders = _query.isEmpty
        ? <Reminder>[]
        : reminders.where((r) {
            return r.title.toLowerCase().contains(q);
          }).toList();

    final totalCount = (_category == SearchCategory.all || _category == SearchCategory.tasks ? matchedTasks.length : 0) +
        (_category == SearchCategory.all || _category == SearchCategory.notes ? matchedNotes.length : 0) +
        (_category == SearchCategory.all || _category == SearchCategory.events ? matchedEvents.length : 0) +
        (_category == SearchCategory.all || _category == SearchCategory.reminders ? matchedReminders.length : 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Apple Native Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: AppleSearchField(
                controller: _searchController,
                placeholder: 'Search tasks, notes, events, reminders...',
                onChanged: (val) => setState(() => _query = val.trim()),
                onClear: () => setState(() => _query = ''),
              ),
            ),

            // Apple Scope Bar (Segmented Scope Filters)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  _buildScopePill('All', SearchCategory.all),
                  const SizedBox(width: 8),
                  _buildScopePill('Tasks (${matchedTasks.length})', SearchCategory.tasks),
                  const SizedBox(width: 8),
                  _buildScopePill('Notes (${matchedNotes.length})', SearchCategory.notes),
                  const SizedBox(width: 8),
                  _buildScopePill('Events (${matchedEvents.length})', SearchCategory.events),
                  const SizedBox(width: 8),
                  _buildScopePill('Reminders (${matchedReminders.length})', SearchCategory.reminders),
                ],
              ),
            ),
            const SizedBox(height: 6),
            const Divider(height: 0.5),

            Expanded(
              child: _query.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AppleSectionHeader('Recent Searches', padding: EdgeInsets.only(bottom: 12)),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _recentSearches.map((term) {
                              return ActionChip(
                                label: Text(term),
                                avatar: const Icon(CupertinoIcons.search, size: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                                onPressed: () {
                                  AppleHaptics.selection();
                                  _searchController.text = term;
                                  setState(() => _query = term);
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    )
                  : totalCount == 0
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(CupertinoIcons.search, size: 38, color: CupertinoColors.systemGrey3),
                              const SizedBox(height: 12),
                              Text(
                                'No results found for "$_query"',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(color: CupertinoColors.systemGrey),
                              ),
                            ],
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                          children: [
                            if ((_category == SearchCategory.all || _category == SearchCategory.tasks) &&
                                matchedTasks.isNotEmpty) ...[
                              AppleSectionHeader('Tasks (${matchedTasks.length})'),
                              AppleGroupedCard(
                                children: matchedTasks.map((t) {
                                  return AppleListTile(
                                    icon: BotanicalIcons.tasks,
                                    iconColor: BotanicalColors.lightPrimary,
                                    title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                                    subtitle: t.dueDate != null
                                        ? Text('Due: ${DateFormat('d MMM').format(t.dueDate!)}', style: const TextStyle(fontSize: 12))
                                        : null,
                                    onTap: () => TaskEditorSheet.show(context, task: t),
                                  );
                                }).toList(),
                              ),
                            ],
                            if ((_category == SearchCategory.all || _category == SearchCategory.notes) &&
                                matchedNotes.isNotEmpty) ...[
                              AppleSectionHeader('Notes (${matchedNotes.length})'),
                              AppleGroupedCard(
                                children: matchedNotes.map((n) {
                                  return AppleListTile(
                                    icon: BotanicalIcons.notes,
                                    iconColor: const Color(0xFF8A6C48),
                                    title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                                    subtitle: Text(n.content, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                                    onTap: () => NoteEditorSheet.show(context, note: n),
                                  );
                                }).toList(),
                              ),
                            ],
                            if ((_category == SearchCategory.all || _category == SearchCategory.events) &&
                                matchedEvents.isNotEmpty) ...[
                              AppleSectionHeader('Events (${matchedEvents.length})'),
                              AppleGroupedCard(
                                children: matchedEvents.map((e) {
                                  return AppleListTile(
                                    icon: BotanicalIcons.calendar,
                                    iconColor: const Color(0xFF328A6E),
                                    title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                                    subtitle: Text(DateFormat('d MMM, h:mm a').format(e.startTime), style: const TextStyle(fontSize: 12)),
                                    onTap: () => EventEditorSheet.show(context, event: e),
                                  );
                                }).toList(),
                              ),
                            ],
                            if ((_category == SearchCategory.all || _category == SearchCategory.reminders) &&
                                matchedReminders.isNotEmpty) ...[
                              AppleSectionHeader('Reminders (${matchedReminders.length})'),
                              AppleGroupedCard(
                                children: matchedReminders.map((r) {
                                  return AppleListTile(
                                    icon: BotanicalIcons.reminder,
                                    iconColor: BotanicalColors.lightAccent,
                                    title: Text(r.title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                                    subtitle: Text(DateFormat('d MMM, h:mm a').format(r.scheduledAt), style: const TextStyle(fontSize: 12)),
                                    onTap: () => ReminderEditorSheet.show(context, reminder: r),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScopePill(String label, SearchCategory cat) {
    final isSelected = _category == cat;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? BotanicalColors.darkPrimary : BotanicalColors.lightPrimary;

    return Semantics(
      selected: isSelected,
      child: InkWell(
        onTap: () {
          AppleHaptics.selection();
          setState(() => _category = cat);
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor
                : (isDark ? BotanicalColors.darkSecondarySurface : BotanicalColors.lightSecondarySurface),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : (isDark ? BotanicalColors.darkTextPrimary : BotanicalColors.lightTextPrimary),
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
