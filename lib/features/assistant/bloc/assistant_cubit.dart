import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../shared/services/maps_launcher_service.dart';
import '../data/assistant_repository.dart';
import '../domain/maps_command.dart';
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
    stt.SpeechToText? speech,
    AssistantAudioRecorder? audioRecorder,
    AssistantAudioRecorder Function()? audioRecorderFactory,
  }) : _repository = repository,
       _mapsLauncher = mapsLauncher,
       _parser = parser,
       _speech = speech ?? stt.SpeechToText(),
       _audioRecorder = audioRecorder,
       _audioRecorderFactory =
           audioRecorderFactory ?? (() => M4aAssistantAudioRecorder()),
       super(const AssistantState());

  final AssistantRepository _repository;
  final MapsLauncherService _mapsLauncher;
  final MapsCommandParser _parser;
  final stt.SpeechToText _speech;
  AssistantAudioRecorder? _audioRecorder;
  final AssistantAudioRecorder Function() _audioRecorderFactory;
  Timer? _listenTimeout;
  bool _responding = false;
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
        response: 'Listening... speak now.',
        recordingPath: '',
        clearError: true,
      ),
    );

    try {
      await _startRecording();
      final available = await _speech.initialize(
        onStatus: _onSpeechStatus,
        onError: (error) => _handleRecognizedText(''),
        options: [stt.SpeechToText.androidNoBluetooth],
      );
      if (!available) {
        await _stopRecording();
        emit(
          state.copyWith(
            status: AssistantStatus.error,
            response: 'Speech recognition is unavailable.',
            errorMessage: 'Install or enable Google Speech Services.',
          ),
        );
        return;
      }

      await _speech.listen(
        listenFor: const Duration(seconds: 7),
        pauseFor: const Duration(seconds: 2),
        onResult: _onSpeechResult,
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          listenMode: stt.ListenMode.confirmation,
        ),
      );

      _listenTimeout = Timer(const Duration(seconds: 9), () {
        if (state.isListening) {
          unawaited(_handleRecognizedText(state.transcript));
        }
      });
    } catch (error) {
      await _stopRecording();
      emit(
        state.copyWith(
          status: AssistantStatus.error,
          response: 'Speech recognition is unavailable.',
          errorMessage: '$error',
        ),
      );
    }
  }

  Future<void> submitText(String text) {
    return _handleRecognizedText(text);
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

  void _onSpeechResult(SpeechRecognitionResult result) {
    emit(
      state.copyWith(
        transcript: result.recognizedWords,
        response: result.recognizedWords.isEmpty
            ? 'Listening... speak now.'
            : 'I can hear you.',
        status: AssistantStatus.listening,
      ),
    );
    if (result.finalResult) {
      unawaited(_handleRecognizedText(result.recognizedWords));
    }
  }

  void _onSpeechStatus(String status) {
    if ((status == stt.SpeechToText.doneStatus ||
            status == stt.SpeechToText.notListeningStatus) &&
        state.isListening) {
      unawaited(_handleRecognizedText(state.transcript));
    }
  }

  Future<void> _handleRecognizedText(String rawText) async {
    if (_responding) {
      return;
    }
    _responding = true;
    _listenTimeout?.cancel();

    final text = rawText.trim();
    final recordingPath = await _stopRecording();
    try {
      await _speech.stop();
    } catch (_) {}

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

  @override
  Future<void> close() {
    _listenTimeout?.cancel();
    unawaited(_speech.cancel());
    final recorder = _audioRecorder;
    if (recorder != null) {
      unawaited(recorder.dispose());
    }
    return super.close();
  }
}
