import '../../../shared/constants/baigalaa_constants.dart';
import '../../auth/data/auth_storage.dart';
import '../../chat/data/chat_audio_playback_service.dart';
import '../../chat/data/chat_repository.dart';
import '../../chat/data/chat_voice_socket_service.dart';
import '../../chat/domain/chat_models.dart';

class AssistantChatService {
  const AssistantChatService({
    required AuthStorage authStorage,
    required ChatRepository chatRepository,
    required ChatVoiceSocketService voiceSocket,
    required ChatAudioPlaybackService audioPlayback,
  }) : _authStorage = authStorage,
       _chatRepository = chatRepository,
       _voiceSocket = voiceSocket,
       _audioPlayback = audioPlayback;

  final AuthStorage _authStorage;
  final ChatRepository _chatRepository;
  final ChatVoiceSocketService _voiceSocket;
  final ChatAudioPlaybackService _audioPlayback;

  Future<AssistantChatContext> prepare(String currentConversationId) async {
    final session = await _session();
    final conversationId = await _conversationId(
      session,
      currentConversationId,
    );
    return AssistantChatContext(
      baseUrl: session.baseUrl,
      token: session.token,
      conversationId: conversationId,
    );
  }

  Future<AssistantChatMessagesResult> loadMessages(
    String currentConversationId,
  ) async {
    final context = await prepare(currentConversationId);
    final messages = await _chatRepository.messages(
      baseUrl: context.baseUrl,
      token: context.token,
      conversationId: context.conversationId,
    );
    return AssistantChatMessagesResult(
      conversationId: context.conversationId,
      messages: messages,
    );
  }

  Future<ChatAudioResponse> sendAudio({
    required AssistantChatContext context,
    required String audioPath,
  }) {
    return _voiceSocket.sendAudio(
      baseUrl: context.baseUrl,
      token: context.token,
      conversationId: context.conversationId,
      audioPath: audioPath,
    );
  }

  Future<String> playAudio({
    required AssistantChatContext context,
    required String audioUrl,
  }) {
    return _audioPlayback.downloadAndPlay(
      baseUrl: context.baseUrl,
      token: context.token,
      audioUrl: audioUrl,
    );
  }

  Future<List<ChatMessage>> safeMessages(AssistantChatContext context) async {
    try {
      return _chatRepository.messages(
        baseUrl: context.baseUrl,
        token: context.token,
        conversationId: context.conversationId,
      );
    } catch (_) {
      return const [];
    }
  }

  Future<_ChatSession> _session() async {
    final token = await _authStorage.read(apiAccessTokenStorageKey);
    if (token == null || token.trim().isEmpty) {
      throw StateError('Please log in again.');
    }
    return _ChatSession(baseUrl: defaultApiBaseUrl, token: token.trim());
  }

  Future<String> _conversationId(
    _ChatSession session,
    String currentConversationId,
  ) async {
    if (currentConversationId.isNotEmpty) {
      return currentConversationId;
    }
    final stored = await _authStorage.read(apiConversationIdStorageKey);
    if (stored != null && stored.trim().isNotEmpty) {
      return stored.trim();
    }
    final conversations = await _chatRepository.conversations(
      baseUrl: session.baseUrl,
      token: session.token,
    );
    final conversation = conversations.isNotEmpty
        ? conversations.first
        : await _chatRepository.createConversation(
            baseUrl: session.baseUrl,
            token: session.token,
          );
    await _authStorage.write(apiConversationIdStorageKey, conversation.id);
    return conversation.id;
  }
}

class AssistantChatContext {
  const AssistantChatContext({
    required this.baseUrl,
    required this.token,
    required this.conversationId,
  });

  final String baseUrl;
  final String token;
  final String conversationId;
}

class AssistantChatMessagesResult {
  const AssistantChatMessagesResult({
    required this.conversationId,
    required this.messages,
  });

  final String conversationId;
  final List<ChatMessage> messages;
}

class _ChatSession {
  const _ChatSession({required this.baseUrl, required this.token});

  final String baseUrl;
  final String token;
}
