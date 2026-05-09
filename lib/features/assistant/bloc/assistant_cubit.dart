import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../shared/services/maps_launcher_service.dart';
import '../../../shared/services/user_location_service.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/data/auth_storage.dart';
import '../../auth/data/session_refresh_service.dart';
import '../../chat/data/chat_audio_playback_service.dart';
import '../../chat/data/chat_repository.dart';
import '../../chat/data/chat_voice_socket_service.dart';
import '../../chat/domain/chat_models.dart';
import '../data/assistant_repository.dart';
import '../domain/maps_command.dart';
import '../services/assistant_chat_service.dart';
import '../services/assistant_audio_recorder.dart';

part 'assistant_state.dart';

enum AssistantSuggestion {
  lights,
  airConditioner,
  myLocation,
  directions,
  coffeeNearMe,
}

class AssistantCubit extends Cubit<AssistantState> {
  AssistantCubit({
    required AssistantRepository repository,
    required MapsLauncherService mapsLauncher,
    MapsCommandParser parser = const MapsCommandParser(),
    AssistantAudioRecorder? audioRecorder,
    AssistantAudioRecorder Function()? audioRecorderFactory,
    AuthStorage authStorage = const SecureAuthStorage(),
    AccessTokenProvider? accessTokenProvider,
    ChatRepository? chatRepository,
    ChatVoiceSocketService? chatVoiceSocket,
    ChatAudioPlaybackService? chatAudioPlayback,
    UserLocationService? userLocationService,
    AssistantChatService? chatService,
  }) : _repository = repository,
       _mapsLauncher = mapsLauncher,
       _parser = parser,
       _audioRecorder = audioRecorder,
       _audioRecorderFactory =
           audioRecorderFactory ?? (() => M4aAssistantAudioRecorder()),
       _chatService =
           chatService ??
           AssistantChatService(
             authStorage: authStorage,
             accessTokenProvider: accessTokenProvider ??
                 SessionRefreshService(
                   repository: const AuthRepository(),
                   storage: authStorage,
                 ),
             chatRepository: chatRepository ?? const ChatRepository(),
             voiceSocket: chatVoiceSocket ?? const ChatVoiceSocketService(),
             audioPlayback: chatAudioPlayback ?? ChatAudioPlaybackService(),
             locationService:
                 userLocationService ?? UserLocationService(),
           ),
       super(const AssistantState());

  final AssistantRepository _repository;
  final MapsLauncherService _mapsLauncher;
  final MapsCommandParser _parser;
  AssistantAudioRecorder? _audioRecorder;
  final AssistantAudioRecorder Function() _audioRecorderFactory;
  final AssistantChatService _chatService;
  Timer? _listenTimeout;
  bool _responding = false;
  int _captureId = 0;
  String? _activeRecordingPath;

