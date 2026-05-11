import 'package:equatable/equatable.dart';

/// Agent reminder row from GET `/api/v1/agents/reminders` (no trailing slash on this API).
class Reminder extends Equatable {
  const Reminder({
    required this.id,
    required this.title,
    required this.notes,
    this.dueAt,
    required this.timezone,
    required this.recurrence,
    this.scheduleTime,
    this.nextRunAt,
    this.lastRunAt,
    required this.status,
    required this.completed,
    this.lastResult = '',
    this.lastError = '',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String notes;
  final DateTime? dueAt;
  final String timezone;
  final String recurrence;
  /// Local wall-clock time e.g. `"07:00"`.
  final String? scheduleTime;
  final DateTime? nextRunAt;
  final DateTime? lastRunAt;
  final String status;
  final bool completed;
  final String lastResult;
  final String lastError;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static DateTime? _parseDt(Object? v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  static bool _truthy(Object? v) {
    if (v == true) return true;
    if (v == false) return false;
    if (v is num) return v != 0;
    final s = v?.toString().trim().toLowerCase();
    return s == 'true' || s == '1' || s == 'yes';
  }

  /// Open tab: active, incomplete reminders.
  bool get matchesOpenTab => status == 'open' && !completed;

  /// Closed tab: completed or no longer open.
  bool get matchesClosedTab => completed || status != 'open';

  factory Reminder.fromJson(Map<String, Object?> json) {
    return Reminder(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      dueAt: _parseDt(json['due_at']),
      timezone: json['timezone']?.toString() ?? 'Asia/Ulaanbaatar',
      recurrence: json['recurrence']?.toString() ?? '',
      scheduleTime: json['schedule_time']?.toString(),
      nextRunAt: _parseDt(json['next_run_at']),
      lastRunAt: _parseDt(json['last_run_at']),
      status: json['status']?.toString() ?? 'open',
      completed: _truthy(json['completed']),
      lastResult: json['last_result']?.toString() ?? '',
      lastError: json['last_error']?.toString() ?? '',
      createdAt: _parseDt(json['created_at']),
      updatedAt: _parseDt(json['updated_at']),
    );
  }

  /// Line shown in notification / TTS (prefer title, fallback notes).
  String get alertText {
    final t = title.trim();
    if (t.isNotEmpty) return t;
    return notes.trim().isEmpty ? 'Сануулга' : notes.trim();
  }

  @override
  List<Object?> get props => [
    id,
    title,
    notes,
    dueAt,
    timezone,
    recurrence,
    scheduleTime,
    nextRunAt,
    lastRunAt,
    status,
    completed,
    lastResult,
    lastError,
    createdAt,
    updatedAt,
  ];
}
