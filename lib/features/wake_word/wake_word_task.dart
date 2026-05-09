import 'dart:async';
import 'dart:convert';

import 'package:flutter_foreground_task/flutter_foreground_task.dart'
    hide NotificationVisibility;
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:porcupine_flutter/porcupine_error.dart';
import 'package:porcupine_flutter/porcupine_manager.dart';

import '../../shared/constants/baigalaa_constants.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(BaigalaaWakeTaskHandler());
}

class BaigalaaWakeTaskHandler extends TaskHandler {
  PorcupineManager? _porcupineManager;
  bool _isPaused = false;
  bool _isOpeningOverlay = false;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    await _startWakeWordEngine();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    await _deletePorcupine();
  }

  @override
  void onReceiveData(Object data) {
    unawaited(_handleCommand(data));
  }

  @override
  void onNotificationButtonPressed(String id) {
    if (id == 'open') {
      FlutterForegroundTask.launchApp();
    }
    if (id == 'stop') {
      unawaited(FlutterForegroundTask.stopService());
    }
  }

  Future<void> _startWakeWordEngine() async {
    try {
      final accessKey = await FlutterForegroundTask.getData<String>(
        key: taskAccessKeyKey,
      );
      final keywordPathsJson = await FlutterForegroundTask.getData<String>(
        key: taskKeywordPathsKey,
      );
      final keywordPaths = _decodeKeywordPaths(keywordPathsJson);

      if (accessKey == null || accessKey.trim().isEmpty) {
        await _publishError('Picovoice AccessKey is missing.');
        return;
      }
      if (keywordPaths.isEmpty) {
        await _publishError('No Baigalaa wake-word .ppn assets were found.');
        return;
      }

      await _deletePorcupine();
      _porcupineManager = await PorcupineManager.fromKeywordPaths(
        accessKey.trim(),
        keywordPaths,
        _onWakeWord,
        sensitivities: List<double>.filled(keywordPaths.length, 0.65),
        errorCallback: (PorcupineException error) {
          unawaited(_publishError(error.message ?? error.toString()));
        },
      );
      await _porcupineManager!.start();
      _isPaused = false;
      await _publishStatus('Listening for configured wake word');
    } catch (error) {
      await _publishError('Wake engine failed: $error');
    }
  }

  List<String> _decodeKeywordPaths(String? value) {
    if (value == null || value.isEmpty) {
      return const [];
    }
    final decoded = jsonDecode(value);
    return decoded is List ? decoded.whereType<String>().toList() : const [];
  }

  void _onWakeWord(int keywordIndex) {
    if (_isPaused || _isOpeningOverlay) {
      return;
    }
    unawaited(_openAssistantOverlay(keywordIndex));
  }

  Future<void> _openAssistantOverlay(int keywordIndex) async {
    _isOpeningOverlay = true;
    _isPaused = true;
    try {
      await _porcupineManager?.stop();
      await FlutterForegroundTask.updateService(
        notificationTitle: 'Baigalaa is awake',
        notificationText: 'Listening in the floating assistant',
      );
      FlutterForegroundTask.sendDataToMain({
        'event': eventWake,
        'keywordIndex': keywordIndex,
      });

      if (!await FlutterOverlayWindow.isActive()) {
        await FlutterOverlayWindow.showOverlay(
          width: WindowSize.matchParent,
          height: overlayHeight,
          alignment: OverlayAlignment.bottomCenter,
          flag: OverlayFlag.defaultFlag,
          visibility: NotificationVisibility.visibilityPrivate,
          overlayTitle: 'Baigalaa assistant',
          overlayContent: 'Listening for a short command',
          enableDrag: false,
          positionGravity: PositionGravity.none,
        );
      }

      await FlutterOverlayWindow.shareData({
        'event': eventWake,
        'keywordIndex': keywordIndex,
        'startedAt': DateTime.now().toIso8601String(),
      });
    } catch (error) {
      await _publishError('Could not open overlay: $error');
      await _resumeListening();
    } finally {
      _isOpeningOverlay = false;
    }
  }

  Future<void> _handleCommand(Object data) async {
    final command = data is String
        ? data
        : data is Map && data['command'] is String
        ? data['command'] as String
        : null;
    if (command == cmdPause) {
      await _pauseListening();
    } else if (command == cmdResume) {
      await _resumeListening();
    } else if (command == cmdShowOverlay) {
      await _openAssistantOverlay(-1);
    }
  }

  Future<void> _pauseListening() async {
    _isPaused = true;
    await _porcupineManager?.stop();
    await _publishStatus('Paused while assistant overlay is active');
  }

  Future<void> _resumeListening() async {
    if (_porcupineManager == null) {
      await _startWakeWordEngine();
      return;
    }
    try {
      if (!_isPaused) {
        return;
      }
      await _porcupineManager!.start();
      _isPaused = false;
      await _publishStatus('Listening for configured wake word');
    } catch (error) {
      await _publishError('Could not resume listening: $error');
    }
  }

  Future<void> _deletePorcupine() async {
    final manager = _porcupineManager;
    _porcupineManager = null;
    if (manager != null) {
      await manager.delete();
    }
  }

  Future<void> _publishStatus(String message) async {
    await FlutterForegroundTask.updateService(
      notificationTitle: 'Baigalaa is listening',
      notificationText: message,
    );
    FlutterForegroundTask.sendDataToMain({
      'event': eventStatus,
      'message': message,
    });
  }

  Future<void> _publishError(String message) async {
    await FlutterForegroundTask.updateService(
      notificationTitle: 'Baigalaa needs attention',
      notificationText: message,
    );
    FlutterForegroundTask.sendDataToMain({
      'event': eventError,
      'message': message,
    });
  }
}
