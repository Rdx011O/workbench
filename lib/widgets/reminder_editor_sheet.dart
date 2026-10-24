import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../core/theme/colors.dart';
import '../models/reminder.dart';
import 'botanical_icons.dart';

class ReminderEditorSheet extends StatefulWidget {
  final Reminder? initialReminder;
  final DateTime? prefilledDate;

  const ReminderEditorSheet({
    super.key,
    this.initialReminder,
    this.prefilledDate,
  });

  static Future<Reminder?> show(BuildContext context, {Reminder? reminder, DateTime? prefilledDate}) {
    return showModalBottomSheet<Reminder>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => ReminderEditorSheet(
        initialReminder: reminder,
        prefilledDate: prefilledDate,
      ),
    );
  }

  @override
  State<ReminderEditorSheet> createState() => _ReminderEditorSheetState();
}

class _ReminderEditorSheetState extends State<ReminderEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late DateTime _scheduledDate;
  late TimeOfDay _scheduledTime;
  String? _recurrence;

  final List<String> _recurrenceOptions = ['None', 'Daily', 'Weekdays', 'Weekly'];

  @override
  void initState() {
    super.initState();
    final reminder = widget.initialReminder;
    _titleController = TextEditingController(text: reminder?.title ?? '');
    _scheduledDate = reminder?.scheduledAt ?? widget.prefilledDate ?? DateTime.now();
    _scheduledTime = reminder != null
        ? TimeOfDay(hour: reminder.scheduledAt.hour, minute: reminder.scheduledAt.minute)
        : const TimeOfDay(hour: 14, minute: 0);
    _recurrence = reminder?.recurrenceRule;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _saveReminder() {
    if (!_formKey.currentState!.validate()) return;

    final targetDateTime = DateTime(
      _scheduledDate.year,
      _scheduledDate.month,
      _scheduledDate.day,
      _scheduledTime.hour,
      _scheduledTime.minute,
    );

    final reminder = Reminder(
      id: widget.initialReminder?.id ?? const Uuid().v4(),
      title: _titleController.text.trim(),
      scheduledAt: targetDateTime,
      isRecurring: _recurrence != null && _recurrence != 'None',
      recurrenceRule: _recurrence == 'None' ? null : _recurrence,
      isCompleted: widget.initialReminder?.isCompleted ?? false,
      snoozedUntil: widget.initialReminder?.snoozedUntil,
      createdAt: widget.initialReminder?.createdAt ?? DateTime.now(),
    );

    Navigator.of(context).pop(reminder);
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context).brightness == Brightness.dark
        ? BotanicalColors.darkBorder
        : BotanicalColors.lightBorder;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.initialReminder == null ? 'New Reminder' : 'Edit Reminder',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontFamily: 'DM Serif Display',
                        ),
                  ),
                  IconButton(
                    icon: const Icon(BotanicalIcons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _titleController,
                autofocus: widget.initialReminder == null,
                style: Theme.of(context).textTheme.titleMedium,
                decoration: const InputDecoration(
                  labelText: 'Reminder Name',
                  hintText: 'e.g. Drink water, Take vitamins, Call mom',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a reminder title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _scheduledDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setState(() => _scheduledDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            const Icon(BotanicalIcons.calendar, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                DateFormat('dd MMM').format(_scheduledDate),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _scheduledTime,
                        );
                        if (picked != null) {
                          setState(() => _scheduledTime = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            const Icon(BotanicalIcons.time, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _scheduledTime.format(context),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _recurrence ?? 'None',
                decoration: const InputDecoration(
                  labelText: 'Repeat',
                  prefixIcon: Icon(BotanicalIcons.repeat, size: 18),
                ),
                items: _recurrenceOptions.map((opt) {
                  return DropdownMenuItem(value: opt, child: Text(opt));
                }).toList(),
                onChanged: (val) {
                  setState(() => _recurrence = val);
                },
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _saveReminder,
                      child: Text(widget.initialReminder == null ? 'Set Reminder' : 'Save Changes'),
                    ),
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
