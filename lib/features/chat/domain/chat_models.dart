import 'package:equatable/equatable.dart';

class ChatConversation extends Equatable {
  const ChatConversation({
    required this.id,
    required this.agentId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String agentId;
  final String title;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ChatConversation.fromData(Object? data) {
    final map = _findMap(data);
    return ChatConversation(
      id: '${map['id'] ?? ''}',
      agentId: '${map['agent_id'] ?? map['agentId'] ?? ''}',
      title: '${map['title'] ?? ''}',
      createdAt: _date(map['created_at'] ?? map['createdAt']),
      updatedAt: _date(map['updated_at'] ?? map['updatedAt']),
    );
  }

  @override
  List<Object?> get props => [id, agentId, title, createdAt, updatedAt];
}

class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String conversationId;
  final String role;
  final String content;
  final DateTime? createdAt;

  bool get isUser => role == 'user';

  factory ChatMessage.local({
    required String conversationId,
    required String role,
    required String content,
  }) {
    return ChatMessage(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      conversationId: conversationId,
      role: role,
      content: content,
      createdAt: DateTime.now(),
    );
  }

  factory ChatMessage.fromData(Object? data) {
    final map = _findMap(data);
    return ChatMessage(
      id: '${map['id'] ?? ''}',
      conversationId:
          '${map['conversation_id'] ?? map['conversationId'] ?? ''}',
      role: '${map['role'] ?? ''}',
      content: '${map['content'] ?? ''}',
      createdAt: _date(map['created_at'] ?? map['createdAt']),
    );
  }

  @override
  List<Object?> get props => [id, conversationId, role, content, createdAt];
}

class ChatAudioResponse extends Equatable {
  const ChatAudioResponse({required this.text, required this.audioUrl});

  final String text;
  final String audioUrl;

  factory ChatAudioResponse.fromData(Object? data) {
    final map = _findMap(data);
    return ChatAudioResponse(
      text: _findString(map, const ['content', 'text', 'message']),
      audioUrl: _findString(map, const [
        'audio_url',
        'audioUrl',
        'mp3_url',
        'mp3Url',
        'mp4_url',
        'mp4Url',
        'media_url',
        'mediaUrl',
      ]),
    );
  }

  @override
  List<Object?> get props => [text, audioUrl];
}

List<ChatConversation> parseConversations(Object? data) {
  return _items(data).map(ChatConversation.fromData).where((item) {
    return item.id.isNotEmpty;
  }).toList()..sort((a, b) {
    final left =
        a.updatedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final right =
        b.updatedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return right.compareTo(left);
  });
}

List<ChatMessage> parseMessages(Object? data) {
  return _items(data).map(ChatMessage.fromData).where((item) {
    return item.id.isNotEmpty || item.content.isNotEmpty;
  }).toList();
}

List<Object?> _items(Object? data) {
  if (data is Map && data['data'] is List) {
    return List<Object?>.from(data['data'] as List);
  }
  if (data is List) {
    return List<Object?>.from(data);
  }
  return const [];
}

Map<Object?, Object?> _findMap(Object? data) {
  if (data is Map) {
    if (data['data'] is Map) {
      return Map<Object?, Object?>.from(data['data'] as Map);
    }
    return Map<Object?, Object?>.from(data);
  }
  return const {};
}

String _findString(Map<Object?, Object?> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString();
    }
  }
  final data = map['data'];
  if (data is Map) {
    return _findString(Map<Object?, Object?>.from(data), keys);
  }
  return '';
}

DateTime? _date(Object? value) {
  if (value == null) {
    return null;
  }
  return DateTime.tryParse(value.toString());
}
