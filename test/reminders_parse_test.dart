import 'package:flutter_test/flutter_test.dart';
import 'package:minimax/features/reminders/domain/reminder.dart';

void main() {
  test('Reminder.fromJson maps API sample', () {
    final r = Reminder.fromJson({
      'id': '69ffbc402489b1a28dede589',
      'title': 'Өглөөний майлны эмхтгэл шалгах',
      'notes': 'Өглөө бүр 07:00-д',
      'due_at': null,
      'timezone': 'Asia/Ulaanbaatar',
      'recurrence': 'daily',
      'schedule_time': '07:00',
      'next_run_at': '2026-05-09T23:00:00+00:00',
      'last_run_at': null,
      'status': 'open',
      'completed': false,
      'last_result': '',
      'last_error': '',
      'created_at': '2026-05-09T22:59:12.228000+00:00',
      'updated_at': '2026-05-09T22:59:12.228000+00:00',
    });
    expect(r.id, '69ffbc402489b1a28dede589');
    expect(r.scheduleTime, '07:00');
    expect(r.recurrence, 'daily');
    expect(r.nextRunAt?.toUtc().toIso8601String(), contains('2026-05-09'));
    expect(r.alertText, contains('Өглөөний'));
  });
}
