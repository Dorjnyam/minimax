import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/baigalaa_shell.dart';
import '../bloc/auth_cubit.dart';
import '../data/auth_repository.dart';
import '../data/auth_storage.dart';
import '../gate/auth_gate_cubit.dart';
import '../gate/auth_gate_state.dart';
import 'auth_onboarding_page.dart';
import 'auth_page.dart';
import 'auth_splash_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    this.storage = const SecureAuthStorage(),
  });

  final AuthStorage storage;

  @override
  Widget build(BuildContext context) {
    final repository = context.read<AuthRepository>();
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AuthGateCubit(
            repository: repository,
            storage: storage,
          )..start(),
        ),
        BlocProvider(
          create: (_) => AuthCubit(repository: repository, storage: storage),
        ),
      ],
      child: const _AuthGateView(),
    );
  }
}

class _AuthGateView extends StatelessWidget {
  const _AuthGateView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthGateCubit, AuthGateState>(
      builder: (context, state) {
        return switch (state.stage) {
          AuthGateStage.splash => const AuthSplashPage(),
          AuthGateStage.onboarding => AuthOnboardingPage(
            onGetStarted: () =>
                unawaited(context.read<AuthGateCubit>().completeOnboarding()),
          ),
          AuthGateStage.auth => AuthPage(
            onEnterApp: context.read<AuthGateCubit>().enterApp,
          ),
          AuthGateStage.app => const BaigalaaShell(),
        };
      },
    );
  }
}
