import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/constants/baigalaa_constants.dart';
import '../data/auth_repository.dart';
import '../data/auth_storage.dart';
import '../domain/auth_models.dart';
import 'auth_gate_state.dart';

class AuthGateCubit extends Cubit<AuthGateState> {
  AuthGateCubit({
    required AuthRepository repository,
    required AuthStorage storage,
  }) : _repository = repository,
       _storage = storage,
       super(const AuthGateState());

  final AuthRepository _repository;
  final AuthStorage _storage;

  /// Opens auth immediately (no splash / onboarding). Valid session → app shell.
  Future<void> start() async {
    emit(const AuthGateState());
    await _restoreSession();
  }

  Future<void> completeOnboarding() async {
    await _storage.write(authOnboardingCompletedStorageKey, 'true');
    await _restoreSession();
  }

  void enterApp() {
    emit(
      const AuthGateState(stage: AuthGateStage.app, message: 'Authenticated.'),
    );
  }

  void showAuth() {
    emit(
      const AuthGateState(stage: AuthGateStage.auth, message: 'Please log in.'),
    );
  }

  Future<void> signOut() async {
    await _clearSession();
    showAuth();
  }

  Future<void> _restoreSession() async {
    final baseUrl = defaultApiBaseUrl;
    final access = await _storage.read(apiAccessTokenStorageKey) ?? '';
    final refresh = await _storage.read(apiRefreshTokenStorageKey) ?? '';

    if (access.isEmpty && refresh.isEmpty) {
      showAuth();
      return;
    }

    if (await _validateAccess(baseUrl, access)) {
      enterApp();
      return;
    }

    if (await _refreshAndValidate(baseUrl, refresh)) {
      enterApp();
      return;
    }

    await _clearSession();
    showAuth();
  }

  Future<bool> _validateAccess(String baseUrl, String access) async {
    if (access.isEmpty) {
      return false;
    }
    try {
      final user = await _repository.me(baseUrl: baseUrl, accessToken: access);
      await _saveUser(user);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _refreshAndValidate(String baseUrl, String refresh) async {
    if (refresh.isEmpty) {
      return false;
    }
    try {
      final session = await _repository.refresh(
        baseUrl: baseUrl,
        refreshToken: refresh,
      );
      if (!session.hasAccessToken) {
        return false;
      }
      final nextSession = AuthSession(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken.isEmpty
            ? refresh
            : session.refreshToken,
      );
      await _saveSession(nextSession);
      return _validateAccess(baseUrl, nextSession.accessToken);
    } catch (_) {
      return false;
    }
  }

  Future<void> _saveSession(AuthSession session) async {
    await _storage.write(apiAccessTokenStorageKey, session.accessToken);
    await _storage.write(apiRefreshTokenStorageKey, session.refreshToken);
  }

  Future<void> _saveUser(AuthUser user) async {
    await _storage.write(authProfileEmailStorageKey, user.email);
    await _storage.write(authProfileFullNameStorageKey, user.fullName);
    await _storage.write(authProfilePhoneStorageKey, user.phone);
  }

  Future<void> _clearSession() async {
    await _storage.delete(apiAccessTokenStorageKey);
    await _storage.delete(apiRefreshTokenStorageKey);
    await _storage.delete(apiConversationIdStorageKey);
    await _storage.delete(authProfileEmailStorageKey);
    await _storage.delete(authProfileFullNameStorageKey);
    await _storage.delete(authProfilePhoneStorageKey);
  }
}
