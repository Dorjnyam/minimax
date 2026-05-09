import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:minimax/features/api_console/data/hackathon_api_client.dart';
import 'package:minimax/features/assistant/domain/maps_command.dart';
import 'package:minimax/features/chat/data/chat_repository.dart';
import 'package:minimax/features/chat/domain/chat_models.dart';

void main() {
  test('conversation parser sorts newest first', () {
    final conversations = parseConversations({
      'data': [
        {
          'id': 'old',
          'title': 'Old',
          'updated_at': '2026-05-09T16:15:27.414000',
        },
        {
          'id': 'new',
          'title': 'New',
          'updated_at': '2026-05-10T16:15:27.414000',
        },
      ],
    });

    expect(conversations.map((item) => item.id), ['new', 'old']);
  });

  test('message and audio response parsers support backend shapes', () {
    final messages = parseMessages({
      'data': [
        {
          'id': 'm1',
          'conversation_id': 'c1',
          'role': 'assistant',
          'content': 'Сайн байна уу',
        },
      ],
    });
    final audio = ChatAudioResponse.fromData({
      'data': {'content': 'Хариу', 'mp3_url': '/media/reply.mp3'},
    });

    expect(messages.single.content, 'Сайн байна уу');
    expect(audio.text, 'Хариу');
    expect(audio.audioUrl, '/media/reply.mp3');
  });

  test('audio response parser attaches maps command from socket type', () {
    final navigate = ChatAudioResponse.fromData({
      'type': 'maps_navigate',
      'lat': 47.916,
      'lng': 106.917,
      'name': 'Сүхбаатарын талбай',
    });
    expect(navigate.mapsCommand?.type, MapsCommandType.directions);
    expect(navigate.mapsCommand?.query, 'Сүхбаатарын талбай');

    final route = ChatAudioResponse.fromData({
      'type': 'maps_route',
      'destination_lat': 47.916,
      'destination_lng': 106.917,
    });
    expect(route.mapsCommand?.query, '47.916,106.917');
  });

  test('audio response parser reads maps_navigate inside assistant_audio actions', () {
    final reply = ChatAudioResponse.fromData({
      'type': 'assistant_audio',
      'content': 'Central TV олдлоо.',
      'actions': [
        {
          'type': 'maps_navigate',
          'name': 'Central TV',
          'lat': 47.8935895,
          'lng': 106.9054189,
        },
      ],
    });
    expect(reply.mapsCommand?.query, 'Central TV');
    expect(reply.mapsCommand?.routeAction, MapsRouteAction.navigate);
  });

  test('merged WS metadata + binary preserves maps actions', () {
    final reply = ChatAudioResponse.fromData({
      'type': 'assistant_audio',
      'content': 'Сүхбаатарын талбай олдлоо.',
      'audio_mime': 'audio/mpeg',
      'actions': [
        {
          'type': 'maps_navigate',
          'name': 'Сүхбаатарын талбай',
          'lat': 47.9166872,
          'lng': 106.917851,
        },
      ],
      kVoiceSocketMergedBinaryKey: <int>[1, 2, 3],
    });
    expect(reply.audioBytes, [1, 2, 3]);
    expect(reply.hasAudio, isTrue);
    expect(reply.mapsCommand?.query, 'Сүхбаатарын талбай');
  });

  test('audio response parser supports inline base64 audio', () {
    final audio = ChatAudioResponse.fromData({
      'type': 'assistant_audio',
      'data': {'message': 'done', 'audio': 'AQID', 'mime': 'audio/mp4'},
    });

    expect(audio.text, 'done');
    expect(audio.audioBase64, 'AQID');
    expect(audio.mimeType, 'audio/mp4');
    expect(audio.hasAudio, isTrue);
  });

  test('repository sends authenticated conversation requests', () async {
    final calls = <String>[];
    final bodies = <Object?>[];
    final repository = ChatRepository(
      client: HackathonApiClient(
        send: (method, uri, headers, body) async {
          calls.add('$method ${uri.path} ${headers['Authorization']}');
          bodies.add(body);
          if (uri.path.endsWith('/messages')) {
            return _json({'data': []});
          }
          return _json({
            'data': {'id': 'c1', 'title': 'Шинэ яриа'},
          });
        },
      ),
    );

    await repository.createConversation(baseUrl: 'http://api', token: 't1');
    await repository.messages(
      baseUrl: 'http://api',
      token: 't1',
      conversationId: 'c1',
    );

    expect(calls.first, 'POST /api/v1/chat/conversations Bearer t1');
    expect(jsonDecode(bodies.first! as String), {'title': 'Шинэ яриа'});
    expect(calls.last, 'GET /api/v1/chat/conversations/c1/messages Bearer t1');
  });
}

http.Response _json(Map<String, Object?> data) {
  return http.Response.bytes(utf8.encode(jsonEncode(data)), 200);
}
