import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../shared/constants/baigalaa_constants.dart';
import '../../bloc/auth_cubit.dart';
import '../../domain/auth_models.dart';
import '../auth_theme.dart';
import 'auth_fields.dart';

class SignUpSection extends StatefulWidget {
  const SignUpSection({
    super.key,
    required this.cubit,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.isBusy,
    required this.onGoLogin,
  });

  final AuthCubit cubit;
  final TextEditingController email;
  final TextEditingController fullName;
  final TextEditingController phone;
  final bool isBusy;
  final VoidCallback onGoLogin;

  @override
  State<SignUpSection> createState() => _SignUpSectionState();
}

class _SignUpSectionState extends State<SignUpSection> {
  final _formKey = GlobalKey<FormState>();

  void _submit() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    unawaited(
      widget.cubit.signUp(
        baseUrl: defaultApiBaseUrl,
        email: widget.email.text.trim(),
        fullName: widget.fullName.text.trim(),
        phone: widget.phone.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthPanel(
          title: '',
          darkNeon: true,
          children: [
            Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start),
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: widget.email,
                    label: 'И-МЭЙЛ',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    validator: _emailValidator,
                    darkNeon: true,
                  ),
                  AuthTextField(
                    controller: widget.fullName,
                    label: 'БҮТЭН НЭР',
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    validator: _nameValidator,
                    darkNeon: true,
                  ),
                  AuthTextField(
                    controller: widget.phone,
                    label: 'УТАСНЫ ДУГААР',
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    validator: _phoneValidator,
                    darkNeon: true,
                  ),
                  NeonAuthBarButton(
                    label: 'Бүртгүүлэх',
                    onPressed: _submit,
                    isBusy: widget.isBusy,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: widget.isBusy ? null : widget.onGoLogin,
            child: Text(
              'Бүртгэлтэй юу? Нэвтрэх',
              style: TextStyle(
                color: AuthTheme.primary.withValues(alpha: 0.95),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class LoginSection extends StatefulWidget {
  const LoginSection({
    super.key,
    required this.cubit,
    required this.email,
    required this.otp,
    required this.isBusy,
  });

  final AuthCubit cubit;
  final TextEditingController email;
  final TextEditingController otp;
  final bool isBusy;

  @override
  State<LoginSection> createState() => _LoginSectionState();
}

class _LoginSectionState extends State<LoginSection> {
  final _formKey = GlobalKey<FormState>();
  bool _requireOtp = false;

  void _sendOtp() {
    setState(() => _requireOtp = false);
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    unawaited(
      widget.cubit.sendOtp(
        baseUrl: defaultApiBaseUrl,
        email: widget.email.text.trim(),
      ),
    );
  }

  void _verifyOtp() {
    setState(() => _requireOtp = true);
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    unawaited(
      widget.cubit.verifyOtp(
        baseUrl: defaultApiBaseUrl,
        email: widget.email.text.trim(),
        otp: widget.otp.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthPanel(
      title: '',
      darkNeon: true,
      children: [
        Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 14),
              AuthTextField(
                controller: widget.email,
                label: 'И-МЭЙЛ',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: _emailValidator,
                darkNeon: true,
              ),
              AuthTextField(
                controller: widget.otp,
                label: 'НЭГ УДААГИЙН КОД',
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.oneTimeCode],
                validator: (value) => _otpValidator(value, _requireOtp),
                darkNeon: true,
              ),
              const SizedBox(height: 4),
              NeonAuthBarButton(
                label: 'Код авах',
                secondary: true,
                isBusy: widget.isBusy,
                onPressed: _sendOtp,
              ),
              const SizedBox(height: 10),
              NeonAuthBarButton(
                label: 'Нэвтрэх',
                isBusy: widget.isBusy,
                onPressed: _verifyOtp,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ProfileSection extends StatelessWidget {
  const ProfileSection({
    super.key,
    required this.cubit,
    required this.user,
    required this.hasToken,
    required this.isBusy,
    required this.onEnterApp,
    required this.onLogout,
  });

  final AuthCubit cubit;
  final AuthUser user;
  final bool hasToken;
  final bool isBusy;
  final VoidCallback onEnterApp;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return AuthPanel(
      title: '',
      darkNeon: true,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AuthTheme.surfaceLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AuthTheme.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            children: [
              _ProfileField(
                label: 'И-мэйл',
                value: user.email,
                showDivider: true,
              ),
              _ProfileField(
                label: 'Бүтэн нэр',
                value: user.fullName,
                showDivider: true,
              ),
              _ProfileField(
                label: 'Утасны дугаар',
                value: user.phone,
                showDivider: false,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        NeonAuthBarButton(
          label: 'Профайл шинэчлэх',
          isBusy: isBusy,
          onPressed: (!hasToken || isBusy)
              ? null
              : () => unawaited(cubit.loadProfile(baseUrl: defaultApiBaseUrl)),
        ),
        const SizedBox(height: 10),
        NeonAuthBarButton(
          label: 'Апп нээх',
          onPressed: hasToken ? onEnterApp : null,
          isBusy: false,
        ),
        const SizedBox(height: 10),
        NeonAuthBarButton(
          label: 'Гарах',
          secondary: true,
          onPressed: isBusy ? null : onLogout,
          isBusy: false,
        ),
      ],
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.label,
    required this.value,
    required this.showDivider,
  });

  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final display = value.isEmpty ? '—' : value;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AuthTheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                display,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  height: 1.35,
                  color: AuthTheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: AuthTheme.outlineVariant.withValues(alpha: 0.45),
          ),
      ],
    );
  }
}

String? _emailValidator(String? value) {
  final email = value?.trim() ?? '';
  final isValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  return isValid ? null : 'Enter a valid email address.';
}

String? _nameValidator(String? value) {
  final name = value?.trim() ?? '';
  return name.length >= 2 ? null : 'Enter your full name.';
}

String? _phoneValidator(String? value) {
  final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
  return digits.length >= 6 ? null : 'Enter a valid phone number.';
}

String? _otpValidator(String? value, bool isRequired) {
  if (!isRequired) {
    return null;
  }
  final otp = value?.trim() ?? '';
  return otp.length >= 4 ? null : 'Enter the OTP from your email.';
}
