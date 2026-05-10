import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/constants/baigalaa_constants.dart';
import '../auth_user_messages.dart';
import '../data/auth_repository.dart';
import '../data/auth_storage.dart';
import '../domain/auth_models.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required AuthRepository repository,
    AuthStorage storage = const SecureAuthStorage(),
  }) : _repository = repository,
       _storage = storage,
       super(const AuthState()) {
    emit(state.copyWith(baseUrl: defaultApiBaseUrl));
  }

  final AuthRepository _repository;
  final AuthStorage _storage;

  Future<void> load() async {
    final baseUrl = await _storage.read(apiBaseUrlStorageKey);
    final access = await _storage.read(apiAccessTokenStorageKey);
    final refresh = await _storage.read(apiRefreshTokenStorageKey);
    final email = await _storage.read(authLastEmailStorageKey);
    final profileEmail = await _storage.read(authProfileEmailStorageKey);
    final fullName = await _storage.read(authProfileFullNameStorageKey);
    final phone = await _storage.read(authProfilePhoneStorageKey);

    emit(
      state.copyWith(
        baseUrl: _validBaseUrl(baseUrl),
        email: email?.isNotEmpty == true ? email : state.email,
        session: AuthSession(
          accessToken: access ?? '',
          refreshToken: refresh ?? '',
        ),
        user: AuthUser(
          email: profileEmail ?? '',
          fullName: fullName ?? '',
          phone: phone ?? '',
        ),
      ),
    );
  }

  void show(AuthView view) {
    emit(state.copyWith(view: view, clearError: true));
  }

  Future<void> saveBaseUrl(String _) async {
    await _storage.write(apiBaseUrlStorageKey, defaultApiBaseUrl);
    emit(state.copyWith(baseUrl: defaultApiBaseUrl));
  }

  Future<void> signUp({
    required String baseUrl,
    required String email,
    required String fullName,
    required String phone,
  }) async {
    await _run(() async {
      final url = _validBaseUrl(baseUrl);
      await saveBaseUrl(url);
      final user = await _repository.signUp(
        baseUrl: url,
        email: email,
        fullName: fullName,
        phone: phone,
      );
      await _storage.write(authLastEmailStorageKey, email);
      if (!user.isEmpty) {
        await _saveUser(user);
      }
      emit(
        state.copyWith(
          status: AuthStatus.success,
          view: AuthView.login,
          email: email,
          user: user.isEmpty ? state.user : user,
          clearError: true,
        ),
      );
    });
  }

  Future<void> sendOtp({required String baseUrl, required String email}) async {
    await _run(() async {
      final url = _validBaseUrl(baseUrl);
      await saveBaseUrl(url);
      await _repository.sendOtp(baseUrl: url, email: email);
      await _storage.write(authLastEmailStorageKey, email);
      emit(
        state.copyWith(
          status: AuthStatus.success,
          view: AuthView.login,
          email: email,
          clearError: true,
        ),
      );
    });
  }

  Future<void> verifyOtp({
    required String baseUrl,
    required String email,
    required String otp,
  }) async {
    await _run(() async {
      final url = _validBaseUrl(baseUrl);
      await saveBaseUrl(url);
      final session = await _repository.verifyOtp(
        baseUrl: url,
        email: email,
        otp: otp,
      );
      await _saveSession(session);
      await _storage.write(authLastEmailStorageKey, email);
      final user = await _repository.me(
        baseUrl: url,
        accessToken: session.accessToken,
      );
      await _saveUser(user);
      emit(
        state.copyWith(
          status: AuthStatus.success,
          session: session,
          email: email,
          user: user,
          view: AuthView.login,
          clearError: true,
        ),
      );
    });
  }

  Future<void> refresh({required String baseUrl}) async {
    await _run(() async {
      final url = _validBaseUrl(baseUrl);
      await saveBaseUrl(url);
      final session = await _repository.refresh(
        baseUrl: url,
        refreshToken: state.session.refreshToken,
      );
      final merged = AuthSession(
        accessToken: session.accessToken.isEmpty
            ? state.session.accessToken
            : session.accessToken,
        refreshToken: session.refreshToken.isEmpty
            ? state.session.refreshToken
            : session.refreshToken,
      );
      await _saveSession(merged);
      emit(
        state.copyWith(
          status: AuthStatus.success,
          session: merged,
          clearError: true,
        ),
      );
    });
  }

  Future<void> logout() async {
    await _clearSession();
    emit(
      state.copyWith(
        status: AuthStatus.success,
        view: AuthView.login,
        session: AuthSession.empty(),
        user: AuthUser.empty(),
        clearError: true,
      ),
    );
  }

  Future<void> _run(Future<void> Function() action) async {
    emit(
      state.copyWith(
        status: AuthStatus.loading,
        clearError: true,
      ),
    );
    try {
      await action();
    } catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: AuthExceptionHandler.userMessage(error),
        ),
      );
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

  String _validBaseUrl(String? _) => defaultApiBaseUrl;
}
