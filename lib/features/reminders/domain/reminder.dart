import 'package:equatable/equatable.dart';

/// Agent reminder row from GET `/api/v1/agents/reminders`.
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
      completed: json['completed'] == true,
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
