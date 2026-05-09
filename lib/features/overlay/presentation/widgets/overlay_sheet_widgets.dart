import 'package:flutter/material.dart';

class OverlayHeader extends StatelessWidget {
  const OverlayHeader({
    super.key,
    required this.stateLabel,
    required this.onClose,
  });

  final String stateLabel;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF56C7FF), Color(0xFF8E5BFF)],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.graphic_eq, color: Colors.white, size: 17),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Baigalaa',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
              Text(
                stateLabel,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.66)),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Close',
          onPressed: onClose,
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.close, color: Colors.white),
        ),
      ],
    );
  }
}

class OverlayMicOrb extends StatelessWidget {
  const OverlayMicOrb({super.key, required this.isListening});

  final bool isListening;

  @override
  Widget build(BuildContext context) {
    final glow = isListening
        ? const Color(0xFF56C7FF)
        : const Color(0xFFA799FF);
    return SizedBox(
      width: 58,
      height: 58,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            width: isListening ? 58 : 48,
            height: isListening ? 58 : 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: glow.withValues(alpha: 0.22)),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            width: isListening ? 46 : 42,
            height: isListening ? 46 : 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [glow, const Color(0xFF8E5BFF)]),
              boxShadow: [
                BoxShadow(
                  color: glow.withValues(alpha: isListening ? 0.34 : 0.16),
                  blurRadius: 16,
                ),
              ],
            ),
            child: const Icon(Icons.mic, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }
}

class OverlayTranscript extends StatelessWidget {
  const OverlayTranscript({
    super.key,
    required this.transcript,
    required this.response,
  });

  final String transcript;
  final String response;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          transcript.isEmpty ? 'Listening...' : transcript,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          response.isEmpty ? 'Say a short command.' : response,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.72),
            fontSize: 12,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class OverlayActions extends StatelessWidget {
  const OverlayActions({
    super.key,
    required this.isListening,
    required this.onAgain,
    required this.onDone,
  });

  final bool isListening;
  final VoidCallback onAgain;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isListening ? null : onAgain,
            icon: const Icon(Icons.mic, size: 18),
            label: const Text('Again'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white.withValues(alpha: 0.35),
              minimumSize: const Size.fromHeight(36),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.24)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            onPressed: onDone,
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Done'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF7B61FF),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(36),
            ),
          ),
        ),
      ],
    );
  }
}
