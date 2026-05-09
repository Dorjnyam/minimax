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
    final uri = socketUri(baseUrl);
    final payload = await buildAudioPayload(
      conversationId: conversationId,
      audioPath: audioPath,
    );
    final headers = {'Authorization': 'Bearer $token'};
    final response = await _exchange(uri, headers, payload).timeout(_timeout);
    return ChatAudioResponse.fromData(_decode(response));
  }

  static Uri socketUri(String baseUrl) {
    final base = Uri.parse(baseUrl.trim().replaceFirst(RegExp(r'/+$'), ''));
    final scheme = base.scheme == 'https' ? 'wss' : 'ws';
    return Uri(
      scheme: scheme,
      host: base.host,
      port: base.hasPort ? base.port : 0,
      path: '/ws/chat',
    );
  }

  static Future<Map<String, Object?>> buildAudioPayload({
    required String conversationId,
    required String audioPath,
  }) async {
    final file = File(audioPath);
    final bytes = await file.readAsBytes();
    return {
      'type': 'audio.message',
      'conversation_id': conversationId,
      'mime_type': 'audio/mp4',
      'filename': _filename(audioPath),
      'audio_base64': base64Encode(bytes),
    };
  }

  static Object? _decode(Object? response) {
    if (response is String) {
      return jsonDecode(response);
    }
    return response;
  }

  static String _filename(String path) {
    final parts = path.split(RegExp(r'[\\/]'));
    return parts.isEmpty ? path : parts.last;
  }

  static Future<Object?> _defaultExchange(
    Uri uri,
    Map<String, String> headers,
    Map<String, Object?> payload,
  ) async {
    final channel = IOWebSocketChannel.connect(uri, headers: headers);
    try {
      channel.sink.add(jsonEncode(payload));
      return await channel.stream.first;
    } finally {
      unawaited(channel.sink.close());
    }
  }
}
