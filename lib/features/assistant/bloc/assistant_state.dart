part of 'assistant_cubit.dart';

enum AssistantStatus {
  idle,
  listening,
  recognized,
  uploading,
  responding,
  playing,
  mapLaunching,
  error,
}

class AssistantState extends Equatable {
  const AssistantState({
    this.status = AssistantStatus.idle,
    this.transcript = '',
    this.response = '',
    this.recordingPath = '',
    this.conversationId = '',
    this.messages = const [],
    this.replyAudioPath = '',
    this.errorMessage,
    this.lastCommand,
  });

  final AssistantStatus status;
  final String transcript;
  final String response;
  final String recordingPath;
  final String conversationId;
  final List<ChatMessage> messages;
  final String replyAudioPath;
  final String? errorMessage;
  final MapsCommand? lastCommand;

  bool get isListening => status == AssistantStatus.listening;
  bool get hasMessages => messages.isNotEmpty;

  AssistantState copyWith({
    AssistantStatus? status,
    String? transcript,
    String? response,
    String? recordingPath,
    String? conversationId,
    List<ChatMessage>? messages,
    String? replyAudioPath,
    String? errorMessage,
    MapsCommand? lastCommand,
    bool clearError = false,
  }) {
    return AssistantState(
      status: status ?? this.status,
      transcript: transcript ?? this.transcript,
      response: response ?? this.response,
      recordingPath: recordingPath ?? this.recordingPath,
      conversationId: conversationId ?? this.conversationId,
      messages: messages ?? this.messages,
      replyAudioPath: replyAudioPath ?? this.replyAudioPath,
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
    conversationId,
    messages,
    replyAudioPath,
    errorMessage,
    lastCommand,
  ];
}
