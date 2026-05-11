import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:minimax/features/api_console/data/hackathon_api_client.dart';

void main() {
  test('GET reminders Uri matches backend expectations', () async {
    Uri? captured;
    final client = HackathonApiClient(
      send: (method, uri, headers, body) async {
        captured = uri;
        expect(method, 'GET');
        expect(body, isNull);
        expect(headers['Authorization'], startsWith('Bearer '));
        return http.Response('{}', 200);
      },
    );

    await client.request(
      baseUrl: 'http://10.255.215.199:8778',
      method: 'GET',
      path: '/api/v1/agents/reminders',
      token: 'tok',
      queryParameters: {'status': 'all', 'limit': '50'},
    );

    final u = captured!;
    expect(
      u.toString().startsWith(
        'http://10.255.215.199:8778/api/v1/agents/reminders?',
      ),
      isTrue,
    );
    expect(u.path, '/api/v1/agents/reminders');
    expect(u.queryParameters['status'], 'all');
    expect(u.queryParameters['limit'], '50');
  });

  test('trailing slash path builds correctly', () async {
    Uri? captured;
    final client = HackathonApiClient(
      send: (method, uri, headers, body) async {
        captured = uri;
        return http.Response('{}', 200);
      },
    );

    await client.request(
      baseUrl: 'http://10.255.215.199:8778/',
      method: 'GET',
      path: '/api/v1/agents/reminders',
      token: 'tok',
      queryParameters: {'status': 'all', 'limit': '50'},
    );

    expect(captured!.path, '/api/v1/agents/reminders');
  });
}
