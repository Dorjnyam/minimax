import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:minimax/features/api_console/data/hackathon_api_client.dart';
import 'package:minimax/features/auth/data/auth_repository.dart';
import 'package:minimax/features/auth/domain/auth_models.dart';

void main() {
  test('sign up sends expected endpoint and body', () async {
    late Uri uri;
    late Object? body;
    final repo = AuthRepository(
      client: HackathonApiClient(
        send: (method, requestUri, headers, requestBody) async {
          uri = requestUri;
          body = requestBody;
          return http.Response('{"email":"themargad@gmail.com"}', 200);
        },
      ),
    );

    await repo.signUp(
      baseUrl: 'http://192.168.0.153:8000',
      email: 'themargad@gmail.com',
      fullName: 'Маргад-Эрдэнэ',
      phone: '80197747',
    );

    expect(uri.path, '/api/v1/auth/signup');
    expect(body.toString(), contains('"timezone":"Asia/Ulaanbaatar"'));
    expect(body.toString(), contains('"language":"mn"'));
  });

  test('token parser supports common access and refresh keys', () {
    expect(
      AuthSession.fromData({
        'data': {'access_token': 'a1', 'refresh_token': 'r1'},
      }),
      const AuthSession(accessToken: 'a1', refreshToken: 'r1'),
    );
    expect(
      AuthSession.fromData({'token': 'a2', 'refresh': 'r2'}),
      const AuthSession(accessToken: 'a2', refreshToken: 'r2'),
    );
  });

  test('profile parser supports signup-style user fields', () {
    final user = AuthUser.fromData({
      'email': 'themargad@gmail.com',
      'full_name': 'Маргад-Эрдэнэ',
      'phone': '80197747',
    });

    expect(user.email, 'themargad@gmail.com');
    expect(user.fullName, 'Маргад-Эрдэнэ');
    expect(user.phone, '80197747');
  });
}
