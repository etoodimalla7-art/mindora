import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Lightweight confetti animation — no external dependency.
///
/// Usage:
///   Stack(children: [
///     YourContent(),
///     if (showConfetti) ConfettiOverlay(),
///   ])
class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({
    super.key,
    this.duration = const Duration(milliseconds: 3000),
    this.particleCount = 80,
  });

  final Duration duration;
  final int particleCount;

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_Particle> _particles;
  final _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration)
      ..forward();
    _particles = List.generate(widget.particleCount, (_) => _Particle.random(_rng));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) => CustomPaint(
          painter: _ConfettiPainter(_particles, _ctrl.value),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _Particle {
  _Particle({
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.color,
    required this.size,
    required this.rotationSpeed,
  });

  final double startX, startY, endX, endY;
  final Color color;
  final double size;
  final double rotationSpeed;

  factory _Particle.random(math.Random rng) {
    const colors = [
      Color(0xFF6366F1),
      Color(0xFF8B5CF6),
      Color(0xFFEC4899),
      Color(0xFFF59E0B),
      Color(0xFF10B981),
      Color(0xFF06B6D4),
    ];
    return _Particle(
      startX: rng.nextDouble(),
      startY: -0.1 - rng.nextDouble() * 0.2,
      endX: rng.nextDouble(),
      endY: 0.8 + rng.nextDouble() * 0.3,
      color: colors[rng.nextInt(colors.length)],
      size: 4 + rng.nextDouble() * 6,
      rotationSpeed: (rng.nextDouble() - 0.5) * 8,
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.particles, this.progress);
  final List<_Particle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      // Eased falling curve
      final t = Curves.easeIn.transform(progress);

      // Vertical position + slight horizontal drift
      final x = (p.startX * size.width) +
          ((p.endX - p.startX) * size.width * t) +
          (math.sin(progress * math.pi * 4 + p.rotationSpeed) * 30);
      final y = p.startY * size.height +
          (p.endY - p.startY) * size.height * t;

      // Fade out near the end
      final opacity = progress < 0.8 ? 1.0 : (1 - (progress - 0.8) / 0.2);

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * p.rotationSpeed * math.pi);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
          const Radius.circular(1),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
