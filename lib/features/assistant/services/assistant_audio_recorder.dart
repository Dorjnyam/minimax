import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

abstract interface class AssistantAudioRecorder {
  Future<String?> start();
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

  @override
  Future<void> dispose() => _recorder.dispose();

  Future<Directory> _recordingsDirectory() async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory('${root.path}${Platform.pathSeparator}recordings');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}
