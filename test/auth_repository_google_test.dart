import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:minimax/features/api_console/data/hackathon_api_client.dart';
import 'package:minimax/features/auth/data/auth_repository.dart';

void main() {
  test('googleConnectUri returns Uri from JSON url field', () async {
    final repo = AuthRepository(
      client: HackathonApiClient(
        send: (method, uri, headers, body) async {
          expect(method, 'GET');
          expect(uri.path, contains('integrations/google/connect'));
          expect(headers['Authorization'], isNotNull);
          return http.Response(
            jsonEncode({'authorization_url': 'https://oauth.example/start'}),
            200,
          );
        },
      ),
    );

    final uri = await repo.googleConnectUri(
      baseUrl: 'http://api.test',
      accessToken: 'token',
    );
    expect(uri.toString(), 'https://oauth.example/start');
  });

  test('googleIntegrationStatus parses body', () async {
    final repo = AuthRepository(
      client: HackathonApiClient(
        send: (method, uri, headers, body) async {
          expect(uri.path, contains('integrations/google/status'));
          return http.Response(
            jsonEncode({
              'connected': true,
              'email': 'user@gmail.com',
            }),
            200,
          );
        },
      ),
    );

    final s = await repo.googleIntegrationStatus(
      baseUrl: 'http://api.test',
      accessToken: 'token',
    );
    expect(s.connected, isTrue);
    expect(s.email, 'user@gmail.com');
  });
}
