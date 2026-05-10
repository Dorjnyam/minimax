import 'dart:typed_data' show Uint8List;

import 'package:equatable/equatable.dart';

import '../../assistant/domain/assistant_follow_up_action.dart';
import '../../assistant/domain/assistant_follow_up_parser.dart';
import '../../assistant/domain/maps_command.dart';
import '../../assistant/domain/maps_socket_parser.dart';

/// Voice WebSocket sends JSON (`assistant_audio`, `actions`, …) then a binary MP3
/// frame. [ChatVoiceSocketService] merges metadata with bytes under this key.
const kVoiceSocketMergedBinaryKey = '_baigalaa_ws_audio_bytes';

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
  const ChatAudioResponse({
    required this.text,
    required this.audioUrl,
    this.audioBase64 = '',
    this.mimeType = '',
    this.audioBytes = const [],
    this.mapsCommand,
    this.followUps = const [],
  });

  final String text;
  final String audioUrl;
  final String audioBase64;
  final String mimeType;
  final List<int> audioBytes;
  final MapsCommand? mapsCommand;

  /// Parsed `assistant_audio.actions[]`: Maps, tel/mail/https opens (after TTS).
  final List<AssistantFollowUp> followUps;

  bool get hasAudio =>
      audioUrl.isNotEmpty || audioBase64.isNotEmpty || audioBytes.isNotEmpty;
  bool get hasPayload => text.isNotEmpty || hasAudio;

  factory ChatAudioResponse.fromData(Object? data) {
    if (data is Map) {
      final m = Map<Object?, Object?>.from(data);
      final binAny = m[kVoiceSocketMergedBinaryKey];
      List<int>? mergedBytes;
      if (binAny is Uint8List) {
        mergedBytes = List<int>.from(binAny);
      } else if (binAny is List<int>) {
        mergedBytes = List<int>.from(binAny);
      }
      if (mergedBytes != null) {
        final bytes = mergedBytes;
        m.remove(kVoiceSocketMergedBinaryKey);
        final meta = ChatAudioResponse.fromData(m);
        return ChatAudioResponse(
          text: meta.text,
          audioUrl: meta.audioUrl,
          audioBase64: meta.audioBase64,
          mimeType:
              meta.mimeType.isNotEmpty ? meta.mimeType : 'audio/mpeg',
          audioBytes: bytes,
          mapsCommand: meta.mapsCommand,
          followUps: meta.followUps,
        );
      }
    }

    final followUps = parseAssistantFollowUps(data);
    final mapsFromFollowUps = _firstMapsCommandFromFollowUps(followUps);
    final mapsFromSocket = mapsFromFollowUps ?? parseSocketMapsCommand(data);
    if (data is List<int>) {
      return ChatAudioResponse(
        text: '',
        audioUrl: '',
        audioBytes: List<int>.from(data),
        mimeType: 'audio/mpeg',
        mapsCommand: mapsFromSocket,
        followUps: followUps,
      );
    }
    if (data is String) {
      final value = data.trim();
      return ChatAudioResponse(
        text: _looksLikeAudio(value) ? '' : value,
        audioUrl: _looksLikeAudioUrl(value) ? value : '',
        audioBase64: value.startsWith('data:audio/') ? _cleanBase64(value) : '',
        mimeType: _mimeFromDataUri(value),
        mapsCommand: mapsFromSocket,
        followUps: followUps,
      );
    }
    final audio = _findString(data, const [
      'audio_url',
      'audioUrl',
      'mp3_url',
      'mp3Url',
      'mp4_url',
      'mp4Url',
      'media_url',
      'mediaUrl',
      'file_url',
      'fileUrl',
      'url',
      'audio_file',
      'audioFile',
      'audio',
    ]);
    final inlineAudio = _findString(data, const [
      'audio_base64',
      'audioBase64',
      'audio_data',
      'audioData',
      'base64',
      'audio',
    ]);
    final mimeType = _findString(data, const [
      'mime',
      'mime_type',
      'mimeType',
      'content_type',
      'contentType',
    ]);
    return ChatAudioResponse(
      text: _findString(data, const ['content', 'text', 'message']),
      audioUrl: _looksLikeAudioUrl(audio) ? audio : '',
      audioBase64: _looksLikeAudioUrl(inlineAudio)
          ? ''
          : _cleanBase64(inlineAudio),
      mimeType: mimeType.isNotEmpty ? mimeType : _mimeFromDataUri(inlineAudio),
      mapsCommand: mapsFromSocket,
      followUps: followUps,
    );
  }

  @override
  List<Object?> get props => [
    text,
    audioUrl,
    audioBase64,
    mimeType,
    audioBytes,
    mapsCommand,
    followUps,
  ];
}

MapsCommand? _firstMapsCommandFromFollowUps(List<AssistantFollowUp> followUps) {
  for (final u in followUps) {
    if (u is AssistantFollowUpMaps) return u.command;
  }
  return null;
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

String _findString(Object? data, List<String> keys) {
  if (data is Map) {
    final map = Map<Object?, Object?>.from(data);
    for (final key in keys) {
      final value = map[key];
      if (value != null && value is! Map && value is! List) {
        final text = value.toString().trim();
        if (text.isNotEmpty) {
          return text;
        }
      }
    }
    for (final value in map.values) {
      final found = _findString(value, keys);
      if (found.isNotEmpty) {
        return found;
      }
    }
  }
  if (data is List) {
    for (final value in data) {
      final found = _findString(value, keys);
      if (found.isNotEmpty) {
        return found;
      }
    }
  }
  return '';
}

bool _looksLikeAudioUrl(String value) {
  final lower = value.toLowerCase();
  return lower.startsWith('http://') ||
      lower.startsWith('https://') ||
      lower.endsWith('.mp3') ||
      lower.endsWith('.mp4') ||
      lower.endsWith('.m4a') ||
      lower.contains('.mp3?') ||
      lower.contains('.mp4?') ||
      lower.contains('.m4a?') ||
      lower.startsWith('/') ||
      lower.startsWith('/media/') ||
      lower.startsWith('/files/');
}

bool _looksLikeAudio(String value) {
  return _looksLikeAudioUrl(value) || value.startsWith('data:audio/');
}

String _cleanBase64(String value) {
  final clean = value.trim();
  if (clean.startsWith('data:audio/')) {
    final comma = clean.indexOf(',');
    return comma == -1 ? '' : clean.substring(comma + 1);
  }
  return clean;
}

String _mimeFromDataUri(String value) {
  if (!value.startsWith('data:')) return '';
  final end = value.indexOf(';');
  return end == -1 ? '' : value.substring(5, end);
}

DateTime? _date(Object? value) {
  if (value == null) {
    return null;
  }
  return DateTime.tryParse(value.toString());
}
