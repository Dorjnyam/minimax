import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../../shared/constants/baigalaa_constants.dart';

/// Lottie hero used on splash ([orbLottieAsset]) and auth ([authHeroLottieAsset]).
class AuthHeroLottie extends StatelessWidget {
  const AuthHeroLottie({
    super.key,
    required this.fallback,
    this.size = 200,
    this.asset = orbLottieAsset,
  });

  final Widget fallback;
  final double size;
  final String asset;

  @override
  Widget build(BuildContext context) {
    final s = size;
    const alignment = Alignment.center;
    return SizedBox(
      width: s,
      height: s,
      child: Lottie.asset(
        asset,
        width: s,
        height: s,
        fit: BoxFit.contain,
        alignment: alignment,
        repeat: true,
        errorBuilder: (context, error, stackTrace) => Align(
          alignment: alignment,
          child: fallback,
        ),
        frameBuilder: (context, child, composition) {
          if (composition == null) {
            return Align(
              alignment: alignment,
              child: Icon(
                Icons.blur_circular_rounded,
                size: 32,
                color: Colors.white.withValues(alpha: 0.35),
              ),
            );
          }
          return Align(alignment: alignment, child: child);
        },
      ),
    );
  }
}
