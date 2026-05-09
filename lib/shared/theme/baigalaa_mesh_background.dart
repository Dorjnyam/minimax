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

  static Color get _deep => BaigalaaPageGradient.deepPurple;
  static Color get _mid => BaigalaaPageGradient.midPurple;
  static Color get _light => BaigalaaPageGradient.surfaceWhite;

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
                _deep,
                Color.lerp(_deep, _mid, 0.35)!,
                _mid,
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.35, -0.65),
              radius: 1.15,
              colors: [
                _light.withValues(alpha: 0.58),
                _light.withValues(alpha: 0.18),
                _light.withValues(alpha: 0.0),
              ],
              stops: const [0.0, 0.38, 1.0],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.95, -0.25),
              radius: 1.05,
              colors: [
                _mid.withValues(alpha: 0.5),
                _mid.withValues(alpha: 0.0),
              ],
              stops: const [0.0, 1.0],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.85, 0.92),
              radius: 1.1,
              colors: [
                _deep.withValues(alpha: 0.58),
                _deep.withValues(alpha: 0.0),
              ],
              stops: const [0.0, 1.0],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.2, 0.55),
              radius: 1.25,
              colors: [
                _light.withValues(alpha: 0.22),
                _light.withValues(alpha: 0.0),
              ],
              stops: const [0.0, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}
