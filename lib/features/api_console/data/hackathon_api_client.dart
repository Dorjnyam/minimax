import 'dart:convert';

import 'package:http/http.dart' as http;

typedef ApiHttpSend =
    Future<http.Response> Function(
      String method,
      Uri uri,
      Map<String, String> headers,
      Object? body,
    );

class ApiCallResult {
  const ApiCallResult({
    required this.statusCode,
    required this.data,
    required this.rawBody,
  });

  final int statusCode;
  final Object? data;
  final String rawBody;

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}

class HackathonApiClient {
  const HackathonApiClient({ApiHttpSend? send}) : _send = send ?? _defaultSend;

  final ApiHttpSend _send;

  Future<ApiCallResult> request({
    required String baseUrl,
    required String method,
    required String path,
    String? token,
    Map<String, Object?>? body,
  }) async {
    final uri = _uri(baseUrl, path);
    final headers = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
      if (token != null && token.trim().isNotEmpty)
        'Authorization': 'Bearer ${token.trim()}',
    };
    final response = await _send(
      method,
      uri,
      headers,
      body == null ? null : jsonEncode(body),
    );
    final raw = utf8.decode(response.bodyBytes);
    return ApiCallResult(
      statusCode: response.statusCode,
      data: _decode(raw),
      rawBody: raw,
    );
  }

  Uri _uri(String baseUrl, String path) {
    final cleanBase = baseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    if (cleanBase.isEmpty) {
      throw ArgumentError('Base URL is required.');
    }
    return Uri.parse('$cleanBase$path');
  }

  Object? _decode(String raw) {
    if (raw.trim().isEmpty) {
      return null;
    }
    try {
      return jsonDecode(raw);
    } catch (_) {
      return raw;
    }
  }

  static Future<http.Response> _defaultSend(
    String method,
    Uri uri,
    Map<String, String> headers,
    Object? body,
  ) {
    return switch (method.toUpperCase()) {
      'GET' => http.get(uri, headers: headers),
      'POST' => http.post(uri, headers: headers, body: body),
      'PATCH' => http.patch(uri, headers: headers, body: body),
      _ => throw ArgumentError('Unsupported method: $method'),
    };
  }
}
