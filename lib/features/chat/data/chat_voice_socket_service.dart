import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:web_socket_channel/io.dart';

import '../domain/chat_models.dart';

typedef ChatSocketExchange =
    Future<Object?> Function(
      Uri uri,
      Map<String, String> headers,
      Map<String, Object?> payload,
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
  }) async {
    final uri = socketUri(
      baseUrl: baseUrl,
      conversationId: conversationId,
      token: token,
    );
    final payload = await buildAudioPayload(audioPath: audioPath);
    final headers = <String, String>{};
    final response = await _exchange(uri, headers, payload).timeout(_timeout);
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

  /// Backend `user_audio` frame: `{ type, audio: base64 file bytes, mime, language }`.
  static Future<Map<String, Object?>> buildAudioPayload({
    required String audioPath,
  }) async {
    final file = File(audioPath);
    final bytes = await file.readAsBytes();
    return {
      'type': 'user_audio',
      'audio': base64Encode(bytes),
      'mime': 'audio/m4a',
      'language': 'mn',
    };
  }

  static Object? _decode(Object? response) {
    if (response is String) {
      return jsonDecode(response);
    }
    return response;
  }

  static Future<Object?> _defaultExchange(
    Uri uri,
    Map<String, String> headers,
    Map<String, Object?> payload,
  ) async {
    final channel = IOWebSocketChannel.connect(uri, headers: headers);
    try {
      channel.sink.add(jsonEncode(payload));
      Object? last;
      await for (final event in channel.stream) {
        last = _decode(event);
        if (_isFinalReply(last)) {
          return last;
        }
      }
      return last;
    } finally {
      unawaited(channel.sink.close());
    }
  }

  static bool _isFinalReply(Object? data) {
    final reply = ChatAudioResponse.fromData(data);
    if (reply.hasAudio) return true;
    if (!reply.hasPayload) return false;
    final type = _socketType(data).toLowerCase();
    return !type.contains('processing') &&
        !type.contains('status') &&
        !type.contains('ack') &&
        !type.contains('partial') &&
        !type.contains('start');
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
