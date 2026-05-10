import 'package:flutter/material.dart';

/// Shell gradient shared by [AssistantPage], profile, reminders, groups, etc.
abstract final class BaigalaaAssistantShell {
  static const BoxDecoration boxDecoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF14233D),
        Color(0xFF5855B0),
        Color(0xFF191C32),
      ],
    ),
  );

  /// Horizontal padding aligned with the assistant content column.
  static const EdgeInsets pagePadding = EdgeInsets.fromLTRB(22, 8, 22, 16);

  static const Color accentText = Color(0xFFEDEBFF);
  static const Color errorText = Color(0xFFFFB8B8);
  static const Color progressIndicator = Color(0xFF5855B0);
}
