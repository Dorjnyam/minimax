import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_cubit.dart';
import '../bloc/auth_state.dart';
import 'auth_splash_page.dart';
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
  bool _hydrated = false;

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

  void _sync(AuthState state) {
    if (_hydrated) {
      return;
    }
    _set(_email, state.email);
    _set(_fullName, state.user.fullName);
    _set(_phone, state.user.phone);
    _hydrated = true;
  }

  void _set(TextEditingController controller, String value) {
    if (value.isNotEmpty && controller.text != value) {
      controller.text = value;
    }
  }

  Future<void> _logout(AuthCubit cubit) async {
    await cubit.logout();
    widget.onLogout?.call();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (_, state) => _sync(state),
      builder: (context, state) {
        final cubit = context.read<AuthCubit>();
        return Scaffold(
          body: EntryGradient(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                _AuthHero(state: state),
                const SizedBox(height: 22),
                if (state.view == AuthView.profile)
                  ProfileSection(
                    cubit: cubit,
                    user: state.user,
                    hasToken: state.hasAccessToken,
                    isBusy: state.isBusy,
                    onEnterApp: widget.onEnterApp ?? () {},
                    onLogout: () => unawaited(_logout(cubit)),
                  )
                else ...[
                  _AuthTabs(state: state, onChanged: cubit.show),
                  const SizedBox(height: 14),
                  if (state.view == AuthView.signUp)
                    SignUpSection(
                      cubit: cubit,
                      email: _email,
                      fullName: _fullName,
                      phone: _phone,
                      isBusy: state.isBusy,
                    )
                  else
                    LoginSection(
                      cubit: cubit,
                      email: _email,
                      otp: _otp,
                      isBusy: state.isBusy,
                    ),
                ],
                const SizedBox(height: 14),
                _AuthStatus(state: state),
                const SizedBox(height: 14),
                const ConnectionPanel(),
              ],
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
    final (icon, title, body) = switch (state.view) {
      AuthView.signUp => (
        Icons.person_add_alt_1,
        'Create your account',
        'Set up your Baigalaa profile, then verify your email with OTP.',
      ),
      AuthView.profile => (
        Icons.verified_user,
        'Profile ready',
        'Your account is verified. Continue into the assistant.',
      ),
      AuthView.login => (
        Icons.lock_open,
        'Sign in to Baigalaa',
        'Use your email and one-time code to continue securely.',
      ),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EntryLogoMark(icon: icon),
        const SizedBox(height: 22),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 31,
            height: 1.08,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          body,
          style: const TextStyle(
            color: Color(0xFFD7DEFF),
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _AuthTabs extends StatelessWidget {
  const _AuthTabs({required this.state, required this.onChanged});

  final AuthState state;
  final ValueChanged<AuthView> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<AuthView>(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return Colors.white.withValues(alpha: 0.12);
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF20255A);
          }
          return Colors.white;
        }),
      ),
      segments: const [
        ButtonSegment(value: AuthView.login, label: Text('Login')),
        ButtonSegment(value: AuthView.signUp, label: Text('Sign up')),
      ],
      selected: {
        state.view == AuthView.signUp ? AuthView.signUp : AuthView.login,
      },
      onSelectionChanged: (values) => onChanged(values.first),
    );
  }
}

class _AuthStatus extends StatelessWidget {
  const _AuthStatus({required this.state});

  final AuthState state;

  @override
  Widget build(BuildContext context) {
    final isError = state.errorMessage.isNotEmpty;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Text(
          isError ? state.errorMessage : state.message,
          style: TextStyle(
            color: isError ? const Color(0xFFFFCDD2) : const Color(0xFFE5EAFF),
          ),
        ),
      ),
    );
  }
}
