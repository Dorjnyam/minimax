import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:minimax/features/api_console/data/hackathon_api_client.dart';
import 'package:minimax/features/auth/bloc/auth_cubit.dart';
import 'package:minimax/features/auth/bloc/auth_state.dart';
import 'package:minimax/features/auth/data/auth_repository.dart';
import 'package:minimax/features/auth/data/auth_storage.dart';
import 'package:minimax/shared/constants/baigalaa_constants.dart';

void main() {
  test('otp verify saves tokens and loads profile', () async {
    final storage = MemoryAuthStorage();
    final calledPaths = <String>[];
    const fullName =
        '\u041c\u0430\u0440\u0433\u0430\u0434-\u042d\u0440\u0434\u044d\u043d\u044d';
    String? meAuthHeader;

    final cubit = AuthCubit(
      repository: AuthRepository(
        client: HackathonApiClient(
          send: (method, uri, headers, body) async {
            calledPaths.add(uri.path);
            if (uri.path.endsWith('/otp/verify')) {
              return http.Response('{"access":"a1","refresh":"r1"}', 200);
            }
            if (uri.path == '/api/v1/auth/me') {
              meAuthHeader = headers['Authorization'];
              return http.Response.bytes(
                utf8.encode(
                  jsonEncode({
                    'email': 'themargad@gmail.com',
                    'full_name': fullName,
                    'phone': '80197747',
                  }),
                ),
                200,
              );
            }
            return http.Response('{}', 404);
          },
        ),
      ),
      storage: storage,
    );

    await cubit.verifyOtp(
      baseUrl: 'http://192.168.0.153:8000',
      email: 'themargad@gmail.com',
      otp: '111111',
    );

    expect(calledPaths, contains('/api/v1/auth/me'));
    expect(meAuthHeader, 'Bearer a1');
    expect(cubit.state.view, AuthView.profile);
    expect(cubit.state.session.accessToken, 'a1');
    expect(cubit.state.user.fullName, fullName);
  });

  test('failed request surfaces readable error state', () async {
    final cubit = AuthCubit(
      repository: AuthRepository(
        client: HackathonApiClient(
          send: (method, uri, headers, body) async => http.Response('bad', 500),
        ),
      ),
      storage: MemoryAuthStorage(),
    );

    await cubit.sendOtp(
      baseUrl: 'http://192.168.0.153:8000',
      email: 'themargad@gmail.com',
    );

    expect(cubit.state.status, AuthStatus.failure);
    expect(cubit.state.errorMessage, contains('HTTP 500'));
  });

  test('logout clears stored session and profile', () async {
    final storage = MemoryAuthStorage({
      apiAccessTokenStorageKey: 'a1',
      apiRefreshTokenStorageKey: 'r1',
      authProfileEmailStorageKey: 'themargad@gmail.com',
      authProfileFullNameStorageKey: 'User',
      authProfilePhoneStorageKey: '80197747',
    });
    final cubit = AuthCubit(
      repository: AuthRepository(
        client: HackathonApiClient(
          send: (method, uri, headers, body) async => http.Response('{}', 200),
        ),
      ),
      storage: storage,
    );

    await cubit.logout();

    expect(cubit.state.view, AuthView.login);
    expect(cubit.state.hasAccessToken, isFalse);
    expect(await storage.read(apiAccessTokenStorageKey), isNull);
    expect(await storage.read(apiRefreshTokenStorageKey), isNull);
    expect(await storage.read(authProfileEmailStorageKey), isNull);
  });
}
