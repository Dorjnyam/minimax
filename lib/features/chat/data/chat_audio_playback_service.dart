import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../domain/chat_models.dart';

typedef ChatAudioGet =
    Future<http.Response> Function(Uri uri, Map<String, String> headers);
typedef ChatAudioPlay = Future<void> Function(String path);

class ChatAudioPlaybackService {
  ChatAudioPlaybackService({
    ChatAudioGet? get,
    ChatAudioPlay? play,
    AudioPlayer? player,
  }) : _get = get ?? _defaultGet,
       _player = player,
       _play = play;

  final ChatAudioGet _get;
  final ChatAudioPlay? _play;
  AudioPlayer? _player;

  Future<String> downloadAndPlay({
    required String baseUrl,
    required String token,
    required String audioUrl,
  }) async {
    final uri = _resolve(baseUrl, audioUrl);
    final response = await _get(uri, {'Authorization': 'Bearer $token'});
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Audio download failed: HTTP ${response.statusCode}');
    }
    final path = await _save(uri, response.bodyBytes);
    await _playPath(path);
    return path;
  }

  Future<String> playResponse(ChatAudioResponse response) async {
    if (response.audioBytes.isNotEmpty) {
      return _saveAndPlay(response.audioBytes, response.mimeType);
    }
    if (response.audioBase64.isNotEmpty) {
      return _saveAndPlay(
        base64Decode(response.audioBase64),
        response.mimeType,
      );
    }
    throw StateError('No inline audio found in response.');
  }

  Future<String> _saveAndPlay(List<int> bytes, String mimeType) async {
    final path = await _saveBytes(bytes, _extensionForMime(mimeType));
    await _playPath(path);
    return path;
  }

  Future<void> _playPath(String path) async {
    final play = _play;
    if (play != null) {
      await play(path);
    } else {
      final player = _player ??= AudioPlayer();
      await player.play(DeviceFileSource(path));
    }
  }

  Uri _resolve(String baseUrl, String audioUrl) {
    final uri = Uri.parse(audioUrl);
    if (uri.hasScheme) {
      return uri;
    }
    return Uri.parse(baseUrl).resolve(audioUrl);
  }

  Future<String> _save(Uri uri, List<int> bytes) async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory('${root.path}${Platform.pathSeparator}audio_replies');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final ext = _extension(uri.path);
    final path =
        '${dir.path}${Platform.pathSeparator}'
        'reply_${DateTime.now().millisecondsSinceEpoch}$ext';
    await File(path).writeAsBytes(bytes);
    return path;
  }

  Future<String> _saveBytes(List<int> bytes, String ext) async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory('${root.path}${Platform.pathSeparator}audio_replies');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final path =
        '${dir.path}${Platform.pathSeparator}'
        'reply_${DateTime.now().millisecondsSinceEpoch}$ext';
    await File(path).writeAsBytes(bytes);
    return path;
  }

  String _extension(String path) {
    final last = path.split('/').last;
    final index = last.lastIndexOf('.');
    if (index == -1 || index == last.length - 1) {
      return '.mp3';
    }
    return last.substring(index);
  }

  String _extensionForMime(String mimeType) {
    final lower = mimeType.toLowerCase();
    if (lower.contains('mp4')) return '.mp4';
    if (lower.contains('m4a')) return '.m4a';
    if (lower.contains('aac')) return '.aac';
    if (lower.contains('wav')) return '.wav';
    return '.mp3';
  }

  static Future<http.Response> _defaultGet(
    Uri uri,
    Map<String, String> headers,
  ) {
    return http.get(uri, headers: headers);
  }
}
