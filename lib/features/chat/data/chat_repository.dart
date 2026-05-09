import '../../api_console/data/hackathon_api_client.dart';
import '../domain/chat_models.dart';

class ChatApiException implements Exception {
  const ChatApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() {
    return statusCode == null ? message : 'HTTP $statusCode: $message';
  }
}

class ChatRepository {
  const ChatRepository({HackathonApiClient client = const HackathonApiClient()})
    : _client = client;

  final HackathonApiClient _client;

  Future<ChatConversation> createConversation({
    required String baseUrl,
    required String token,
    String title = 'Шинэ яриа',
  }) async {
    final result = await _request(
      baseUrl: baseUrl,
      method: 'POST',
      path: '/api/v1/chat/conversations',
      token: token,
      body: {'title': title},
    );
    return ChatConversation.fromData(result.data);
  }

  Future<List<ChatConversation>> conversations({
    required String baseUrl,
    required String token,
  }) async {
    final result = await _request(
      baseUrl: baseUrl,
      method: 'GET',
      path: '/api/v1/chat/conversations',
      token: token,
    );
    return parseConversations(result.data);
  }

  Future<List<ChatMessage>> messages({
    required String baseUrl,
    required String token,
    required String conversationId,
  }) async {
    final result = await _request(
      baseUrl: baseUrl,
      method: 'GET',
      path: '/api/v1/chat/conversations/$conversationId/messages',
      token: token,
    );
    return parseMessages(result.data);
  }

  Future<ApiCallResult> _request({
    required String baseUrl,
    required String method,
    required String path,
    required String token,
    Map<String, Object?>? body,
  }) async {
    final result = await _client.request(
      baseUrl: baseUrl,
      method: method,
      path: path,
      token: token,
      body: body,
    );
    if (!result.isSuccess) {
      throw ChatApiException(
        result.rawBody.isEmpty ? 'Request failed.' : result.rawBody,
        statusCode: result.statusCode,
      );
    }
    return result;
  }
}
