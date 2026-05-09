import 'dart:async';

import 'package:flutter/material.dart';

import '../../bloc/auth_cubit.dart';
import '../../domain/auth_models.dart';
import 'auth_fields.dart';

class ConnectionPanel extends StatelessWidget {
  const ConnectionPanel({
    super.key,
    required this.baseUrl,
    required this.isBusy,
    required this.onSave,
  });

  final TextEditingController baseUrl;
  final bool isBusy;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white.withValues(alpha: 0.94),
      child: ExpansionTile(
        leading: const Icon(Icons.tune),
        title: const Text('Backend address'),
        subtitle: const Text('http://192.168.0.153:8000'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          AuthTextField(
            controller: baseUrl,
            label: 'Base URL',
            icon: Icons.link,
            keyboardType: TextInputType.url,
          ),
          Text(
            'Use the LAN IP of the computer running the backend.',
            style: TextStyle(color: Colors.black.withValues(alpha: 0.55)),
          ),
          const SizedBox(height: 10),
          AuthActionButton(
            label: 'Save URL',
            icon: Icons.save,
            isBusy: isBusy,
            onPressed: onSave,
          ),
        ],
      ),
    );
  }
}

class SignUpSection extends StatefulWidget {
  const SignUpSection({
    super.key,
    required this.cubit,
    required this.baseUrl,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.isBusy,
  });

  final AuthCubit cubit;
  final TextEditingController baseUrl;
  final TextEditingController email;
  final TextEditingController fullName;
  final TextEditingController phone;
  final bool isBusy;

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
        baseUrl: widget.baseUrl.text,
        email: widget.email.text.trim(),
        fullName: widget.fullName.text.trim(),
        phone: widget.phone.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthPanel(
      title: 'Create account',
      children: [
        Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enter your details once, then verify your email with OTP.',
                style: TextStyle(color: Colors.black.withValues(alpha: 0.58)),
              ),
              const SizedBox(height: 12),
              AuthTextField(
                controller: widget.email,
                label: 'Email',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: _emailValidator,
              ),
              AuthTextField(
                controller: widget.fullName,
                label: 'Full name',
                icon: Icons.person,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                validator: _nameValidator,
              ),
              AuthTextField(
                controller: widget.phone,
                label: 'Phone',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.telephoneNumber],
                validator: _phoneValidator,
              ),
              AuthActionButton(
                label: 'Create account',
                icon: Icons.person_add,
                isBusy: widget.isBusy,
                onPressed: _submit,
              ),
            ],
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
    required this.baseUrl,
    required this.email,
    required this.otp,
    required this.isBusy,
  });

  final AuthCubit cubit;
  final TextEditingController baseUrl;
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
        baseUrl: widget.baseUrl.text,
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
        baseUrl: widget.baseUrl.text,
        email: widget.email.text.trim(),
        otp: widget.otp.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthPanel(
      title: 'Login with OTP',
      children: [
        Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Send a one-time code to your email, then enter it below.',
                style: TextStyle(color: Colors.black.withValues(alpha: 0.58)),
              ),
              const SizedBox(height: 12),
              AuthTextField(
                controller: widget.email,
                label: 'Email',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: _emailValidator,
              ),
              AuthTextField(
                controller: widget.otp,
                label: 'One-time code',
                icon: Icons.password,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.oneTimeCode],
                validator: (value) => _otpValidator(value, _requireOtp),
              ),
              FilledButton.tonalIcon(
                onPressed: widget.isBusy ? null : _sendOtp,
                icon: const Icon(Icons.sms),
                label: const Text('Send OTP'),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: widget.isBusy ? null : _verifyOtp,
                icon: const Icon(Icons.verified),
                label: const Text('Verify OTP'),
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
    required this.baseUrl,
    required this.user,
    required this.hasToken,
    required this.isBusy,
    required this.onEnterApp,
    required this.onLogout,
  });

  final AuthCubit cubit;
  final TextEditingController baseUrl;
  final AuthUser user;
  final bool hasToken;
  final bool isBusy;
  final VoidCallback onEnterApp;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return AuthPanel(
      title: 'Profile',
      children: [
        _ProfileRow(label: 'Email', value: user.email),
        _ProfileRow(label: 'Full name', value: user.fullName),
        _ProfileRow(label: 'Phone', value: user.phone),
        const SizedBox(height: 8),
        AuthActionButton(
          label: 'Refresh profile',
          icon: Icons.account_circle,
          isBusy: isBusy,
          enabled: hasToken,
          onPressed: () => unawaited(cubit.loadProfile(baseUrl: baseUrl.text)),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: hasToken ? onEnterApp : null,
          icon: const Icon(Icons.arrow_forward),
          label: const Text('Enter App'),
        ),
        OutlinedButton.icon(
          onPressed: isBusy ? null : onLogout,
          icon: const Icon(Icons.logout),
          label: const Text('Logout'),
        ),
      ],
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 86,
            child: Text(
              label,
              style: TextStyle(color: Colors.black.withValues(alpha: 0.56)),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
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
