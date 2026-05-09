import 'package:flutter/material.dart';

import 'baigalaa_page_gradient.dart';

/// Layered mesh-style background using [BaigalaaPageGradient] brand colors.
class BaigalaaMeshBackground extends StatelessWidget {
  const BaigalaaMeshBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const _MeshLayers(),
        child,
      ],
    );
  }
}

class _MeshLayers extends StatelessWidget {
  const _MeshLayers();

  static Color get _navy => BaigalaaPageGradient.navy;
  static Color get _magenta => BaigalaaPageGradient.magenta;
  static Color get _rose => BaigalaaPageGradient.rose;
  static Color get _mist => BaigalaaPageGradient.mist;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _navy,
                Color.lerp(_navy, _magenta, 0.45)!,
                _magenta,
                Color.lerp(_magenta, _rose, 0.55)!,
              ],
              stops: const [0.0, 0.38, 0.72, 1.0],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.4, -0.55),
              radius: 1.12,
              colors: [
                _mist.withValues(alpha: 0.72),
                _rose.withValues(alpha: 0.35),
                _rose.withValues(alpha: 0.0),
              ],
              stops: const [0.0, 0.42, 1.0],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.92, -0.2),
              radius: 0.95,
              colors: [
                _magenta.withValues(alpha: 0.55),
                _magenta.withValues(alpha: 0.08),
                _magenta.withValues(alpha: 0.0),
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.82, 0.88),
              radius: 1.08,
              colors: [
                _navy.withValues(alpha: 0.72),
                _navy.withValues(alpha: 0.0),
              ],
              stops: const [0.0, 1.0],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.25, 0.62),
              radius: 1.2,
              colors: [
                _mist.withValues(alpha: 0.38),
                _mist.withValues(alpha: 0.1),
                _mist.withValues(alpha: 0.0),
              ],
              stops: const [0.0, 0.4, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}
