import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart'
    hide NotificationVisibility;
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../shared/constants/baigalaa_constants.dart';
import '../../wake_word/wake_word_task.dart';
import 'widgets/setup_widgets.dart';

class BaigalaaSetupPage extends StatefulWidget {
  const BaigalaaSetupPage({super.key});

  @override
  State<BaigalaaSetupPage> createState() => _BaigalaaSetupPageState();
}

class _BaigalaaSetupPageState extends State<BaigalaaSetupPage> {
  static const _secureStorage = FlutterSecureStorage();

  final _accessKeyController = TextEditingController();
  final _taskLog = <String>[];

  bool _isLoading = true;
  bool _isBusy = false;
  bool _isAndroid = false;
  bool _serviceRunning = false;
  bool _microphoneGranted = false;
  bool _notificationGranted = false;
  bool _overlayGranted = false;
  List<String> _availableWakeAssets = const [];
  String _statusMessage = 'Checking device state';

  bool get _canStart =>
      _isAndroid &&
      _microphoneGranted &&
      _notificationGranted &&
      _overlayGranted &&
      _availableWakeAssets.isNotEmpty &&
      _accessKeyController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    FlutterForegroundTask.addTaskDataCallback(_onTaskData);
    _initForegroundService();
    unawaited(_loadInitialState());
  }

  @override
  void dispose() {
    FlutterForegroundTask.removeTaskDataCallback(_onTaskData);
    _accessKeyController.dispose();
    super.dispose();
  }

  void _initForegroundService() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'baigalaa_wake_word',
        channelName: 'Baigalaa wake word',
        channelDescription: 'Shows while Baigalaa is listening for wake words.',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: false,
        allowAutoRestart: false,
        stopWithTask: false,
      ),
    );
  }

  Future<void> _loadInitialState() async {
    final isAndroid = !kIsWeb && Platform.isAndroid;
    String? accessKey;
    if (isAndroid) {
      try {
        accessKey = await _secureStorage.read(key: accessKeyStorageKey);
      } catch (_) {}
    }
    final wakeAssets = await _loadAvailableWakeAssets();
    if (!mounted) {
      return;
    }
    _accessKeyController.text = accessKey ?? '';
    setState(() {
      _isAndroid = isAndroid;
      _availableWakeAssets = wakeAssets;
    });
    await _refreshState();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<List<String>> _loadAvailableWakeAssets() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      return manifest
          .listAssets()
          .where(
            (asset) =>
                asset.startsWith(wakeWordAssetDirectory) &&
                asset.toLowerCase().endsWith('.ppn'),
          )
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<void> _refreshState() async {
    final isAndroid = !kIsWeb && Platform.isAndroid;
    var serviceRunning = false;
    var microphoneGranted = false;
    var notificationGranted = !isAndroid;
    var overlayGranted = !isAndroid;

    if (isAndroid) {
      try {
        serviceRunning = await FlutterForegroundTask.isRunningService;
        microphoneGranted = await Permission.microphone.isGranted;
        final notificationPermission =
            await FlutterForegroundTask.checkNotificationPermission();
        notificationGranted =
            notificationPermission == NotificationPermission.granted;
        overlayGranted = await FlutterOverlayWindow.isPermissionGranted();
      } catch (_) {}
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _isAndroid = isAndroid;
      _serviceRunning = serviceRunning;
      _microphoneGranted = microphoneGranted;
      _notificationGranted = notificationGranted;
      _overlayGranted = overlayGranted;
      _statusMessage = serviceRunning
          ? 'Wake listener is running'
          : 'Wake listener is stopped';
    });
  }

  Future<void> _requestPermissions() async {
    await _runBusy(() async {
      if (!_isAndroid) {
        _setStatus('Android is required for the floating overlay MVP.');
        return;
      }
      await Permission.microphone.request();
      final notificationPermission =
          await FlutterForegroundTask.checkNotificationPermission();
      if (notificationPermission != NotificationPermission.granted) {
        await FlutterForegroundTask.requestNotificationPermission();
      }
      if (!await FlutterOverlayWindow.isPermissionGranted()) {
        await FlutterOverlayWindow.requestPermission();
      }
      await _refreshState();
    });
  }

  Future<void> _startListening() async {
    await _runBusy(() async {
      await _refreshState();
      final accessKey = _accessKeyController.text.trim();
      if (accessKey.isEmpty) {
        _setStatus('Enter a Picovoice AccessKey.');
        return;
      }
      if (_availableWakeAssets.isEmpty) {
        _setStatus('Add Android .ppn files under assets/wake_words first.');
        return;
      }
      if (!_microphoneGranted || !_notificationGranted || !_overlayGranted) {
        _setStatus('Grant microphone, notification, and overlay permissions.');
        return;
      }

      await _secureStorage.write(key: accessKeyStorageKey, value: accessKey);
      await FlutterForegroundTask.saveData(
        key: taskAccessKeyKey,
        value: accessKey,
      );
      await FlutterForegroundTask.saveData(
        key: taskKeywordPathsKey,
        value: jsonEncode(_availableWakeAssets),
      );

      final result = _serviceRunning
          ? await FlutterForegroundTask.restartService()
          : await FlutterForegroundTask.startService(
              serviceId: 712,
              serviceTypes: const [ForegroundServiceTypes.microphone],
              notificationTitle: 'Baigalaa is listening',
              notificationText: 'Say your configured wake word',
              notificationButtons: const [
                NotificationButton(id: 'open', text: 'Open'),
                NotificationButton(id: 'stop', text: 'Stop'),
              ],
              callback: startCallback,
            );

      _handleServiceResult(result, successMessage: 'Wake listener started.');
      await _refreshState();
    });
  }

  Future<void> _stopListening() async {
    await _runBusy(() async {
      if (!await FlutterForegroundTask.isRunningService) {
        await _refreshState();
        return;
      }
      final result = await FlutterForegroundTask.stopService();
      _handleServiceResult(result, successMessage: 'Wake listener stopped.');
      await _refreshState();
    });
  }

  Future<void> _testOverlay() async {
    await _runBusy(() async {
      if (!_isAndroid) {
        _setStatus('Android is required for the floating overlay MVP.');
        return;
      }
      if (!await FlutterOverlayWindow.isPermissionGranted()) {
        _setStatus('Grant display-over-other-apps permission first.');
        await FlutterOverlayWindow.requestPermission();
        await _refreshState();
        return;
      }
      if (await FlutterForegroundTask.isRunningService) {
        FlutterForegroundTask.sendDataToTask({'command': cmdShowOverlay});
      } else {
        await FlutterOverlayWindow.showOverlay(
          width: WindowSize.matchParent,
          height: overlayHeight,
          alignment: OverlayAlignment.bottomCenter,
          flag: OverlayFlag.defaultFlag,
          visibility: NotificationVisibility.visibilityPrivate,
          overlayTitle: 'Baigalaa assistant',
          overlayContent: 'Test overlay',
          enableDrag: false,
          positionGravity: PositionGravity.none,
        );
      }
      _setStatus('Test overlay opened.');
    });
  }

  Future<void> _runBusy(Future<void> Function() action) async {
    if (_isBusy) {
      return;
    }
    setState(() => _isBusy = true);
    try {
      await action();
    } catch (error) {
      _setStatus('$error');
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  void _handleServiceResult(
    ServiceRequestResult result, {
    required String successMessage,
  }) {
    switch (result) {
      case ServiceRequestSuccess():
        _setStatus(successMessage);
      case ServiceRequestFailure(:final error):
        _setStatus('Foreground service failed: $error');
    }
  }

  void _onTaskData(Object data) {
    if (!mounted) {
      return;
    }
    _setStatus(_messageFromTaskData(data));
  }

  String _messageFromTaskData(Object data) {
    if (data is Map) {
      final message = data['message'];
      if (message is String) {
        return message;
      }
      if (data['event'] == eventWake) {
        return 'Wake word detected.';
      }
    }
    return data.toString();
  }

  void _setStatus(String message) {
    if (!mounted) {
      return;
    }
    setState(() {
      _statusMessage = message;
      _taskLog.insert(0, message);
      if (_taskLog.length > 5) {
        _taskLog.removeLast();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SetupHeader(serviceRunning: _serviceRunning),
          const SizedBox(height: 16),
          SetupStatusPanel(
            statusMessage: _statusMessage,
            isAndroid: _isAndroid,
            microphoneGranted: _microphoneGranted,
            notificationGranted: _notificationGranted,
            overlayGranted: _overlayGranted,
            wakeAssetCount: _availableWakeAssets.length,
          ),
          const SizedBox(height: 16),
          AccessKeyPanel(
            controller: _accessKeyController,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          SetupActionPanel(
            isBusy: _isBusy,
            serviceRunning: _serviceRunning,
            canStart: _canStart,
            onRequestPermissions: _requestPermissions,
            onStart: _startListening,
            onStop: _stopListening,
            onTestOverlay: _testOverlay,
            onRefresh: _refreshState,
          ),
          if (_availableWakeAssets.isEmpty) ...[
            const SizedBox(height: 16),
            const WakeAssetNotice(),
          ],
          if (_taskLog.isNotEmpty) ...[
            const SizedBox(height: 16),
            TaskLogPanel(entries: _taskLog),
          ],
        ],
      ),
    );
  }
}
