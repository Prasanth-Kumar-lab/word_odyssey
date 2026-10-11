import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Rotating arcs and orbiting sparks. Place behind a logo or level orb.
class OrbitHalo extends StatefulWidget {
  const OrbitHalo({super.key, required this.size, this.child});

  final double size;
  final Widget? child;

  @override
  State<OrbitHalo> createState() => _OrbitHaloState();
}

class _OrbitHaloState extends State<OrbitHalo> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 16))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) => CustomPaint(
          painter: _HaloPainter(_c.value),
          child: child,
        ),
        child: Center(child: widget.child),
      ),
    );
  }
}

class _HaloPainter extends CustomPainter {
  _HaloPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    const palette = [AppColors.gold, AppColors.cyan, AppColors.pink];
    for (var i = 0; i < 3; i++) {
      final spin = t * pi * 2 * (i.isEven ? 1 : -1.35) + i * 1.2;
      final radius = size.width * (0.40 + i * 0.055);
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Colors.white.withValues(alpha: 0.08),
      );
      canvas.drawArc(
        rect,
        spin,
        pi * (1.15 + i * 0.12),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = i == 1 ? 2.4 : 1.4
          ..strokeCap = StrokeCap.round
          ..shader = SweepGradient(
            transform: GradientRotation(spin),
            colors: [
              Colors.transparent,
              palette[i].withValues(alpha: 0.15),
              palette[i].withValues(alpha: 0.95),
              Colors.white.withValues(alpha: 0.9),
              palette[(i + 1) % 3].withValues(alpha: 0.1),
              Colors.transparent,
            ],
          ).createShader(rect),
      );

      final angle = spin * 1.35 + i * 0.8;
      final dot = center + Offset(cos(angle), sin(angle)) * radius;
      canvas.drawCircle(dot, 7 - i.toDouble(), Paint()..color = palette[i].withValues(alpha: 0.28));
      canvas.drawCircle(dot, 2.6, Paint()..color = Colors.white.withValues(alpha: 0.95));
    }
  }

  @override
  bool shouldRepaint(covariant _HaloPainter oldDelegate) => oldDelegate.t != t;
}

/// Expanding rounded rings behind a call-to-action.
class SoftPulse extends StatefulWidget {
  const SoftPulse({
    super.key,
    required this.child,
    this.color = AppColors.orange,
    this.borderRadius = 40,
  });

  final Widget child;
  final Color color;
  final double borderRadius;

  @override
  State<SoftPulse> createState() => _SoftPulseState();
}

class _SoftPulseState extends State<SoftPulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, __) => Stack(
                fit: StackFit.expand,
                children: [
                  _ring(_c.value),
                  _ring((_c.value + 0.5) % 1),
                ],
              ),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }

  Widget _ring(double phase) {
    final eased = Curves.easeOut.transform(phase);
    return Transform.scale(
      scale: 1 + 0.16 * eased,
      child: Opacity(
        opacity: (1 - eased) * 0.55,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius + 8 * eased),
            border: Border.all(color: widget.color.withValues(alpha: 0.95), width: 2),
          ),
        ),
      ),
    );
  }
}

/// Gradient loading bar with a traveling highlight.
class GlowProgressBar extends StatefulWidget {
  const GlowProgressBar({super.key, required this.value, this.height = 8});

  final double value;
  final double height;

  @override
  State<GlowProgressBar> createState() => _GlowProgressBarState();
}

class _GlowProgressBarState extends State<GlowProgressBar> with SingleTickerProviderStateMixin {
  late final AnimationController _shine =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))..repeat();

  @override
  void dispose() {
    _shine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.height;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: widget.value.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        final factor = v <= 0 ? 0.001 : v;
        return SizedBox(
          height: h + 14,
          child: Center(
            child: Container(
              height: h,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(h),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(h),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: factor,
                    heightFactor: 1,
                    child: AnimatedBuilder(
                      animation: _shine,
                      builder: (_, __) {
                        final shine = _shine.value;
                        final before = (shine - 0.22).clamp(0.0, 1.0);
                        final mid = shine < before ? before : shine;
                        return DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: const [
                                Color(0xFFFFE29A),
                                AppColors.gold,
                                Colors.white,
                                AppColors.orange,
                              ],
                              stops: [0, before, mid, 1],
                            ),
                            boxShadow: [
                              BoxShadow(color: AppColors.gold.withValues(alpha: 0.85), blurRadius: 12),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Three dots that rise and fade in sequence.
class BouncingDots extends StatefulWidget {
  const BouncingDots({super.key, this.color = Colors.white});

  final Color color;

  @override
  State<BouncingDots> createState() => _BouncingDotsState();
}

class _BouncingDotsState extends State<BouncingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final phase = (_c.value + i * 0.16) % 1;
          final wave = sin(phase * pi);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Transform.translate(
              offset: Offset(0, -5 * wave),
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.35 + 0.65 * wave),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
