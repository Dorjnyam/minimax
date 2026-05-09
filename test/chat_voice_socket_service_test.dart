import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:minimax/features/chat/data/chat_voice_socket_service.dart';
import 'package:minimax/shared/constants/baigalaa_constants.dart';

void main() {
  test('socket uri is derived from base url', () {
    expect(
      ChatVoiceSocketService.socketUri(
        baseUrl: defaultApiBaseUrl,
        conversationId: 'c1',
        token: 't1',
      ).toString(),
      '${defaultApiBaseUrl.replaceFirst('http://', 'ws://')}/ws/chat/c1/?token=t1',
    );
    expect(
      ChatVoiceSocketService.socketUri(
        baseUrl: 'https://api.test/base',
        conversationId: 'c2',
        token: 'token value',
      ).toString(),
      'wss://api.test/ws/chat/c2/?token=token+value',
    );
  });

  test('audio payload matches backend user_audio body', () async {
    final file = File('${Directory.systemTemp.path}/baigalaa_socket_test.m4a');
    await file.writeAsBytes([1, 2, 3]);
    addTearDown(() {
      if (file.existsSync()) {
        file.deleteSync();
      }
    });

    final payload = await ChatVoiceSocketService.buildAudioPayload(
      audioPath: file.path,
    );

    expect(payload, {
      'type': 'user_audio',
      'audio': base64Encode([1, 2, 3]),
      'mime': 'audio/m4a',
      'language': 'mn',
      'tts': false,
    });
  });

  test('sendAudio passes token query and parses response', () async {
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
      exchange: (uri, headers, payload, _) async {
        capturedUri = uri;
        capturedHeaders = headers;
        expect(payload['type'], 'user_audio');
        expect(payload['mime'], 'audio/m4a');
        expect(payload['language'], 'mn');
        expect(payload['tts'], false);
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

    expect(capturedUri.toString(), 'ws://api.test/ws/chat/c2/?token=token');
    expect(capturedHeaders, isEmpty);
    expect(response.text, 'reply');
    expect(response.audioUrl, '/reply.mp3');
  });
  test('user_message payload matches backend body', () {
    expect(
      ChatVoiceSocketService.buildUserMessagePayload(
        content: 'Хэрхэн талбай руу очих вэ',
        location: (lat: 47.9188, lng: 106.9175),
        tts: false,
      ),
      {
        'type': 'user_message',
        'content': 'Хэрхэн талбай руу очих вэ',
        'tts': false,
        'location': {'lat': 47.9188, 'lng': 106.9175},
      },
    );
  });

  test('isAssistantReplyComplete accepts text-only assistant reply', () {
    expect(
      ChatVoiceSocketService.isAssistantReplyComplete({
        'content': 'Reply text',
      }),
      isTrue,
    );
    expect(
      ChatVoiceSocketService.isAssistantReplyComplete({'audio_url': '/a.mp3'}),
      isTrue,
    );
  });

  test('isVoiceResponseComplete skips text until audio', () {
    expect(
      ChatVoiceSocketService.isVoiceResponseComplete({'content': 'typing...'}),
      isFalse,
    );
    expect(
      ChatVoiceSocketService.isVoiceResponseComplete({
        'type': 'assistant_message',
        'text': 'partial',
      }),
      isFalse,
    );
    expect(
      ChatVoiceSocketService.isVoiceResponseComplete({'audio_url': '/reply.mp3'}),
      isTrue,
    );
    expect(
      ChatVoiceSocketService.isVoiceResponseComplete({
        'audio_base64': 'AAAA',
        'mime': 'audio/mpeg',
      }),
      isTrue,
    );
    expect(
      ChatVoiceSocketService.isVoiceResponseComplete({'error': 'STT failed'}),
      isTrue,
    );
  });

  test('sendAudio parses inline base64 audio response', () async {
    final file = File('${Directory.systemTemp.path}/baigalaa_socket_b64.m4a');
    await file.writeAsBytes([7, 8, 9]);
    addTearDown(() {
      if (file.existsSync()) {
        file.deleteSync();
      }
    });

    final service = ChatVoiceSocketService(
      exchange: (_, _, _, _) async {
        return jsonEncode({
          'type': 'assistant_audio',
          'audio': 'AQID',
          'mime': 'audio/mpeg',
        });
      },
    );

    final response = await service.sendAudio(
      baseUrl: 'http://api.test',
      token: 'token',
      conversationId: 'c2',
      audioPath: file.path,
    );

    expect(response.audioBase64, 'AQID');
    expect(response.mimeType, 'audio/mpeg');
    expect(response.hasAudio, isTrue);
  });
}
