import 'package:flutter/material.dart';

class AssistantMicControls extends StatelessWidget {
  const AssistantMicControls({
    super.key,
    required this.isListening,
    required this.onMicPressed,
    required this.onClosePressed,
  });

  final bool isListening;
  final VoidCallback onMicPressed;
  final VoidCallback onClosePressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _CircleIconButton(icon: Icons.chat_bubble_outline, onPressed: () {}),
        Stack(
          alignment: Alignment.center,
          children: [
            for (var i = 0; i < 3; i++)
              AnimatedContainer(
                duration: Duration(milliseconds: 220 + i * 60),
                width: isListening ? 92 + i * 28 : 82 + i * 20,
                height: isListening ? 92 + i * 28 : 82 + i * 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.07 + i * 0.035),
                  ),
                ),
              ),
            DecoratedBox(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                  colors: [Color(0xFF54C7FF), Color(0xFF9966FF)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x775E7CFF),
                    blurRadius: 28,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: IconButton(
                tooltip: 'Speak',
                onPressed: onMicPressed,
                iconSize: 38,
                color: Colors.white,
                padding: const EdgeInsets.all(22),
                icon: const Icon(Icons.mic_none_rounded),
              ),
            ),
          ],
        ),
        _CircleIconButton(icon: Icons.close, onPressed: onClosePressed),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        color: Colors.white.withValues(alpha: 0.04),
      ),
      child: IconButton(
        tooltip: icon == Icons.close ? 'Clear' : 'Messages',
        onPressed: onPressed,
        color: Colors.white,
        icon: Icon(icon),
      ),
    );
  }
}
