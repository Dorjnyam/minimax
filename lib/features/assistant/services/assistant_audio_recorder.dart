import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

abstract interface class AssistantAudioRecorder {
  Future<String?> start();
  Future<bool> waitForSilence({
    Duration minDuration = const Duration(milliseconds: 1200),
    Duration silenceDuration = const Duration(milliseconds: 1500),
    Duration maxDuration = const Duration(seconds: 12),
    double voiceThresholdDb = -45,
  });
  Future<String?> stop();
  Future<void> cancel();
  Future<void> dispose();
}

class M4aAssistantAudioRecorder implements AssistantAudioRecorder {
  M4aAssistantAudioRecorder({AudioRecorder? recorder})
    : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;
  String? _activePath;

  @override
  Future<String?> start() async {
    if (await _recorder.isRecording()) {
      return _activePath;
    }
    final supported = await _recorder.isEncoderSupported(AudioEncoder.aacLc);
    if (!supported) {
      return null;
    }
    final dir = await _recordingsDirectory();
    final path =
        '${dir.path}${Platform.pathSeparator}'
        'baigalaa_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
        numChannels: 1,
        noiseSuppress: true,
        echoCancel: true,
      ),
      path: path,
    );
    _activePath = path;
    return path;
  }

  @override
  Future<bool> waitForSilence({
    Duration minDuration = const Duration(milliseconds: 1200),
    Duration silenceDuration = const Duration(milliseconds: 1500),
    Duration maxDuration = const Duration(seconds: 12),
    double voiceThresholdDb = -45,
  }) async {
    final startedAt = DateTime.now();
    final completer = Completer<bool>();
    var heardVoice = false;
    Timer? silenceTimer;
    late final StreamSubscription subscription;
    final maxTimer = Timer(maxDuration, () {
      if (!completer.isCompleted) completer.complete(heardVoice);
    });

    subscription = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 200))
        .listen((amplitude) {
          if (completer.isCompleted) return;
          final elapsed = DateTime.now().difference(startedAt);
          if (amplitude.current > voiceThresholdDb) {
            heardVoice = true;
            silenceTimer?.cancel();
            silenceTimer = null;
          } else if (heardVoice &&
              elapsed >= minDuration &&
              silenceTimer == null) {
            silenceTimer = Timer(silenceDuration, () {
              if (!completer.isCompleted) completer.complete(true);
            });
          }
        });

    try {
      return await completer.future;
    } finally {
      maxTimer.cancel();
      silenceTimer?.cancel();
      await subscription.cancel();
    }
  }

  @override
  Future<String?> stop() async {
    if (!await _recorder.isRecording()) {
      return _activePath;
    }
    final path = await _recorder.stop();
    _activePath = path ?? _activePath;
    return _activePath;
  }

  @override
  Future<void> cancel() async {
    if (await _recorder.isRecording()) {
      await _recorder.cancel();
    }
    _activePath = null;
  }

  /// Completes a normal [stop] first so native teardown runs while the session
  /// is still considered active. Calling [AudioRecorder.dispose] directly can race
  /// the Android muxer (MPEG4Writer "Stop() called but track is not started").
  @override
  Future<void> dispose() async {
    await stop();
    await _recorder.dispose();
  }

  Future<Directory> _recordingsDirectory() async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory('${root.path}${Platform.pathSeparator}recordings');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}
