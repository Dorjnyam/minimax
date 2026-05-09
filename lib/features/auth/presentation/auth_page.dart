import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/constants/baigalaa_constants.dart';
import '../bloc/auth_cubit.dart';
import '../bloc/auth_state.dart';
import 'auth_splash_page.dart';
import 'auth_theme.dart';
import 'widgets/auth_hero_lottie.dart';
import 'widgets/auth_sections.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, this.onEnterApp, this.onLogout});

  final VoidCallback? onEnterApp;
  final VoidCallback? onLogout;

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

  Future<void> _logout(AuthCubit cubit) async {
    await cubit.logout();
    widget.onLogout?.call();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final cubit = context.read<AuthCubit>();
        final isProfile = state.view == AuthView.profile;
        final listPad = EdgeInsets.fromLTRB(20, 0, 20, isProfile ? 32 : 40);
        return Scaffold(
          body: DecoratedBox(
            decoration: BoxDecoration(gradient: AuthTheme.backgroundGradient),
            child: SafeArea(
              child: ListView(
                padding: listPad,
                children: [
                  _AuthHero(state: state),
                  SizedBox(height: state.view == AuthView.profile ? 20 : 28),
                  if (state.view == AuthView.profile)
                    ProfileSection(
                      cubit: cubit,
                      user: state.user,
                      hasToken: state.hasAccessToken,
                      isBusy: state.isBusy,
                      onEnterApp: widget.onEnterApp ?? () {},
                      onLogout: () => unawaited(_logout(cubit)),
                    )
                  else if (state.view == AuthView.signUp)
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
                            color: AuthTheme.primary.withValues(alpha: 0.95),
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
    final brandChip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AuthTheme.primary.withValues(alpha: 0.35)),
        color: AuthTheme.primary.withValues(alpha: 0.06),
      ),
      child: const Text(
        'Baigalaa',
        style: TextStyle(
          color: AuthTheme.primary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );

    final headline = switch (state.view) {
      AuthView.signUp => 'Бүртгэл үүсгэх',
      AuthView.profile => 'Миний бүртгэл',
      AuthView.login => 'Нэвтрэх',
    };

    if (state.view == AuthView.profile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          brandChip,
          const SizedBox(height: 14),
          Text(
            headline,
            style: const TextStyle(
              color: AuthTheme.onSurface,
              fontSize: 30,
              height: 1.08,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 22),
          Center(child: _profileOrb()),
        ],
      );
    }

    final graphic = _glowingLottie(context, switch (state.view) {
      AuthView.signUp => Icons.person_add_alt_1,
      _ => Icons.graphic_eq,
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
            color: AuthTheme.onSurface,
            fontSize: state.view == AuthView.signUp ? 20 : 28,
            height: 1.05,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _profileOrb() {
    return SizedBox(
      height: 132,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AuthTheme.primaryContainer.withValues(alpha: 0.12),
              boxShadow: [
                BoxShadow(
                  color: AuthTheme.primaryContainer.withValues(alpha: 0.22),
                  blurRadius: 36,
                  spreadRadius: -6,
                ),
              ],
            ),
          ),
          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AuthTheme.primaryContainer,
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 42,
              color: AuthTheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
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
          color: AuthTheme.statusSurface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: AuthTheme.outlineVariant.withValues(alpha: 0.35),
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
                  color: AuthTheme.onErrorContainer,
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
