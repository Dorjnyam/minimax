import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:minimax/features/assistant/bloc/assistant_cubit.dart';
import 'package:minimax/features/assistant/data/assistant_repository.dart';
import 'package:minimax/features/auth/data/session_refresh_service.dart';
import 'package:minimax/features/auth/data/auth_storage.dart';
import 'package:minimax/features/chat/data/chat_audio_playback_service.dart';
import 'package:minimax/features/chat/data/chat_repository.dart';
import 'package:minimax/features/chat/data/chat_voice_socket_service.dart';
import 'package:minimax/features/chat/domain/chat_models.dart';
import 'package:minimax/shared/constants/baigalaa_constants.dart';
import 'package:minimax/shared/services/user_location_service.dart';
import 'package:minimax/shared/services/maps_launcher_service.dart';

void main() {
  test('recorded non-map text sends m4a to authenticated chat', () async {
    final file = File('${Directory.systemTemp.path}/baigalaa_cubit_chat.m4a');
    await file.writeAsBytes([1, 2, 3]);
    addTearDown(() {
      if (file.existsSync()) {
        file.deleteSync();
      }
    });

    final socket = _FakeVoiceSocket();
    final cubit = AssistantCubit(
      repository: const MockAssistantRepository(),
      mapsLauncher: MapsLauncherService(launch: (_, _) async => true),
      accessTokenProvider: const FixedAccessTokenProvider('token'),
      authStorage: MemoryAuthStorage({
        apiBaseUrlStorageKey: 'http://api.test',
        apiAccessTokenStorageKey: 'token',
        apiConversationIdStorageKey: 'c1',
      }),
      chatRepository: _FakeChatRepository(),
      chatVoiceSocket: socket,
      chatAudioPlayback: _FakePlayback(),
      userLocationService: UserLocationService(
        override: () async => (lat: 47.9188, lng: 106.9175),
      ),
    );

    await cubit.submitText('hello', recordingPath: file.path);

    expect(socket.audioPath, file.path);
    expect(socket.conversationId, 'c1');
    expect(cubit.state.status, AssistantStatus.idle);
    expect(cubit.state.response, 'assistant reply');
    expect(cubit.state.replyAudioPath, 'local-reply.mp3');
    expect(cubit.state.messages.map((item) => item.role), [
      'user',
      'assistant',
    ]);
    await cubit.close();
  });

  test('missing token surfaces login error for recorded audio', () async {
    final cubit = AssistantCubit(
      repository: const MockAssistantRepository(),
      mapsLauncher: MapsLauncherService(launch: (_, _) async => true),
      accessTokenProvider: const FixedAccessTokenProvider(''),
      authStorage: MemoryAuthStorage(),
      chatRepository: _FakeChatRepository(),
      chatVoiceSocket: _FakeVoiceSocket(),
      chatAudioPlayback: _FakePlayback(),
      userLocationService: UserLocationService(override: () async => null),
    );

    await cubit.submitText('hello', recordingPath: 'missing.m4a');

    expect(cubit.state.status, AssistantStatus.error);
    expect(cubit.state.response, 'Please log in again.');
    await cubit.close();
  });
}

class _FakeChatRepository implements ChatRepository {
  @override
  Future<ChatConversation> createConversation({
    required String baseUrl,
    required String token,
    String title = 'Шинэ яриа',
  }) async {
    return ChatConversation(
      id: 'c1',
      agentId: 'a1',
      title: title,
      createdAt: null,
      updatedAt: null,
    );
  }

  @override
  Future<List<ChatConversation>> conversations({
    required String baseUrl,
    required String token,
  }) async {
    return const [];
  }

  @override
  Future<List<ChatMessage>> messages({
    required String baseUrl,
    required String token,
    required String conversationId,
  }) async {
    return const [];
  }
}

class _FakeVoiceSocket implements ChatVoiceSocketService {
  String? conversationId;
  String? audioPath;

  @override
  Future<ChatAudioResponse> sendAudio({
    required String baseUrl,
    required String token,
    required String conversationId,
    required String audioPath,
    ({double lat, double lng})? location,
  }) async {
    this.conversationId = conversationId;
    this.audioPath = audioPath;
    return const ChatAudioResponse(
      text: 'assistant reply',
      audioUrl: 'http://api.test/reply.mp3',
    );
  }
}

class _FakePlayback implements ChatAudioPlaybackService {
  @override
  Future<String> downloadAndPlay({
    required String baseUrl,
    required String token,
    required String audioUrl,
  }) async {
    return 'local-reply.mp3';
  }

  @override
  Future<String> playResponse(ChatAudioResponse response) async {
    return 'local-inline-reply.mp3';
  }
}
