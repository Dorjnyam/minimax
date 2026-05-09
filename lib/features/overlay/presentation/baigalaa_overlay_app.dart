import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../shared/constants/baigalaa_constants.dart';
import '../../../shared/theme/baigalaa_mesh_background.dart';
import '../../../shared/widgets/fixed_text_scale.dart';
import 'widgets/overlay_sheet_widgets.dart';

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
          seedColor: const Color(0xFF007C89),
          primary: const Color(0xFF007C89),
          secondary: const Color(0xFF4E6E5D),
          surface: Colors.white,
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
  final _speech = stt.SpeechToText();
  final _tts = FlutterTts();

  StreamSubscription<dynamic>? _overlaySubscription;
  Timer? _fallbackTimer;
  String _stateLabel = 'Listening';
  String _transcript = '';
  String _response = '';
  bool _isListening = false;
  bool _hasResponded = false;

  @override
  void initState() {
    super.initState();
    FlutterForegroundTask.sendDataToTask({'command': cmdPause});
    _overlaySubscription = FlutterOverlayWindow.overlayListener.listen((_) {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_startInteraction());
    });
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _overlaySubscription?.cancel();
    unawaited(_speech.cancel());
    unawaited(_tts.stop());
    super.dispose();
  }

  Future<void> _startInteraction() async {
    _fallbackTimer?.cancel();
    setState(() {
      _stateLabel = 'Listening';
      _transcript = '';
      _response = '';
      _isListening = true;
      _hasResponded = false;
    });

    try {
      await _tts.awaitSpeakCompletion(true);
      await _tts.setLanguage('mn-MN');
      await _tts.setSpeechRate(0.42);
      await _tts.setPitch(1.0);
      final available = await _speech.initialize(
        onStatus: _onSpeechStatus,
        onError: (_) => unawaited(_finishInteraction('')),
        options: [stt.SpeechToText.androidNoBluetooth],
      );
      if (!available) {
        await _finishInteraction('');
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
      _fallbackTimer = Timer(const Duration(seconds: 9), () {
        if (!_hasResponded) {
          unawaited(_finishInteraction(_transcript));
        }
      });
    } catch (_) {
      await _finishInteraction('');
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() => _transcript = result.recognizedWords);
    if (result.finalResult && !_hasResponded) {
      unawaited(_finishInteraction(result.recognizedWords));
    }
  }

  void _onSpeechStatus(String status) {
    if ((status == stt.SpeechToText.doneStatus ||
            status == stt.SpeechToText.notListeningStatus) &&
        !_hasResponded) {
      unawaited(_finishInteraction(_transcript));
    }
  }

  Future<void> _finishInteraction(String transcript) async {
    if (_hasResponded) {
      return;
    }
    _hasResponded = true;
    _fallbackTimer?.cancel();
    try {
      await _speech.stop();
    } catch (_) {}

    final cleanTranscript = transcript.trim();
    final response = _mockResponse(cleanTranscript);
    if (!mounted) {
      return;
    }
    setState(() {
      _isListening = false;
      _stateLabel = 'Ready';
      _transcript = cleanTranscript;
      _response = response;
    });
    if (cleanTranscript.isNotEmpty) {
      try {
        await _tts.speak(response);
      } catch (_) {}
    }
  }

  String _mockResponse(String transcript) {
    final normalized = transcript.trim().toLowerCase();
    if (normalized.isEmpty) {
      return '\u0421\u0430\u0439\u043d \u0441\u043e\u043d\u0441\u043e\u0433\u0434\u0441\u043e\u043d\u0433\u04af\u0439. '
          '\u0414\u0430\u0445\u0438\u0430\u0434 \u0445\u044d\u043b\u043d\u044d \u04af\u04af.';
    }
    if (normalized.contains('time')) {
      final now = TimeOfDay.now();
      final hour = now.hour.toString().padLeft(2, '0');
      final minute = now.minute.toString().padLeft(2, '0');
      return '\u041e\u0434\u043e\u043e $hour:$minute \u0431\u043e\u043b\u0436 \u0431\u0430\u0439\u043d\u0430.';
    }
    return '\u0411\u0438 \u0441\u043e\u043d\u0441\u043b\u043e\u043e: $transcript. '
        'Backend \u0445\u0430\u0440\u0438\u0443\u043b\u0442 \u0434\u0430\u0440\u0430\u0430 \u043d\u044c '
        '\u044d\u043d\u0434 \u0445\u043e\u043b\u0431\u043e\u0433\u0434\u043e\u043d\u043e.';
  }

  Future<void> _closeOverlay() async {
    FlutterForegroundTask.sendDataToTask({'command': cmdResume});
    await FlutterOverlayWindow.closeOverlay();
  }

  @override
  Widget build(BuildContext context) {
    return BaigalaaMeshBackground(
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          minimum: const EdgeInsets.only(bottom: 35),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 460,
                maxHeight: overlayHeight - 18,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF111C34).withValues(alpha: 0.86),
                            const Color(0xFF251A42).withValues(alpha: 0.82),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.16),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x44000000),
                            blurRadius: 24,
                            offset: Offset(0, 10),
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
                              stateLabel: _stateLabel,
                              onClose: _closeOverlay,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                OverlayMicOrb(isListening: _isListening),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OverlayTranscript(
                                    transcript: _transcript,
                                    response: _response,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            OverlayActions(
                              isListening: _isListening,
                              onAgain: _startInteraction,
                              onDone: _closeOverlay,
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
      ),
    );
  }
}
