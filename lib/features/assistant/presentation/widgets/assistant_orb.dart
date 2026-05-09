import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../../shared/constants/baigalaa_constants.dart';

/// Center orb from [orb.json] (project root). Plays while [active] (mic listening);
/// pauses when idle (no custom [AnimationController] — avoids web/reload ticker issues).
class AssistantOrb extends StatelessWidget {
  const AssistantOrb({super.key, required this.active, this.size = 230});

  final bool active;
  final double size;

  @override
  Widget build(BuildContext context) {
    final s = size;
    return SizedBox(
      width: s,
      height: s,
      child: Lottie.asset(
        orbLottieAsset,
        width: s,
        height: s,
        fit: BoxFit.contain,
        alignment: Alignment.center,
        repeat: active,
        animate: active,
        frameBuilder: (context, child, composition) {
          // Avoid CircularProgressIndicator here: inside Lottie's FutureBuilder it can
          // throw on Flutter web (ticker / JS interop). No heavy animation needed.
          if (composition == null) {
            return Center(
              child: Icon(
                Icons.blur_circular_rounded,
                size: 32,
                color: Colors.white.withValues(alpha: 0.35),
              ),
            );
          }
          return child;
        },
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.graphic_eq_rounded,
            size: s * 0.35,
            color: Colors.white.withValues(alpha: 0.65),
          );
        },
      ),
    );
  }
}
