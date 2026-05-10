import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/constants/baigalaa_constants.dart';
import '../bloc/auth_cubit.dart';
import '../bloc/auth_state.dart';
import 'auth_splash_page.dart' show EntryLogoMark;
import 'auth_theme.dart';
import 'widgets/auth_hero_lottie.dart';
import 'widgets/auth_sections.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, this.onEnterApp});

  final VoidCallback? onEnterApp;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _email = TextEditingController();
  final _fullName = TextEditingController();
  final _phone = TextEditingController();
  final _otp = TextEditingController();

  @override
  void initState() {
    super.initState();
    unawaited(context.read<AuthCubit>().load());
  }

  @override
  void dispose() {
    _email.dispose();
    _fullName.dispose();
    _phone.dispose();
    _otp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listenWhen: (previous, current) =>
          current.status == AuthStatus.success &&
          current.hasAccessToken &&
          !previous.hasAccessToken,
      listener: (context, state) {
        (widget.onEnterApp ?? () {})();
      },
      builder: (context, state) {
        final cubit = context.read<AuthCubit>();
        const listPad = EdgeInsets.fromLTRB(20, 16, 20, 40);
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF14233D),
                  Color(0xFF5855B0),
                  Color(0xFF191C32),
                ],
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: SafeArea(
                child: ListView(
                  padding: listPad,
                  children: [
                  _AuthHero(state: state),
                  const SizedBox(height: 28),
                  if (state.view == AuthView.signUp)
                    SignUpSection(
                      cubit: cubit,
                      email: _email,
                      fullName: _fullName,
                      phone: _phone,
                      isBusy: state.isBusy,
                      onGoLogin: () => cubit.show(AuthView.login),
                    )
                  else ...[
                    LoginSection(
                      cubit: cubit,
                      email: _email,
                      otp: _otp,
                      isBusy: state.isBusy,
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: TextButton(
                        onPressed: state.isBusy
                            ? null
                            : () => cubit.show(AuthView.signUp),
                        child: Text(
                          'Бүртгэл байхгүй юу? Бүртгүүлэх',
                          style: TextStyle(
                            color: const Color(0xFFE8DEF8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (state.errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _AuthErrorBanner(message: state.errorMessage),
                  ],
                ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AuthHero extends StatelessWidget {
  const _AuthHero({required this.state});

  final AuthState state;

  @override
  Widget build(BuildContext context) {
    final headline = switch (state.view) {
      AuthView.signUp => 'Бүртгэл үүсгэх',
      AuthView.login => 'Нэвтрэх',
    };

    final graphic = _glowingLottie(context, switch (state.view) {
      AuthView.signUp => Icons.person_add_alt_1,
      AuthView.login => Icons.graphic_eq,
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: double.infinity,
          child: Center(child: graphic),
        ),
        const SizedBox(height: 22),
        Text(
          headline,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.94),
            fontSize: state.view == AuthView.signUp ? 20 : 20,
            height: 1.05,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _glowingLottie(BuildContext context, IconData icon) {
    return SizedBox(
      height: 220,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 210,
            height: 210,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AuthTheme.primaryContainer.withValues(alpha: 0.38),
                  AuthTheme.primaryContainer.withValues(alpha: 0),
                ],
                stops: const [0.15, 0.92],
              ),
              boxShadow: [
                BoxShadow(
                  color: AuthTheme.primaryContainer.withValues(alpha: 0.28),
                  blurRadius: 40,
                  spreadRadius: -8,
                ),
              ],
            ),
          ),
          AuthHeroLottie(
            fallback: EntryLogoMark(icon: icon),
            size: 196,
            asset: authHeroLottieAsset,
          ),
        ],
      ),
    );
  }
}

class _AuthErrorBanner extends StatelessWidget {
  const _AuthErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.22),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AuthTheme.error,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFFFDAD6),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
