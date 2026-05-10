import 'package:flutter/material.dart';

import '../reminders_strings.dart';

/// Separate fields combined into one socket `user_message` on submit.
class ReminderCreateSheet extends StatefulWidget {
  const ReminderCreateSheet({
    super.key,
    required this.onSubmit,
    this.loading = false,
  });

  final Future<void> Function(String title, String notes, String scheduleHint)
  onSubmit;
  final bool loading;

  @override
  State<ReminderCreateSheet> createState() => _ReminderCreateSheetState();
}

class _ReminderCreateSheetState extends State<ReminderCreateSheet> {
  final _title = TextEditingController();
  final _notes = TextEditingController();
  final _schedule = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    _schedule.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              RemindersStrings.createTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _title,
              style: const TextStyle(color: Colors.white),
              decoration: _dec(RemindersStrings.fieldTitle),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              minLines: 2,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: _dec(RemindersStrings.fieldNotes),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _schedule,
              style: const TextStyle(color: Colors.white),
              decoration: _dec(
                '${RemindersStrings.fieldSchedule}\n${RemindersStrings.fieldScheduleHint}',
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.loading ? null : () => Navigator.pop(context),
                    child: Text(RemindersStrings.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: widget.loading
                        ? null
                        : () async {
                            final t = _title.text.trim();
                            if (t.isEmpty) return;
                            await widget.onSubmit(
                              t,
                              _notes.text.trim(),
                              _schedule.text.trim(),
                            );
                          },
                    child: Text(RemindersStrings.submitCreate),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _dec(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.28)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF5855B0)),
      ),
    );
  }
}
