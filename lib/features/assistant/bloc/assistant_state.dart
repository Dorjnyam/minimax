part of 'assistant_cubit.dart';

enum AssistantStatus {
  idle,
  listening,
  recognized,
  responding,
  mapLaunching,
  error,
}

class AssistantState extends Equatable {
  const AssistantState({
    this.status = AssistantStatus.idle,
    this.transcript = '',
    this.response = 'Turn on the air conditioner in the living room.',
    this.recordingPath = '',
    this.errorMessage,
    this.lastCommand,
  });

  final AssistantStatus status;
  final String transcript;
  final String response;
  final String recordingPath;
  final String? errorMessage;
  final MapsCommand? lastCommand;

  bool get isListening => status == AssistantStatus.listening;

  AssistantState copyWith({
    AssistantStatus? status,
    String? transcript,
    String? response,
    String? recordingPath,
    String? errorMessage,
    MapsCommand? lastCommand,
    bool clearError = false,
  }) {
    return AssistantState(
      status: status ?? this.status,
      transcript: transcript ?? this.transcript,
      response: response ?? this.response,
      recordingPath: recordingPath ?? this.recordingPath,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      lastCommand: lastCommand ?? this.lastCommand,
    );
  }

  @override
  List<Object?> get props => [
        status,
        transcript,
        response,
        recordingPath,
        errorMessage,
        lastCommand,
      ];
}
