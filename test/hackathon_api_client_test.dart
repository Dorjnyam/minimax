import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:minimax/features/api_console/data/hackathon_api_client.dart';

void main() {
  test('client builds collection endpoint requests with bearer auth', () async {
    late Uri capturedUri;
    late Map<String, String> capturedHeaders;
    late Object? capturedBody;
    final client = HackathonApiClient(
      send: (method, uri, headers, body) async {
        capturedUri = uri;
        capturedHeaders = headers;
        capturedBody = body;
        return http.Response('{"ok":true}', 200);
      },
    );

    final result = await client.request(
      baseUrl: 'http://192.168.0.153:8000',
      method: 'POST',
      path: '/api/v1/agents/abc/run',
      token: 'token-1',
      body: {'input': 'hello'},
    );

    expect(
      capturedUri.toString(),
      'http://192.168.0.153:8000/api/v1/agents/abc/run',
    );
    expect(capturedHeaders['Authorization'], 'Bearer token-1');
    expect(capturedBody.toString(), contains('"input":"hello"'));
    expect(result.isSuccess, isTrue);
  });
}
