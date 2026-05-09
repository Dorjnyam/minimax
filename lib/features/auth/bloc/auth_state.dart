import 'package:equatable/equatable.dart';

import '../domain/auth_models.dart';

enum AuthStatus { initial, loading, success, failure }

enum AuthView { signUp, login, profile }

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.initial,
    this.view = AuthView.login,
    this.baseUrl = '',
    this.email = '',
    this.session = const AuthSession(accessToken: '', refreshToken: ''),
    this.user = const AuthUser(email: '', fullName: '', phone: ''),
    this.errorMessage = '',
  });

  final AuthStatus status;
  final AuthView view;
  final String baseUrl;
  final String email;
  final AuthSession session;
  final AuthUser user;
  final String errorMessage;

  bool get isBusy => status == AuthStatus.loading;
  bool get hasAccessToken => session.hasAccessToken;

  AuthState copyWith({
    AuthStatus? status,
    AuthView? view,
    String? baseUrl,
    String? email,
    AuthSession? session,
    AuthUser? user,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      view: view ?? this.view,
      baseUrl: baseUrl ?? this.baseUrl,
      email: email ?? this.email,
      session: session ?? this.session,
      user: user ?? this.user,
      errorMessage: clearError ? '' : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    view,
    baseUrl,
    email,
    session,
    user,
    errorMessage,
  ];
}
