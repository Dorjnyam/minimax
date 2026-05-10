import 'package:timezone/timezone.dart' as tz;

import 'reminder.dart';

/// Computes the next fire instant for local notifications (timezone-aware).
class ReminderScheduleCalculator {
  const ReminderScheduleCalculator();

  tz.Location locationFor(Reminder r) {
    try {
      return tz.getLocation(r.timezone);
    } catch (_) {
      return tz.getLocation('Asia/Ulaanbaatar');
    }
  }

  /// Next schedule instant strictly after [now] (location clock), or null if unknown.
  tz.TZDateTime? nextFire({
    required Reminder reminder,
    required tz.TZDateTime now,
  }) {
    final loc = locationFor(reminder);

    if (reminder.nextRunAt != null) {
      final utc = reminder.nextRunAt!.toUtc();
      final atLoc = tz.TZDateTime.fromMillisecondsSinceEpoch(
        loc,
        utc.millisecondsSinceEpoch,
      );
      if (!atLoc.isBefore(now)) {
        return atLoc;
      }
      if (_isDaily(reminder.recurrence)) {
        return _nextDailyFromScheduleTime(reminder.scheduleTime, loc, now);
      }
      return null;
    }

    if (_isDaily(reminder.recurrence)) {
      return _nextDailyFromScheduleTime(reminder.scheduleTime, loc, now);
    }

    return null;
  }

  bool _isDaily(String recurrence) =>
      recurrence.toLowerCase() == 'daily' ||
      recurrence.toLowerCase().contains('day');

  tz.TZDateTime? _nextDailyFromScheduleTime(
    String? scheduleTime,
    tz.Location loc,
    tz.TZDateTime now,
  ) {
    final parts = _parseHHmm(scheduleTime);
    if (parts == null) return null;
    final hour = parts.$1;
    final minute = parts.$2;

    var candidate = tz.TZDateTime(
      loc,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!candidate.isAfter(now)) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }

  /// Returns (hour, minute) or null if missing/invalid.
  (int, int)? _parseHHmm(String? scheduleTime) {
    if (scheduleTime == null || scheduleTime.trim().isEmpty) {
      return (9, 0);
    }
    final segs = scheduleTime.trim().split(':');
    if (segs.length < 2) return null;
    final h = int.tryParse(segs[0].trim());
    final m = int.tryParse(segs[1].trim());
    if (h == null || m == null) return null;
    if (h < 0 || h > 23 || m < 0 || m > 59) return null;
    return (h, m);
  }
}
