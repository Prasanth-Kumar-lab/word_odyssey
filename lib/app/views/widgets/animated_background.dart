import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Slowly shifting aurora gradient with drifting glowing particles.
class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 40))..repeat();
  late final List<_Particle> _particles = _makeParticles();

  List<_Particle> _makeParticles() {
    final r = Random(7);
    const palette = [AppColors.gold, AppColors.pink, AppColors.cyan, Colors.white, AppColors.violet];
    return List.generate(
      42,
      (_) => _Particle(
        x: r.nextDouble(),
        y: r.nextDouble(),
        radius: 1.5 + r.nextDouble() * (r.nextDouble() < 0.2 ? 26 : 5),
        speed: 0.3 + r.nextDouble() * 1.2,
        phase: r.nextDouble() * pi * 2,
        color: palette[r.nextInt(palette.length)],
        opacity: 0.08 + r.nextDouble() * 0.35,
      ),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox.expand(
        child: CustomPaint(painter: _BackgroundPainter(_c, _particles)),
      ),
    );
  }
}

class _Particle {
  const _Particle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.phase,
    required this.color,
    required this.opacity,
  });
  final double x, y, radius, speed, phase, opacity;
  final Color color;
}

class _BackgroundPainter extends CustomPainter {
  _BackgroundPainter(this.anim, this.particles) : super(repaint: anim);

  final Animation<double> anim;
  final List<_Particle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    final t = anim.value;
    final wave = (sin(t * pi * 2) + 1) / 2;
    final rect = Offset.zero & size;

    final a = t * pi * 2;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment(cos(a) * 0.6, -1),
          end: Alignment(-cos(a) * 0.6, 1),
          colors: [
            Color.lerp(AppColors.bgTop, const Color(0xFF2B0E5E), wave)!,
            Color.lerp(AppColors.bgMid, const Color(0xFF5B1A6E), wave)!,
            Color.lerp(AppColors.bgBottom, const Color(0xFF14295E), wave)!,
          ],
        ).createShader(rect),
    );

    // Aurora blobs
    void blob(Color c, double cx, double cy, double r) {
      final center = Offset(cx * size.width, cy * size.height);
      final radius = r * size.shortestSide;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(colors: [c.withValues(alpha: 0.38), c.withValues(alpha: 0)])
              .createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }

    blob(AppColors.violet, 0.2 + 0.15 * sin(a), 0.25 + 0.1 * cos(a * 2), 0.9);
    blob(AppColors.pink, 0.85 + 0.1 * cos(a), 0.55 + 0.15 * sin(a), 0.7);
    blob(AppColors.cyan, 0.4 + 0.2 * sin(a * 2), 0.95 + 0.05 * cos(a), 0.8);
    blob(AppColors.gold, 0.62 + 0.08 * sin(a * 1.4), 0.16 + 0.06 * cos(a), 0.42);

    _shoot(canvas, size, 0.08, const Offset(0.12, 0.22), const Offset(0.72, 0.48));
    _shoot(canvas, size, 0.31, const Offset(0.88, 0.16), const Offset(0.28, 0.42));
    _shoot(canvas, size, 0.57, const Offset(0.2, 0.62), const Offset(0.78, 0.28));
    _shoot(canvas, size, 0.79, const Offset(0.7, 0.08), const Offset(0.18, 0.36));

    // Particles
    for (final p in particles) {
      final y = (p.y - t * p.speed * 2) % 1.0;
      final x = p.x + sin(a * 3 + p.phase) * 0.03;
      final twinkle = 0.6 + 0.4 * sin(a * 8 * p.speed + p.phase);
      final center = Offset(x * size.width, y * size.height);
      canvas.drawCircle(
        center,
        p.radius,
        Paint()
          ..shader = RadialGradient(colors: [
            p.color.withValues(alpha: p.opacity * twinkle),
            p.color.withValues(alpha: 0),
          ]).createShader(Rect.fromCircle(center: center, radius: p.radius)),
      );
    }

    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.38)],
          stops: const [0.52, 1],
        ).createShader(rect),
    );
  }

  void _shoot(Canvas canvas, Size size, double start, Offset from, Offset to) {
    const window = 0.05;
    final local = anim.value - start;
    if (local < 0 || local > window) return;
    final p = local / window;
    final head = Offset.lerp(Offset(from.dx * size.width, from.dy * size.height), Offset(to.dx * size.width, to.dy * size.height), p)!;
    final tail = Offset.lerp(
      Offset(from.dx * size.width, from.dy * size.height),
      Offset(to.dx * size.width, to.dy * size.height),
      (p - 0.22).clamp(0.0, 1.0),
    )!;
    canvas.drawLine(
      tail,
      head,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85 * (1 - p))
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    canvas.drawCircle(head, 2.2, Paint()..color = Colors.white.withValues(alpha: 0.95 * (1 - p)));
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter old) => false;
}
