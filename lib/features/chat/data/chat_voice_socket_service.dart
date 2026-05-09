import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/io.dart';

import '../domain/chat_models.dart';

typedef ChatSocketExchange =
    Future<Object?> Function(
      Uri uri,
      Map<String, String> headers,
      Map<String, Object?> payload,
      bool Function(Object?) isComplete,
    );

class ChatVoiceSocketService {
  const ChatVoiceSocketService({
    ChatSocketExchange? exchange,
    Duration timeout = const Duration(seconds: 45),
  }) : _exchange = exchange ?? _defaultExchange,
       _timeout = timeout;

  final ChatSocketExchange _exchange;
  final Duration _timeout;

  Future<ChatAudioResponse> sendAudio({
    required String baseUrl,
    required String token,
    required String conversationId,
    required String audioPath,
    ({double lat, double lng})? location,
  }) async {
    final uri = socketUri(
      baseUrl: baseUrl,
      conversationId: conversationId,
      token: token,
    );
    final payload = await buildAudioPayload(
      audioPath: audioPath,
      location: location,
    );
    _logOutgoing(uri, payload);
    final headers = <String, String>{};
    final response = await _exchange(
      uri,
      headers,
      payload,
      isVoiceResponseComplete,
    ).timeout(_timeout);
    return ChatAudioResponse.fromData(_decode(response));
  }

  /// Same WebSocket URL as [sendAudio]; JSON body uses `user_message` (+ optional GPS).
  Future<ChatAudioResponse> sendUserMessage({
    required String baseUrl,
    required String token,
    required String conversationId,
    required String content,
    ({double lat, double lng})? location,
  }) async {
    final uri = socketUri(
      baseUrl: baseUrl,
      conversationId: conversationId,
      token: token,
    );
    final payload = buildUserMessagePayload(
      content: content,
      location: location,
    );
    _logOutgoing(uri, payload);
    final headers = <String, String>{};
    final response = await _exchange(
      uri,
      headers,
      payload,
      isAssistantReplyComplete,
    ).timeout(_timeout);
    return ChatAudioResponse.fromData(_decode(response));
  }

  static Uri socketUri({
    required String baseUrl,
    required String conversationId,
    required String token,
  }) {
    final base = Uri.parse(baseUrl.trim().replaceFirst(RegExp(r'/+$'), ''));
    final scheme = base.scheme == 'https' ? 'wss' : 'ws';
    return Uri(
      scheme: scheme,
      host: base.host,
      port: base.hasPort ? base.port : 0,
      path: '/ws/chat/${Uri.encodeComponent(conversationId)}/',
      queryParameters: {'token': token},
    );
  }

  /// Backend `user_message` frame (text chat over the voice socket).
  static Map<String, Object?> buildUserMessagePayload({
    required String content,
    ({double lat, double lng})? location,
    bool tts = false,
  }) {
    return {
      'type': 'user_message',
      'content': content,
      'tts': tts,
      if (location != null)
        'location': <String, Object?>{
          'lat': location.lat,
          'lng': location.lng,
        },
    };
  }

  /// Backend `user_audio` frame: audio + [location] + [tts] (same shape as `user_message` extras).
  static Future<Map<String, Object?>> buildAudioPayload({
    required String audioPath,
    ({double lat, double lng})? location,
  }) async {
    final file = File(audioPath);
    final bytes = await file.readAsBytes();
    return {
      'type': 'user_audio',
      'audio': base64Encode(bytes),
      'mime': 'audio/m4a',
      'language': 'mn',
      'tts': false,
      if (location != null)
        'location': <String, Object?>{
          'lat': location.lat,
          'lng': location.lng,
        },
    };
  }

  static Object? _decode(Object? response) {
    if (response is String) {
      return jsonDecode(response);
    }
    return response;
  }

  static List<int>? _coerceSocketBinary(Object? last) {
    if (last is Uint8List) return List<int>.from(last);
    if (last is List<int>) return List<int>.from(last);
    return null;
  }

  static Future<Object?> _defaultExchange(
    Uri uri,
    Map<String, String> headers,
    Map<String, Object?> payload,
    bool Function(Object?) isComplete,
  ) async {
    return _socketExchange(uri, headers, payload, isComplete);
  }

