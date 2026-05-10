import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/constants/baigalaa_constants.dart';
import '../../auth_user_messages.dart';
import '../../bloc/auth_cubit.dart';
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
                    enableSuggestions: false,
                    autocorrect: false,
                    inputFormatters: [
                      FilteringTextInputFormatter.deny(RegExp(r'\s')),
                    ],
                    smartDashesType: SmartDashesType.disabled,
                    smartQuotesType: SmartQuotesType.disabled,
                    validator: _emailValidator,
                    darkNeon: true,
                  ),
                  AuthTextField(
                    controller: widget.fullName,
                    label: 'БҮТЭН НЭР',
                    textInputAction: TextInputAction.next,
                    autofillHints: const [],
                    enableSuggestions: false,
                    autocorrect: false,
                    validator: _nameValidator,
                    darkNeon: true,
                  ),
                  AuthTextField(
                    controller: widget.phone,
                    label: 'УТАСНЫ ДУГААР',
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [],
                    enableSuggestions: false,
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
                color: const Color(0xFFE8DEF8),
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
                enableSuggestions: false,
                autocorrect: false,
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r'\s')),
                ],
                smartDashesType: SmartDashesType.disabled,
                smartQuotesType: SmartQuotesType.disabled,
                validator: _emailValidator,
                darkNeon: true,
              ),
              AuthTextField(
                controller: widget.otp,
                label: 'НЭГ УДААГИЙН КОД',
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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

String? _emailValidator(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) {
    return AuthValidationMessages.emailRequired;
  }
  if (email.length > 254) {
    return AuthValidationMessages.emailTooLong;
  }
  final isValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  return isValid ? null : AuthValidationMessages.emailInvalid;
}

String? _nameValidator(String? value) {
  final name = value?.trim() ?? '';
  if (name.isEmpty) {
    return AuthValidationMessages.nameRequired;
  }
  if (name.length < 2) {
    return AuthValidationMessages.nameTooShort;
  }
  if (name.length > 120) {
    return AuthValidationMessages.nameTooLong;
  }
  return null;
}

String? _phoneValidator(String? value) {
  final raw = (value ?? '').trim();
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (raw.isEmpty) {
    return AuthValidationMessages.phoneRequired;
  }
  if (digits.length < 6) {
    return AuthValidationMessages.phoneInvalid;
  }
  if (digits.length > 15) {
    return AuthValidationMessages.phoneTooLong;
  }
  return null;
}

String? _otpValidator(String? value, bool isRequired) {
  if (!isRequired) {
    return null;
  }
  final otp = value?.trim() ?? '';
  if (otp.isEmpty) {
    return AuthValidationMessages.otpRequired;
  }
  if (otp.length < 4) {
    return AuthValidationMessages.otpTooShort;
  }
  return null;
}
