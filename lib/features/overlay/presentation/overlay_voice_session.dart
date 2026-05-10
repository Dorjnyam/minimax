import '../../assistant/services/assistant_audio_recorder.dart';
import '../../assistant/services/assistant_chat_service.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/data/auth_storage.dart';
import '../../auth/data/session_refresh_service.dart';
import '../../chat/data/chat_audio_playback_service.dart';
import '../../chat/data/chat_repository.dart';
import '../../chat/data/chat_voice_socket_service.dart';
import '../../chat/domain/chat_models.dart';

/// Voice upload + playback for the overlay engine (same stack as [AssistantCubit] chat path).
class OverlayVoiceSession {
  OverlayVoiceSession()
    : _chatService = AssistantChatService(
        authStorage: const SecureAuthStorage(),
        accessTokenProvider: SessionRefreshService(
          repository: const AuthRepository(),
          storage: const SecureAuthStorage(),
        ),
        chatRepository: const ChatRepository(),
        voiceSocket: const ChatVoiceSocketService(),
        audioPlayback: ChatAudioPlaybackService(),
      ),
      _recorder = M4aAssistantAudioRecorder();

  final AssistantChatService _chatService;
  final M4aAssistantAudioRecorder _recorder;

  String _conversationId = '';

  AssistantAudioRecorder get recorder => _recorder;

  Future<void> closeRecorder() => _recorder.dispose();

  Future<String?> startRecording() => _recorder.start();

  Future<String> stopRecording() async {
    final path = await _recorder.stop();
    return path ?? '';
  }

  Future<void> cancelRecording() => _recorder.cancel();

  /// Sends m4a to the same WS/chat pipeline as the main assistant.
  Future<({AssistantChatContext context, ChatAudioResponse reply})> sendRecording(
    String audioPath,
  ) async {
    final context = await _chatService.prepare(_conversationId);
    _conversationId = context.conversationId;
    final reply = await _chatService.sendAudio(
      context: context,
      audioPath: audioPath,
    );
    return (context: context, reply: reply);
  }

  Future<void> playAssistantAudio({
    required AssistantChatContext context,
    required ChatAudioResponse reply,
  }) async {
    if (!reply.hasAudio) return;
    if (reply.audioUrl.isNotEmpty) {
      await _chatService.playAudio(
        context: context,
        audioUrl: reply.audioUrl,
      );
      return;
    }
    await _chatService.playAudioResponse(reply);
  }
}
