import 'package:equatable/equatable.dart';

import '../../domain/reminder.dart';

class RemindersState extends Equatable {
  const RemindersState({
    this.reminders = const [],
    this.filterStatus = 'open',
    this.pausedIds = const {},
    this.loading = false,
    this.errorMessage,
    this.creating = false,
  });

  final List<Reminder> reminders;
  final String filterStatus;
  final Set<String> pausedIds;
  final bool loading;
  final String? errorMessage;
  final bool creating;

  bool isLocallyPaused(String id) => pausedIds.contains(id);

  RemindersState copyWith({
    List<Reminder>? reminders,
    String? filterStatus,
    Set<String>? pausedIds,
    bool? loading,
    String? errorMessage,
    bool clearError = false,
    bool? creating,
  }) {
    return RemindersState(
      reminders: reminders ?? this.reminders,
      filterStatus: filterStatus ?? this.filterStatus,
      pausedIds: pausedIds ?? this.pausedIds,
      loading: loading ?? this.loading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      creating: creating ?? this.creating,
    );
  }

  @override
  List<Object?> get props => [
    reminders,
    filterStatus,
    pausedIds,
    loading,
    errorMessage,
    creating,
  ];
}
