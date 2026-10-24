import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../core/theme/colors.dart';
import '../models/event.dart';
import 'botanical_icons.dart';

class EventEditorSheet extends StatefulWidget {
  final CalendarEvent? initialEvent;
  final DateTime? prefilledDate;

  const EventEditorSheet({
    super.key,
    this.initialEvent,
    this.prefilledDate,
  });

  static Future<CalendarEvent?> show(BuildContext context, {CalendarEvent? event, DateTime? prefilledDate}) {
    return showModalBottomSheet<CalendarEvent>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => EventEditorSheet(
        initialEvent: event,
        prefilledDate: prefilledDate,
      ),
    );
  }

  @override
  State<EventEditorSheet> createState() => _EventEditorSheetState();
}

class _EventEditorSheetState extends State<EventEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;

  late DateTime _startDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  bool _isAllDay = false;
  String _colorTag = 'work';
  String? _recurrence;

  final List<String> _tags = ['work', 'personal', 'health', 'reading', 'home'];
  final List<String> _recurrenceOptions = ['None', 'Daily', 'Weekly', 'Monthly'];

  @override
  void initState() {
    super.initState();
    final event = widget.initialEvent;
    _titleController = TextEditingController(text: event?.title ?? '');
    _descriptionController = TextEditingController(text: event?.description ?? '');
    _locationController = TextEditingController(text: event?.location ?? '');

    _startDate = event?.startTime ?? widget.prefilledDate ?? DateTime.now();
    _startTime = event != null
        ? TimeOfDay(hour: event.startTime.hour, minute: event.startTime.minute)
        : const TimeOfDay(hour: 10, minute: 0);
    _endTime = event != null
        ? TimeOfDay(hour: event.endTime.hour, minute: event.endTime.minute)
        : const TimeOfDay(hour: 11, minute: 0);
    _isAllDay = event?.isAllDay ?? false;
    _colorTag = event?.colorTag ?? 'work';
    _recurrence = event?.recurrenceRule;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _saveEvent() {
    if (!_formKey.currentState!.validate()) return;

    final startDateTime = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _isAllDay ? 0 : _startTime.hour,
      _isAllDay ? 0 : _startTime.minute,
    );
    final endDateTime = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _isAllDay ? 23 : _endTime.hour,
      _isAllDay ? 59 : _endTime.minute,
    );

    final event = CalendarEvent(
      id: widget.initialEvent?.id ?? const Uuid().v4(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      startTime: startDateTime,
      endTime: endDateTime,
      isAllDay: _isAllDay,
      location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
      recurrenceRule: _recurrence == 'None' ? null : _recurrence,
      colorTag: _colorTag,
      createdAt: widget.initialEvent?.createdAt ?? DateTime.now(),
    );

    Navigator.of(context).pop(event);
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
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
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
                    widget.initialEvent == null ? 'New Event' : 'Edit Event',
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
              Expanded(
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      autofocus: widget.initialEvent == null,
                      style: Theme.of(context).textTheme.titleMedium,
                      decoration: const InputDecoration(
                        labelText: 'Event Title',
                        hintText: 'e.g. Design review, Doctor visit',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter an event title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Description (optional)',
                        hintText: 'Agenda, notes, or participants...',
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location / Link (optional)',
                        prefixIcon: Icon(BotanicalIcons.location, size: 18),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Date picker
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _startDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setState(() => _startDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            const Icon(BotanicalIcons.calendar, size: 18),
                            const SizedBox(width: 10),
                            Text(
                              DateFormat('EEEE, dd MMMM yyyy').format(_startDate),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // All Day switch
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('All Day Event'),
                      value: _isAllDay,
                      activeThumbColor: primaryColor,
                      onChanged: (val) => setState(() => _isAllDay = val),
                    ),

                    if (!_isAllDay) ...[
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: _startTime,
                                );
                                if (picked != null) {
                                  setState(() => _startTime = picked);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Start Time', style: Theme.of(context).textTheme.labelSmall),
                                    const SizedBox(height: 4),
                                    Text(_startTime.format(context), style: Theme.of(context).textTheme.bodyMedium),
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
                                  initialTime: _endTime,
                                );
                                if (picked != null) {
                                  setState(() => _endTime = picked);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('End Time', style: Theme.of(context).textTheme.labelSmall),
                                    const SizedBox(height: 4),
                                    Text(_endTime.format(context), style: Theme.of(context).textTheme.bodyMedium),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Tag
                    Text('Tag', style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _tags.map((tag) {
                        final isSelected = _colorTag == tag;
                        return ChoiceChip(
                          label: Text(tag[0].toUpperCase() + tag.substring(1)),
                          selected: isSelected,
                          selectedColor: primaryColor.withValues(alpha: 0.15),
                          labelStyle: TextStyle(
                            color: isSelected ? primaryColor : null,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                          side: BorderSide(
                            color: isSelected ? primaryColor : borderColor,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          onSelected: (val) {
                            if (val) setState(() => _colorTag = tag);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    DropdownButtonFormField<String>(
                      initialValue: _recurrence ?? 'None',
                      decoration: const InputDecoration(
                        labelText: 'Recurrence',
                        prefixIcon: Icon(BotanicalIcons.repeat, size: 18),
                      ),
                      items: _recurrenceOptions.map((opt) {
                        return DropdownMenuItem(value: opt, child: Text(opt));
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _recurrence = val);
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
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
                      onPressed: _saveEvent,
                      child: Text(widget.initialEvent == null ? 'Create Event' : 'Save Changes'),
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
