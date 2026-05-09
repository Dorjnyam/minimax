import 'dart:math' as math;

import 'package:flutter/material.dart';

class AssistantOrb extends StatefulWidget {
  const AssistantOrb({super.key, required this.active, this.size = 230});

  final bool active;
  final double size;

  @override
  State<AssistantOrb> createState() => _AssistantOrbState();
}

class _AssistantOrbState extends State<AssistantOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Offset _drag = Offset.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _drag += details.delta / 28;
        });
      },
      onPanEnd: (_) => setState(() => _drag = Offset.zero),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _OrbPainter(
              progress: _controller.value,
              active: widget.active,
              drag: _drag,
            ),
            size: Size.square(widget.size),
          );
        },
      ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  _OrbPainter({
    required this.progress,
    required this.active,
    required this.drag,
  });

  final double progress;
  final bool active;
  final Offset drag;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final pulse = active ? 1.0 + math.sin(progress * math.pi * 2) * 0.07 : 1.0;
    final baseRadius = size.width * 0.27 * pulse;

    final glowPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              Colors.white.withValues(alpha: active ? 0.75 : 0.55),
              const Color(0xFFB070FF).withValues(alpha: 0.55),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(center: center, radius: size.width * 0.38),
          );
    canvas.drawCircle(center, size.width * 0.38, glowPaint);

    for (var i = 0; i < 4; i++) {
      final angle = progress * math.pi * 2 + i * math.pi / 2 + drag.dx;
      final path = Path();
      final radius = baseRadius + i * 8;
      final start = center + Offset(math.cos(angle), math.sin(angle)) * 10;
      path.moveTo(start.dx, start.dy);
      for (var step = 0; step < 64; step++) {
        final t = step / 63;
        final theta = angle + t * math.pi * 1.35;
        final stretch = radius * (1.15 + math.sin(t * math.pi) * 1.25);
        final x = center.dx + math.cos(theta) * stretch + drag.dx * 7;
        final y = center.dy + math.sin(theta) * stretch * 0.62 + drag.dy * 7;
        path.lineTo(x, y);
      }

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 34 - i * 4
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          colors: [
            const Color(0xFF62D7FF).withValues(alpha: 0.58),
            const Color(0xFFC45CFF).withValues(alpha: 0.78),
            const Color(0xFF9364FF).withValues(alpha: 0.32),
          ],
        ).createShader(Offset.zero & size);
      canvas.drawPath(path, paint);
    }

    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white,
          const Color(0xFFE7C9FF),
          const Color(0xFF7D65FF).withValues(alpha: 0.1),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 28));
    canvas.drawCircle(center, active ? 14 : 11, corePaint);
  }

  @override
  bool shouldRepaint(covariant _OrbPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.active != active ||
        oldDelegate.drag != drag;
  }
}