  static Future<Object?> _socketExchange(
    Uri uri,
    Map<String, String> headers,
    Map<String, Object?> payload,
    bool Function(Object?) isComplete,
  ) async {
    final channel = IOWebSocketChannel.connect(uri, headers: headers);
    try {
      channel.sink.add(jsonEncode(payload));
      Object? last;
      var frameIndex = 0;
      /// Last JSON frame with `assistant_audio` / `actions` before binary MP3.
      Map<String, Object?>? voiceAssistantMeta;
      await for (final event in channel.stream) {
        frameIndex++;
        last = _decode(event);
        if (last is Map) {
          final map = Map<String, Object?>.from(last);
          final type = map['type']?.toString();
          final actions = map['actions'];
          if (type == 'assistant_audio' ||
              (actions is List && actions.isNotEmpty)) {
            voiceAssistantMeta = map;
          }
        }
        final done = isComplete(last);
        _logIncomingFrame(frameIndex, last, complete: done);
        if (done) {
          final binary = _coerceSocketBinary(last);
          if (binary != null && voiceAssistantMeta != null) {
            return <String, Object?>{
              ...voiceAssistantMeta,
              kVoiceSocketMergedBinaryKey: binary,
            };
          }
          return last;
        }
      }
      _log(
        'stream closed after $frameIndex frame(s); last frame used as fallback.',
      );
      return last;
    } finally {
      unawaited(channel.sink.close());
    }
  }

  /// Completes on first assistant text (no audio), playable audio, or error — same socket as voice.
  static bool isAssistantReplyComplete(Object? data) {
    if (isVoiceResponseComplete(data)) return true;
    final parsed = ChatAudioResponse.fromData(data);
    return parsed.text.trim().isNotEmpty;
  }

  static void _logOutgoing(Uri uri, Map<String, Object?> payload) {
    if (!kDebugMode) return;
    final safeUri = _uriForLog(uri);
    final described = _describeOutgoingPayload(payload);
    debugPrint(
      '[Baigalaa VoiceSocket] → SEND ${_prettyJson(described)}\n'
      '  url: $safeUri',
    );
    final loc = payload['location'];
    if (loc is Map) {
      debugPrint(
        '[Baigalaa VoiceSocket] → body.location: lat=${loc['lat']} lng=${loc['lng']}',
      );
    } else {
      debugPrint(
        '[Baigalaa VoiceSocket] → body.location: (not sent — key absent)',
      );
    }
  }

  static void _logIncomingFrame(int index, Object? data, {required bool complete}) {
    if (!kDebugMode) return;
    final tag = complete ? 'DONE' : 'recv';
    debugPrint(
      '[Baigalaa VoiceSocket] ← $tag #$index ${_previewIncoming(data)}',
    );
  }

  static void _log(String msg) {
    if (!kDebugMode) return;
    debugPrint('[Baigalaa VoiceSocket] $msg');
  }

  static Uri _uriForLog(Uri uri) {
    final q = Map<String, String>.from(uri.queryParameters);
    if (q.containsKey('token')) {
      q['token'] = '***';
    }
    return uri.replace(queryParameters: q);
  }

  /// Omits huge base64; keeps sizes for debugging.
  static Map<String, Object?> _describeOutgoingPayload(Map<String, Object?> p) {
    final out = Map<String, Object?>.from(p);
    final audio = out['audio'];
    if (audio is String) {
      out['audio'] = '<base64, ${audio.length} chars>';
    }
    return out;
  }

  static String _prettyJson(Object? data) {
    try {
      return const JsonEncoder.withIndent('  ').convert(data);
    } catch (_) {
      return data.toString();
    }
  }

  static String _previewIncoming(Object? data, {int maxLen = 1600}) {
    if (data == null) return 'null';
    if (data is List<int>) {
      return '<binary ${data.length} bytes>';
    }
    try {
      final text = jsonEncode(data);
      if (text.length <= maxLen) return text;
      return '${text.substring(0, maxLen)}… (${text.length} chars total)';
    } catch (_) {
      final raw = data.toString();
      if (raw.length <= maxLen) return raw;
      return '${raw.substring(0, maxLen)}…';
    }
  }

  /// Stop reading the socket when this frame carries playable audio or an error.
  /// Interim text-only assistant messages are ignored until MP3/url/base64 arrives.
  static bool isVoiceResponseComplete(Object? data) {
    if (_isSocketErrorFrame(data)) return true;
    return ChatAudioResponse.fromData(data).hasAudio;
  }

  static bool _isSocketErrorFrame(Object? data) {
    if (data == null) return false;
    if (data is Map) {
      final map = Map<Object?, Object?>.from(data);
      if (map.containsKey('error')) return true;
      if (map['success'] == false) return true;
      final type = _socketType(data).toLowerCase();
      if (type.contains('error')) return true;
      final nested = map['data'];
      if (nested is Map && nested['error'] != null) return true;
    }
    return false;
  }

  static String _socketType(Object? data) {
    if (data is Map) {
      final value = data['type'];
      if (value != null) return value.toString();
      final nested = data['data'];
      if (nested is Map && nested['type'] != null) {
        return nested['type'].toString();
      }
    }
    return '';
  }
}
