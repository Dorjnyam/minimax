import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:minimax/features/api_console/data/hackathon_api_client.dart';
import 'package:minimax/features/auth/data/auth_repository.dart';
import 'package:minimax/features/auth/data/auth_storage.dart';
import 'package:minimax/features/auth/gate/auth_gate_cubit.dart';
import 'package:minimax/features/auth/gate/auth_gate_state.dart';
import 'package:minimax/shared/constants/baigalaa_constants.dart';

void main() {
  test('first launch shows onboarding', () async {
    final cubit = AuthGateCubit(
      repository: _repo((method, uri, headers, body) async {
        return http.Response('{}', 500);
      }),
      storage: MemoryAuthStorage(),
      splashDuration: Duration.zero,
    );

    await cubit.start();

    expect(cubit.state.stage, AuthGateStage.onboarding);
  });

  test('saved access token validates profile and enters app', () async {
    final storage = MemoryAuthStorage({
      authOnboardingCompletedStorageKey: 'true',
      apiBaseUrlStorageKey: 'http://api.test',
      apiAccessTokenStorageKey: 'a1',
    });
    String? authHeader;
    final cubit = AuthGateCubit(
      repository: _repo((method, uri, headers, body) async {
        authHeader = headers['Authorization'];
        return _json({
          'email': 'user@test.mn',
          'full_name': 'User',
          'phone': '1',
        });
      }),
      storage: storage,
      splashDuration: Duration.zero,
    );

    await cubit.start();

    expect(cubit.state.stage, AuthGateStage.app);
    expect(authHeader, 'Bearer a1');
    expect(await storage.read(authProfileEmailStorageKey), 'user@test.mn');
  });

  test('expired access token refreshes before entering app', () async {
    final storage = MemoryAuthStorage({
      authOnboardingCompletedStorageKey: 'true',
      apiBaseUrlStorageKey: 'http://api.test',
      apiAccessTokenStorageKey: 'old',
      apiRefreshTokenStorageKey: 'r1',
    });
    final cubit = AuthGateCubit(
      repository: _repo((method, uri, headers, body) async {
        if (uri.path.endsWith('/auth/refresh')) {
          return _json({'access': 'new', 'refresh': 'r2'});
        }
        if (headers['Authorization'] == 'Bearer new') {
          return _json({
            'email': 'user@test.mn',
            'full_name': 'User',
            'phone': '1',
          });
        }
        return http.Response('expired', 401);
      }),
      storage: storage,
      splashDuration: Duration.zero,
    );

    await cubit.start();

    expect(cubit.state.stage, AuthGateStage.app);
    expect(await storage.read(apiAccessTokenStorageKey), 'new');
    expect(await storage.read(apiRefreshTokenStorageKey), 'r2');
  });

  test('invalid saved session clears tokens and shows auth', () async {
    final storage = MemoryAuthStorage({
      authOnboardingCompletedStorageKey: 'true',
      apiAccessTokenStorageKey: 'bad',
      apiRefreshTokenStorageKey: 'bad-refresh',
    });
    final cubit = AuthGateCubit(
      repository: _repo((method, uri, headers, body) async {
        return http.Response('invalid', 401);
      }),
      storage: storage,
      splashDuration: Duration.zero,
    );

    await cubit.start();

    expect(cubit.state.stage, AuthGateStage.auth);
    expect(await storage.read(apiAccessTokenStorageKey), isNull);
    expect(await storage.read(apiRefreshTokenStorageKey), isNull);
  });
}

AuthRepository _repo(ApiHttpSend send) {
  return AuthRepository(client: HackathonApiClient(send: send));
}

http.Response _json(Map<String, Object?> data) {
  return http.Response.bytes(utf8.encode(jsonEncode(data)), 200);
}
