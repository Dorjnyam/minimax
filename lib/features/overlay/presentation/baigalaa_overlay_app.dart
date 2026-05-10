import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart'
    hide NotificationVisibility;
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../assistant/presentation/widgets/assistant_controls.dart';
import '../../../shared/constants/baigalaa_constants.dart';
import '../../../shared/widgets/fixed_text_scale.dart';
import 'overlay_strings.dart';
import 'overlay_voice_session.dart';
import 'widgets/overlay_sheet_widgets.dart';

/// Shell isolate — brand navy; use opacity for see-through layers.
const Color _overlayChrome = Color(0xFF14233D);
const Color _overlayAccent = Color(0xFF5855B0);

/// Dim behind the sheet (underlying app shows through slightly).
const double _kBackdropOpacity = 0.48;

/// Card surface — readable but still a bit transparent.
const double _kPanelOpacity = 0.86;

class BaigalaaOverlayApp extends StatelessWidget {
  const BaigalaaOverlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: FixedTextScale.builder,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _overlayAccent,
          brightness: Brightness.dark,
          surface: _overlayChrome,
        ),
      ),
      home: const BaigalaaOverlayPage(),
    );
  }
}

class BaigalaaOverlayPage extends StatefulWidget {
  const BaigalaaOverlayPage({super.key});

  @override
  State<BaigalaaOverlayPage> createState() => _BaigalaaOverlayPageState();
}

class _BaigalaaOverlayPageState extends State<BaigalaaOverlayPage> {
  late final OverlayVoiceSession _voice;
  StreamSubscription<dynamic>? _overlaySubscription;

  Timer? _listenTimeout;
  int _captureId = 0;
  bool _listening = false;
  bool _responding = false;

  /// Idle | recording | uploading | playing (subtitle under title).
  String _phaseLabel = OverlayStrings.subtitleIdle;
  String _transcript = '';
  String _response = '';

  @override
  void initState() {
    super.initState();
    _voice = OverlayVoiceSession();
    FlutterForegroundTask.sendDataToTask({'command': cmdPause});
    _overlaySubscription = FlutterOverlayWindow.overlayListener.listen((_) {});
  }

  @override
  void dispose() {
    _listenTimeout?.cancel();
    _overlaySubscription?.cancel();
    unawaited(_voice.closeRecorder());
    super.dispose();
  }

  String _headlineText() {
    if (_listening) return OverlayStrings.recording;
    if (_transcript.isNotEmpty) return _transcript;
    if (_phaseLabel == OverlayStrings.uploading) {
      return OverlayStrings.voiceMessageLabel;
    }
    return OverlayStrings.hintIdle;
  }

  String _detailText() {
    if (_listening) return OverlayStrings.recordingSpeakNow;
    return _response;
  }

  void _beginAutoStop() {
    final captureId = ++_captureId;
    unawaited(
      _voice.recorder.waitForSilence().then((_) {
        if (captureId == _captureId && _listening && !_responding) {
          unawaited(_finalizePipeline());
        }
      }),
    );
  }

  Future<void> listen() async {
    if (_listening || _responding) return;

    final permission = await Permission.microphone.request();
    if (!permission.isGranted) {
      setState(() {
        _phaseLabel = OverlayStrings.subtitleIdle;
        _response = OverlayStrings.micDenied;
      });
      return;
    }

    setState(() {
      _listening = true;
      _phaseLabel = OverlayStrings.recording;
      _transcript = '';
      _response = OverlayStrings.recordingSpeakNow;
    });

    try {
      final path = await _voice.startRecording();
      if (path == null || path.isEmpty) {
        await _voice.cancelRecording();
        if (!mounted) return;
        setState(() {
          _listening = false;
          _phaseLabel = OverlayStrings.subtitleIdle;
          _response = OverlayStrings.recordFailed;
        });
        return;
      }

      _beginAutoStop();
      _listenTimeout = Timer(const Duration(seconds: 12), () {
        if (_listening && !_responding) {
          unawaited(_finalizePipeline());
        }
      });
    } catch (e) {
      await _voice.cancelRecording();
      if (!mounted) return;
      setState(() {
        _listening = false;
        _phaseLabel = OverlayStrings.subtitleIdle;
        _response = OverlayStrings.errorBrief(e);
      });
    }
  }

  Future<void> toggleListening() async {
    if (_responding) return;
    if (_listening) {
      _listenTimeout?.cancel();
      await _finalizePipeline();
      return;
    }
    await listen();
  }

