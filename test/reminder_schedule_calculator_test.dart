import 'package:flutter_test/flutter_test.dart';
import 'package:minimax/features/reminders/domain/reminder.dart';
import 'package:minimax/features/reminders/domain/reminder_schedule_calculator.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(() {
    tzdata.initializeTimeZones();
  });

  test('nextFire uses next_run_at when in future', () {
    const calc = ReminderScheduleCalculator();
    final loc = tz.getLocation('Asia/Ulaanbaatar');
    final now = tz.TZDateTime(loc, 2026, 5, 9, 8, 0);
    final r = Reminder.fromJson({
      'id': '1',
      'title': 't',
      'notes': '',
      'timezone': 'Asia/Ulaanbaatar',
      'recurrence': 'daily',
      'schedule_time': '07:00',
      'next_run_at': '2026-05-10T15:00:00.000Z',
      'status': 'open',
      'completed': false,
    });
    final next = calc.nextFire(reminder: r, now: now);
    expect(next, isNotNull);
    expect(next!.millisecondsSinceEpoch >= now.millisecondsSinceEpoch, isTrue);
  });

  test('nextFire daily picks schedule_time tomorrow when passed today', () {
    const calc = ReminderScheduleCalculator();
    final loc = tz.getLocation('Asia/Ulaanbaatar');
    final now = tz.TZDateTime(loc, 2026, 5, 9, 18, 0);
    final r = Reminder.fromJson({
      'id': '2',
      'title': 't',
      'notes': '',
      'timezone': 'Asia/Ulaanbaatar',
      'recurrence': 'daily',
      'schedule_time': '07:00',
      'status': 'open',
      'completed': false,
    });
    final next = calc.nextFire(reminder: r, now: now);
    expect(next, isNotNull);
    expect(next!.hour, 7);
    expect(next.day >= now.day, isTrue);
  });
}
