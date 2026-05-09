import 'package:equatable/equatable.dart';

enum AuthGateStage { splash, onboarding, auth, app }

class AuthGateState extends Equatable {
  const AuthGateState({
    this.stage = AuthGateStage.splash,
    this.message = 'Starting Baigalaa...',
  });

  final AuthGateStage stage;
  final String message;

  AuthGateState copyWith({AuthGateStage? stage, String? message}) {
    return AuthGateState(
      stage: stage ?? this.stage,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [stage, message];
}