  Future<void> cancelOrDismiss() async {
    if (_responding) return;
    if (_listening) {
      _listenTimeout?.cancel();
      await _finalizePipeline();
      return;
    }
    setState(() {
      _transcript = '';
      _response = '';
      _phaseLabel = OverlayStrings.subtitleIdle;
    });
  }

  Future<void> _finalizePipeline() async {
    if (_responding) return;
    _responding = true;
    _captureId++;
    _listenTimeout?.cancel();

    final path = await _voice.stopRecording();

    if (!mounted) {
      _responding = false;
      return;
    }

    setState(() {
      _listening = false;
    });

    if (path.isEmpty) {
      setState(() {
        _phaseLabel = OverlayStrings.subtitleIdle;
        _response = OverlayStrings.emptyRecording;
        _transcript = '';
      });
      _responding = false;
      return;
    }

    setState(() {
      _phaseLabel = OverlayStrings.uploading;
      _transcript = OverlayStrings.voiceMessageLabel;
      _response = '';
    });

    try {
      final bundle = await _voice.sendRecording(path).timeout(
        const Duration(seconds: 45),
        onTimeout: () =>
            throw TimeoutException('Илгээлт цаг хэтэрлээ.', const Duration(seconds: 45)),
      );
      final reply = bundle.reply;
      final ctx = bundle.context;

      final assistantText = reply.text.trim().isEmpty
          ? 'Хариу ирлээ.'
          : reply.text.trim();

      setState(() {
        _response = assistantText;
      });

      if (reply.hasAudio) {
        setState(() => _phaseLabel = OverlayStrings.playing);
        try {
          await _voice.playAssistantAudio(context: ctx, reply: reply);
        } catch (_) {
          if (mounted) {
            setState(() {
              _response = '$assistantText\n(Аудио тоглуулахад алдаа гарлаа.)';
            });
          }
        }
      }

      if (mounted) {
        setState(() {
          _phaseLabel = OverlayStrings.subtitleIdle;
          _transcript = '';
        });
      }
    } on StateError catch (e) {
      if (mounted) {
        final login =
            e.message.contains('log in') || e.message.contains('Please log');
        setState(() {
          _phaseLabel = OverlayStrings.subtitleIdle;
          _transcript = '';
          _response =
              login ? OverlayStrings.loginRequired : OverlayStrings.errorBrief(e);
        });
      }
    } on TimeoutException catch (e) {
      if (mounted) {
        setState(() {
          _phaseLabel = OverlayStrings.subtitleIdle;
          _transcript = '';
          _response = e.message ?? OverlayStrings.errorBrief(e);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _phaseLabel = OverlayStrings.subtitleIdle;
          _transcript = '';
          _response = OverlayStrings.errorBrief(e);
        });
      }
    } finally {
      _responding = false;
    }
  }

  Future<void> _closeOverlay() async {
    _listenTimeout?.cancel();
    if (_listening && !_responding) {
      _captureId++;
      await _voice.cancelRecording();
      if (mounted) {
        setState(() {
          _listening = false;
          _phaseLabel = OverlayStrings.subtitleIdle;
          _transcript = '';
          _response = '';
        });
      }
    }
    FlutterForegroundTask.sendDataToTask({'command': cmdResume});
    await FlutterOverlayWindow.closeOverlay();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _overlayChrome.withValues(alpha: _kBackdropOpacity),
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          minimum: const EdgeInsets.only(bottom: 8),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 340,
                maxHeight: overlayHeight - 16,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
                child: Material(
                  color: Colors.transparent,
                  elevation: 8,
                  shadowColor: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                    decoration: BoxDecoration(
                      color: _overlayChrome.withValues(alpha: _kPanelOpacity),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          OverlayHeader(
                            dense: true,
                            stateLabel: _phaseLabel,
                            onClose: () => unawaited(_closeOverlay()),
                          ),
                          const SizedBox(height: 6),
                          OverlayTranscript(
                            dense: true,
                            headline: _headlineText(),
                            detail: _detailText(),
                          ),
                          const SizedBox(height: 8),
                          AssistantMicControls(
                            compact: true,
                            isListening: _listening,
                            showMessages: false,
                            onMicPressed: () => unawaited(toggleListening()),
                            onClosePressed: () => unawaited(cancelOrDismiss()),
                            onMessagesPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
