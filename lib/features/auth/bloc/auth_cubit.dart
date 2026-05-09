import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/constants/baigalaa_constants.dart';
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
       super(const AuthState());

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

  Future<void> saveBaseUrl(String baseUrl) async {
    final clean = baseUrl.trim();
    await _storage.write(apiBaseUrlStorageKey, clean);
    emit(state.copyWith(baseUrl: clean));
  }

  Future<void> signUp({
    required String baseUrl,
    required String email,
    required String fullName,
    required String phone,
  }) async {
    await _run('Signing up...', () async {
      await saveBaseUrl(baseUrl);
      final user = await _repository.signUp(
        baseUrl: baseUrl,
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
          message: 'Sign up complete. Send OTP to log in.',
          clearError: true,
        ),
      );
    });
  }

  Future<void> sendOtp({required String baseUrl, required String email}) async {
    await _run('Sending OTP...', () async {
      await saveBaseUrl(baseUrl);
      await _repository.sendOtp(baseUrl: baseUrl, email: email);
      await _storage.write(authLastEmailStorageKey, email);
      emit(
        state.copyWith(
          status: AuthStatus.success,
          view: AuthView.login,
          email: email,
          message: 'OTP sent.',
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
    await _run('Verifying OTP...', () async {
      await saveBaseUrl(baseUrl);
      final session = await _repository.verifyOtp(
        baseUrl: baseUrl,
        email: email,
        otp: otp,
      );
      await _saveSession(session);
      await _storage.write(authLastEmailStorageKey, email);
      emit(
        state.copyWith(
          status: AuthStatus.success,
          session: session,
          email: email,
          message: 'Login successful.',
          clearError: true,
        ),
      );
      final user = await _repository.me(
        baseUrl: baseUrl,
        accessToken: session.accessToken,
      );
      await _saveUser(user);
      emit(
        state.copyWith(
          status: AuthStatus.success,
          view: AuthView.profile,
          user: user,
          message: 'Profile loaded.',
          clearError: true,
        ),
      );
    });
  }

  Future<void> refresh({required String baseUrl}) async {
    await _run('Refreshing token...', () async {
      await saveBaseUrl(baseUrl);
      final session = await _repository.refresh(
        baseUrl: baseUrl,
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
          message: 'Token refreshed.',
          clearError: true,
        ),
      );
    });
  }

  Future<void> loadProfile({String? baseUrl, String? accessToken}) async {
    final url = baseUrl ?? state.baseUrl;
    final token = accessToken ?? state.session.accessToken;
    await _run('Loading profile...', () async {
      final user = await _repository.me(baseUrl: url, accessToken: token);
      await _saveUser(user);
      emit(
        state.copyWith(
          status: AuthStatus.success,
          view: AuthView.profile,
          user: user,
          message: 'Profile loaded.',
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
        message: 'Logged out.',
        clearError: true,
      ),
    );
  }

  Future<void> _run(String message, Future<void> Function() action) async {
    emit(
      state.copyWith(
        status: AuthStatus.loading,
        message: message,
        clearError: true,
      ),
    );
    try {
      await action();
    } catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          message: 'Request failed.',
          errorMessage: error.toString(),
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
    await _storage.delete(authProfileEmailStorageKey);
    await _storage.delete(authProfileFullNameStorageKey);
    await _storage.delete(authProfilePhoneStorageKey);
  }

  String _validBaseUrl(String? value) {
    final clean = value?.trim() ?? '';
    if (clean.isEmpty ||
        clean == defaultApiBaseUrl ||
        clean == 'http://localhost:8000' ||
        clean == 'http://192.168.0.153/:8000') {
      return state.baseUrl;
    }
    return clean;
  }
}
