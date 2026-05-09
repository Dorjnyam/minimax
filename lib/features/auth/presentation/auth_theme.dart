import 'package:flutter/material.dart';

/// Material 3–style tokens for light auth screens (matches Stitch / design/stitch HTML).
abstract final class AuthTheme {
  static const Color background = Color(0xFFFDF7FF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLow = Color(0xFFF8F2FA);
  static const Color primary = Color(0xFF4F378A);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF6750A4);
  static const Color onPrimaryContainer = Color(0xFFE0D2FF);
  static const Color onSurface = Color(0xFF1D1B20);
  static const Color onSurfaceVariant = Color(0xFF494551);
  static const Color fieldFill = Color(0xFFF5F3FF);
  static const Color outlineVariant = Color(0xFFE6E0E9);
  static const Color statusSurface = Color(0xFFECE6EE);
  static const Color error = Color(0xFFBA1A1A);
  static const Color onErrorContainer = Color(0xFF93000A);

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFDF7FF), Color(0xFFF8F2FA)],
  );
}
