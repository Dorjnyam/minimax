import 'package:flutter/material.dart';

import '../overlay_strings.dart';

class OverlayHeader extends StatelessWidget {
  const OverlayHeader({
    super.key,
    required this.stateLabel,
    required this.onClose,
    this.dense = false,
  });

  final String stateLabel;
  final VoidCallback onClose;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final logo = dense ? 22.0 : 30.0;
    final iconSize = dense ? 14.0 : 17.0;
    final gap = dense ? 8.0 : 10.0;
    final titleStyle = dense
        ? Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
            letterSpacing: 0,
          )
        : Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          );
    final stateStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.66),
      fontSize: dense ? 11 : null,
    );

    return Row(
      children: [
        Container(
          width: logo,
          height: logo,
          decoration: BoxDecoration(
            color: const Color(0xFF5855B0).withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(dense ? 6 : 8),
          ),
          child: Icon(Icons.graphic_eq, color: Colors.white, size: iconSize),
        ),
        SizedBox(width: gap),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(OverlayStrings.title, style: titleStyle),
              Text(stateLabel, style: stateStyle),
            ],
          ),
        ),
        IconButton(
          tooltip: OverlayStrings.closeTooltip,
          onPressed: onClose,
          visualDensity: dense ? VisualDensity.compact : VisualDensity.standard,
          iconSize: dense ? 20 : 24,
          padding: dense ? EdgeInsets.zero : null,
          constraints: dense
              ? const BoxConstraints(minWidth: 32, minHeight: 32)
              : null,
          icon: const Icon(Icons.close, color: Colors.white),
        ),
      ],
    );
  }
}

class OverlayMicOrb extends StatelessWidget {
  const OverlayMicOrb({
    super.key,
    required this.isListening,
    required this.accent,
  });

  final bool isListening;
  final Color accent;

  @override
  Widget build(BuildContext context) {
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
              border: Border.all(
                color: accent.withValues(alpha: 0.35),
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            width: isListening ? 46 : 42,
            height: isListening ? 46 : 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.88),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: isListening ? 0.35 : 0.18),
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
    required this.headline,
    required this.detail,
    this.dense = false,
  });

  final String headline;
  final String detail;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final headlineSize = dense ? 13.0 : 15.0;
    final detailSize = dense ? 11.0 : 12.0;
    final gap = dense ? 2.0 : 4.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          headline,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
            fontSize: headlineSize,
            height: dense ? 1.2 : null,
          ),
        ),
        SizedBox(height: gap),
        Text(
          detail,
          maxLines: dense ? 3 : 4,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.72),
            fontSize: detailSize,
            letterSpacing: 0,
            height: dense ? 1.25 : null,
          ),
        ),
      ],
    );
  }
}

class OverlayActions extends StatelessWidget {
  const OverlayActions({
    super.key,
    required this.isBusy,
    required this.onAgain,
    required this.onDone,
  });

  final bool isBusy;
  final VoidCallback onAgain;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xFF5855B0);
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isBusy ? null : onAgain,
            icon: const Icon(Icons.mic, size: 18),
            label: Text(OverlayStrings.again),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white.withValues(alpha: 0.35),
              minimumSize: const Size.fromHeight(36),
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.28)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            onPressed: onDone,
            icon: const Icon(Icons.check, size: 18),
            label: Text(OverlayStrings.done),
            style: FilledButton.styleFrom(
              backgroundColor: accent.withValues(alpha: 0.88),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(36),
            ),
          ),
        ),
      ],
    );
  }
}
