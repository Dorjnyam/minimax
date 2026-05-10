import 'package:flutter/material.dart';

class AssistantMicControls extends StatelessWidget {
  const AssistantMicControls({
    super.key,
    required this.isListening,
    required this.onMicPressed,
    required this.onClosePressed,
    required this.onMessagesPressed,
    this.showMessages = true,
    this.compact = false,
  });

  final bool isListening;
  final VoidCallback onMicPressed;
  final VoidCallback onClosePressed;
  final VoidCallback onMessagesPressed;

  /// When false, the leading messages button is omitted (e.g. overlay isolate).
  final bool showMessages;

  /// Smaller mic rings and buttons for narrow contexts (floating overlay).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ringLarge = compact ? 56.0 : 92.0;
    final ringStep = compact ? 14.0 : 28.0;
    final ringIdle = compact ? 48.0 : 82.0;
    final ringIdleStep = compact ? 12.0 : 20.0;
    final iconSize = compact ? 26.0 : 38.0;
    final micPadding = compact ? 11.0 : 22.0;
    final blur = compact ? 14.0 : 28.0;
    final spread = compact ? 2.0 : 4.0;
    final sideSlot = compact ? 40.0 : 48.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        showMessages
            ? _CircleIconButton(
                icon: Icons.chat_bubble_outline,
                tooltip: 'Messages',
                onPressed: onMessagesPressed,
                compact: compact,
              )
            : SizedBox(width: sideSlot),
        Stack(
          alignment: Alignment.center,
          children: [
            for (var i = 0; i < 3; i++)
              AnimatedContainer(
                duration: Duration(milliseconds: 220 + i * 60),
                width: isListening
                    ? ringLarge + i * ringStep
                    : ringIdle + i * ringIdleStep,
                height: isListening
                    ? ringLarge + i * ringStep
                    : ringIdle + i * ringIdleStep,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.07 + i * 0.035),
                  ),
                ),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                  colors: [Color(0xFF54C7FF), Color(0xFF9966FF)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x775E7CFF),
                    blurRadius: blur,
                    spreadRadius: spread,
                  ),
                ],
              ),
              child: IconButton(
                tooltip: isListening ? 'Stop and send' : 'Speak',
                onPressed: onMicPressed,
                iconSize: iconSize,
                color: Colors.white,
                padding: EdgeInsets.all(micPadding),
                icon: Icon(
                  isListening ? Icons.stop_rounded : Icons.mic_none_rounded,
                ),
              ),
            ),
          ],
        ),
        _CircleIconButton(
          icon: Icons.close,
          tooltip: 'Clear',
          onPressed: onClosePressed,
          compact: compact,
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.compact = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        color: Colors.white.withValues(alpha: 0.04),
      ),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        color: Colors.white,
        iconSize: compact ? 20 : 24,
        padding: compact ? const EdgeInsets.all(8) : const EdgeInsets.all(12),
        constraints: BoxConstraints(
          minWidth: compact ? 36 : 48,
          minHeight: compact ? 36 : 48,
        ),
        visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
        icon: Icon(icon),
      ),
    );
  }
}
