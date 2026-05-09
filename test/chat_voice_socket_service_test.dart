import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:minimax/features/chat/data/chat_voice_socket_service.dart';
import 'package:minimax/shared/constants/baigalaa_constants.dart';

void main() {
  test('socket uri is derived from base url', () {
    expect(
      ChatVoiceSocketService.socketUri(defaultApiBaseUrl).toString(),
      '${defaultApiBaseUrl.replaceFirst('http://', 'ws://')}/ws/chat',
    );
    expect(
      ChatVoiceSocketService.socketUri('https://api.test/base').toString(),
      'wss://api.test/ws/chat',
    );
  });

  test(
    'audio payload includes conversation id, filename, and base64 m4a',
    () async {
      final file = File(
        '${Directory.systemTemp.path}/baigalaa_socket_test.m4a',
      );
      await file.writeAsBytes([1, 2, 3]);
      addTearDown(() {
        if (file.existsSync()) {
          file.deleteSync();
        }
      });

      final payload = await ChatVoiceSocketService.buildAudioPayload(
        conversationId: 'c1',
        audioPath: file.path,
      );

      expect(payload['type'], 'audio.message');
      expect(payload['conversation_id'], 'c1');
      expect(payload['mime_type'], 'audio/mp4');
      expect(payload['filename'], 'baigalaa_socket_test.m4a');
      expect(payload['audio_base64'], base64Encode([1, 2, 3]));
    },
  );

  test('sendAudio passes bearer header and parses response', () async {
    final file = File('${Directory.systemTemp.path}/baigalaa_socket_send.m4a');
    await file.writeAsBytes([4, 5, 6]);
    addTearDown(() {
      if (file.existsSync()) {
        file.deleteSync();
      }
    });
    Uri? capturedUri;
    Map<String, String>? capturedHeaders;

    final service = ChatVoiceSocketService(
      exchange: (uri, headers, payload) async {
        capturedUri = uri;
        capturedHeaders = headers;
        expect(payload['conversation_id'], 'c2');
        return jsonEncode({
          'data': {'content': 'reply', 'audio_url': '/reply.mp3'},
        });
      },
    );

    final response = await service.sendAudio(
      baseUrl: 'http://api.test',
      token: 'token',
      conversationId: 'c2',
      audioPath: file.path,
    );

    expect(capturedUri.toString(), 'ws://api.test/ws/chat');
    expect(capturedHeaders?['Authorization'], 'Bearer token');
    expect(response.text, 'reply');
    expect(response.audioUrl, '/reply.mp3');
  });
}