  Future<void> listen() async {
    if (state.isListening || _responding) {
      return;
    }

    final permission = await Permission.microphone.request();
    if (!permission.isGranted) {
      emit(
        state.copyWith(
          status: AssistantStatus.error,
          response: 'Microphone permission is required.',
          errorMessage: permission.isPermanentlyDenied
              ? 'Enable microphone permission in Android settings.'
              : 'Tap the mic and allow microphone access.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: AssistantStatus.listening,
        transcript: '',
        response: 'Recording... speak now.',
        recordingPath: '',
        clearError: true,
      ),
    );

    try {
      await _startRecording();
      _beginAutoStop();
      _listenTimeout = Timer(const Duration(seconds: 12), () {
        if (state.isListening) {
          unawaited(_handleRecognizedText(state.transcript));
        }
      });
    } catch (error) {
      await _stopRecording();
      emit(
        state.copyWith(
          status: AssistantStatus.error,
          response: 'Could not access the microphone.',
          errorMessage: '$error',
        ),
      );
    }
  }

  Future<void> submitText(String text, {String? recordingPath}) {
    if (recordingPath != null && recordingPath.isNotEmpty) {
      _activeRecordingPath = recordingPath;
    }
    return _handleRecognizedText(text);
  }

  Future<void> loadMessages() async {
    try {
      final result = await _chatService.loadMessages(state.conversationId);
      emit(
        state.copyWith(
          conversationId: result.conversationId,
          messages: result.messages,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(state.copyWith(errorMessage: '$error'));
    }
  }

  Future<void> runSuggestion(AssistantSuggestion suggestion) {
    final text = switch (suggestion) {
      AssistantSuggestion.lights => 'Turn off the light',
      AssistantSuggestion.airConditioner =>
        'Turn on the air conditioner in the living room',
      AssistantSuggestion.myLocation => 'show my location',
      AssistantSuggestion.directions => 'directions to Sukhbaatar Square',
      AssistantSuggestion.coffeeNearMe => 'search coffee near me',
    };
    return _handleRecognizedText(text);
  }

  /// Typed message from the home composer: same socket as voice, `user_message` JSON body.
  Future<void> sendUserTypedMessage(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty) return;

    final command = _parser.parse(text);
    if (command != null) {
      await _launchMapCommand(command);
      return;
    }

    await _respondWithChatText(text);
  }

  Future<void> _handleRecognizedText(String rawText) async {
    if (_responding) return;
    _responding = true;
    _captureId++;
    _listenTimeout?.cancel();

    final text = rawText.trim();
    final hadActiveRecording = _activeRecordingPath != null;
    final recordingPath = await _stopRecording();
    final shouldSendAudio = hadActiveRecording && recordingPath.isNotEmpty;

    emit(
      state.copyWith(
        status: AssistantStatus.recognized,
        transcript: text,
        response: text.isEmpty ? "I didn't catch that. Try again." : text,
        recordingPath: recordingPath,
        clearError: true,
      ),
    );

    final command = _parser.parse(text);
    if (command != null) {
      await _launchMapCommand(command);
    } else if (shouldSendAudio) {
      await _respondWithChat(text, recordingPath);
    } else {
      await _respondWithMock(text);
    }
    _responding = false;
  }

  Future<void> _startRecording() async {
    try {
      final recorder = _audioRecorder ??= _audioRecorderFactory();
      _activeRecordingPath = await recorder.start();
      if (_activeRecordingPath != null) {
        emit(state.copyWith(recordingPath: _activeRecordingPath));
      }
    } catch (error) {
      emit(state.copyWith(errorMessage: 'Audio recording unavailable: $error'));
    }
  }

  void _beginAutoStop() {
    final recorder = _audioRecorder;
    if (recorder == null) return;
    final captureId = ++_captureId;
    unawaited(
      recorder.waitForSilence().then((_) {
        if (captureId == _captureId && state.isListening && !_responding) {
          unawaited(_handleRecognizedText(state.transcript));
        }
      }),
    );
  }

  Future<String> _stopRecording() async {
    try {
      final recorder = _audioRecorder;
      if (recorder == null) {
        return _activeRecordingPath ?? '';
      }
      final path = await recorder.stop();
      _activeRecordingPath = path ?? _activeRecordingPath;
      return _activeRecordingPath ?? '';
    } catch (_) {
      return _activeRecordingPath ?? '';
    }
  }

  Future<void> _launchMapCommand(MapsCommand command) async {
    emit(
      state.copyWith(
        status: AssistantStatus.mapLaunching,
        response: command.confirmation,
        lastCommand: command,
        clearError: true,
      ),
    );
    try {
      await _mapsLauncher.launch(command);
      emit(
        state.copyWith(
          status: AssistantStatus.idle,
          response: command.confirmation,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: AssistantStatus.error,
          response: 'Could not open Google Maps.',
          errorMessage: '$error',
        ),
      );
    }
  }

  Future<void> _respondWithMock(String text) async {
    emit(state.copyWith(status: AssistantStatus.responding));
    final reply = await _repository.replyTo(text);
    emit(state.copyWith(status: AssistantStatus.idle, response: reply.text));
  }

  Future<void> _respondWithChat(String text, String recordingPath) async {
    try {
      final context = await _chatService.prepare(state.conversationId);
      final userMessage = ChatMessage.local(
        conversationId: context.conversationId,
        role: 'user',
        content: text.isEmpty ? 'Voice message' : text,
      );
      emit(
        state.copyWith(
          status: AssistantStatus.uploading,
          conversationId: context.conversationId,
          messages: [...state.messages, userMessage],
          response: 'Sending voice message...',
          clearError: true,
        ),
      );

      final reply = await _chatService.sendAudio(
        context: context,
        audioPath: recordingPath,
      );
      var localAudioPath = '';
      if (reply.hasAudio) {
        emit(state.copyWith(status: AssistantStatus.playing));
        try {
          localAudioPath = reply.audioUrl.isNotEmpty
              ? await _chatService.playAudio(
                  context: context,
                  audioUrl: reply.audioUrl,
                )
              : await _chatService.playAudioResponse(reply);
        } catch (error) {
          emit(state.copyWith(errorMessage: 'Audio playback failed: $error'));
        }
      }

      String? mapsErr;
      final mapCmd = reply.mapsCommand;
      if (mapCmd != null) {
        emit(
          state.copyWith(
            status: AssistantStatus.mapLaunching,
            response: mapCmd.confirmation,
            lastCommand: mapCmd,
            clearError: true,
          ),
        );
        try {
          await _mapsLauncher.launch(mapCmd);
        } catch (error) {
          mapsErr = 'Could not open Google Maps: $error';
        }
      }

      final assistantText = reply.text.isEmpty
          ? 'Voice response received.'
          : reply.text;
      final assistantMessage = ChatMessage.local(
        conversationId: context.conversationId,
        role: 'assistant',
        content: assistantText,
      );
      final freshMessages = await _chatService.safeMessages(context);
      emit(
        state.copyWith(
          status: AssistantStatus.idle,
          response: assistantText,
          messages: freshMessages.isEmpty
              ? [...state.messages, assistantMessage]
              : freshMessages,
          replyAudioPath: localAudioPath,
          errorMessage: mapsErr ?? state.errorMessage,
          clearError: mapsErr == null && localAudioPath.isNotEmpty,
        ),
      );
    } catch (error) {
      final missingToken = error is StateError;
      emit(
        state.copyWith(
          status: AssistantStatus.error,
          response: missingToken
              ? 'Please log in again.'
              : 'Could not send voice message.',
          errorMessage: '$error',
        ),
      );
    }
  }

  Future<void> _respondWithChatText(String text) async {
    if (_responding) return;
    _responding = true;
    try {
      final context = await _chatService.prepare(state.conversationId);
      final userMessage = ChatMessage.local(
        conversationId: context.conversationId,
        role: 'user',
        content: text,
      );
      emit(
        state.copyWith(
          status: AssistantStatus.uploading,
          conversationId: context.conversationId,
          messages: [...state.messages, userMessage],
          transcript: text,
          response: 'Sending…',
          clearError: true,
        ),
      );

      final reply = await _chatService.sendUserText(
        context: context,
        content: text,
      );
      var localAudioPath = '';
      if (reply.hasAudio) {
        emit(state.copyWith(status: AssistantStatus.playing));
        try {
          localAudioPath = reply.audioUrl.isNotEmpty
              ? await _chatService.playAudio(
                  context: context,
                  audioUrl: reply.audioUrl,
                )
              : await _chatService.playAudioResponse(reply);
        } catch (error) {
          emit(state.copyWith(errorMessage: 'Audio playback failed: $error'));
        }
      }

      String? mapsErr;
      final mapCmd = reply.mapsCommand;
      if (mapCmd != null) {
        emit(
          state.copyWith(
            status: AssistantStatus.mapLaunching,
            response: mapCmd.confirmation,
            lastCommand: mapCmd,
            clearError: true,
          ),
        );
        try {
          await _mapsLauncher.launch(mapCmd);
        } catch (error) {
          mapsErr = 'Could not open Google Maps: $error';
        }
      }

      final assistantText =
          reply.text.isEmpty ? 'Received.' : reply.text;
      final assistantMessage = ChatMessage.local(
        conversationId: context.conversationId,
        role: 'assistant',
        content: assistantText,
      );
      final freshMessages = await _chatService.safeMessages(context);
      emit(
        state.copyWith(
          status: AssistantStatus.idle,
          response: assistantText,
          messages: freshMessages.isEmpty
              ? [...state.messages, assistantMessage]
              : freshMessages,
          replyAudioPath: localAudioPath,
          errorMessage: mapsErr ?? state.errorMessage,
          clearError: mapsErr == null && localAudioPath.isNotEmpty,
        ),
      );
    } catch (error) {
      final missingToken = error is StateError;
      emit(
        state.copyWith(
          status: AssistantStatus.error,
          response: missingToken
              ? 'Please log in again.'
              : 'Could not send message.',
          errorMessage: '$error',
        ),
      );
    } finally {
      _responding = false;
    }
  }

  @override
  Future<void> close() async {
    _captureId++;
    _listenTimeout?.cancel();
    final recorder = _audioRecorder;
    _audioRecorder = null;
    if (recorder != null) {
      await recorder.dispose();
    }
    return super.close();
  }
}
