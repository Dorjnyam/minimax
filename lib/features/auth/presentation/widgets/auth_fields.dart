import 'package:flutter/material.dart';

import '../auth_theme.dart';

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    this.icon,
    this.darkNeon = false,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.enableSuggestions = true,
    this.autocorrect = true,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData? icon;

  /// When true, use light auth chrome (lavender fields on pale background).
  final bool darkNeon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool enableSuggestions;
  final bool autocorrect;
  final FormFieldValidator<String>? validator;

  static const Color _focusRing = AuthTheme.primaryContainer;

  InputDecoration _authFieldDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: AuthTheme.fieldFill,
      labelText: label,
      labelStyle: const TextStyle(
        color: AuthTheme.primary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.1,
      ),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _focusRing.withValues(alpha: 0.55)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AuthTheme.error.withValues(alpha: 0.65)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AuthTheme.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        autofillHints: autofillHints,
        enableSuggestions: enableSuggestions,
        autocorrect: autocorrect,
        validator: validator,
        style: darkNeon
            ? const TextStyle(color: AuthTheme.onSurface, fontWeight: FontWeight.w500)
            : null,
        cursorColor: darkNeon ? AuthTheme.primary : null,
        decoration: darkNeon
            ? _authFieldDecoration()
            : InputDecoration(
                labelText: label,
                prefixIcon: icon == null ? null : Icon(icon),
              ),
      ),
    );
  }
}

class AuthActionButton extends StatelessWidget {
  const AuthActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.isBusy,
    required this.onPressed,
    this.enabled = true,
  });

  final String label;
  final IconData icon;
  final bool isBusy;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: isBusy || !enabled ? null : onPressed,
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
      icon: isBusy
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon),
      label: Text(label),
    );
  }
}

class AuthPanel extends StatelessWidget {
  const AuthPanel({
    super.key,
    required this.title,
    required this.children,
    this.darkNeon = false,
  });

  final String title;
  final List<Widget> children;

  /// When true, use elevated light card (matches Stitch auth card).
  final bool darkNeon;

  @override
  Widget build(BuildContext context) {
    if (darkNeon) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AuthTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AuthTheme.outlineVariant.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title.isNotEmpty) ...[
              Text(
                title,
                style: const TextStyle(
                  color: AuthTheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
            ],
            ...children,
          ],
        ),
      );
    }
    return Card(
      color: AuthTheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AuthTheme.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title.isNotEmpty) ...[
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AuthTheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 14),
            ],
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Primary / outlined actions for light auth flows.
class NeonAuthBarButton extends StatelessWidget {
  const NeonAuthBarButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isBusy = false,
    this.secondary = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isBusy;

  /// Lighter bordered style for secondary actions (e.g. send OTP).
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    final primaryChild = isBusy
        ? const SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: AuthTheme.onPrimary,
            ),
          )
        : Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              letterSpacing: 0.02,
            ),
          );

    final secondaryChild = isBusy
        ? const SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: AuthTheme.primary,
            ),
          )
        : Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              letterSpacing: 0.02,
            ),
          );

    if (secondary) {
      return SizedBox(
        height: 48,
        width: double.infinity,
        child: OutlinedButton(
          onPressed: isBusy ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AuthTheme.primary,
            side: const BorderSide(color: AuthTheme.primary, width: 2),
            backgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          child: secondaryChild,
        ),
      );
    }

    return SizedBox(
      height: 48,
      width: double.infinity,
      child: FilledButton(
        onPressed: isBusy ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AuthTheme.primary,
          foregroundColor: AuthTheme.onPrimary,
          disabledForegroundColor: AuthTheme.onPrimary.withValues(alpha: 0.65),
          disabledBackgroundColor: AuthTheme.primary.withValues(alpha: 0.38),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: primaryChild,
      ),
    );
  }
}
