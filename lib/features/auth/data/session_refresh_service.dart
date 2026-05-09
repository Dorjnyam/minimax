import '../../../shared/constants/baigalaa_constants.dart';
import '../domain/auth_models.dart';
import 'auth_repository.dart';
import 'auth_storage.dart';

/// Supplies a valid access token, refreshing via [AuthRepository.refresh] when
/// `/auth/me` fails (expired access token).
abstract interface class AccessTokenProvider {
  Future<String?> ensureAccessToken({String? baseUrl});
}

/// Test helper: returns a fixed token without calling the API.
final class FixedAccessTokenProvider implements AccessTokenProvider {
  const FixedAccessTokenProvider(this.token);

  final String token;

  @override
  Future<String?> ensureAccessToken({String? baseUrl}) async {
    final t = token.trim();
    return t.isEmpty ? null : t;
  }
}

final class SessionRefreshService implements AccessTokenProvider {
  SessionRefreshService({
    required AuthRepository repository,
    required AuthStorage storage,
  }) : _repository = repository,
       _storage = storage;

  final AuthRepository _repository;
  final AuthStorage _storage;

  @override
  Future<String?> ensureAccessToken({String? baseUrl}) async {
    final resolvedBaseUrl = baseUrl ?? defaultApiBaseUrl;
    final access = await _storage.read(apiAccessTokenStorageKey) ?? '';
    final refresh = await _storage.read(apiRefreshTokenStorageKey) ?? '';

    if (access.isEmpty && refresh.isEmpty) {
      return null;
    }

    if (access.isNotEmpty) {
      try {
        await _repository.me(baseUrl: resolvedBaseUrl, accessToken: access);
        return access;
      } catch (_) {}
    }

    if (refresh.isEmpty) {
      return null;
    }

    try {
      final session = await _repository.refresh(
        baseUrl: resolvedBaseUrl,
        refreshToken: refresh,
      );
      final merged = AuthSession(
        accessToken: session.accessToken.isEmpty ? access : session.accessToken,
        refreshToken: session.refreshToken.isEmpty ? refresh : session.refreshToken,
      );
      if (!merged.hasAccessToken) {
        return null;
      }
      await _storage.write(apiAccessTokenStorageKey, merged.accessToken);
      await _storage.write(apiRefreshTokenStorageKey, merged.refreshToken);
      await _repository.me(baseUrl: resolvedBaseUrl, accessToken: merged.accessToken);
      return merged.accessToken;
    } catch (_) {
      return null;
    }
  }
}
