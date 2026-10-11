import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../theme/app_theme.dart';
import '../../utils/haptics.dart';

/// Frosted glass panel.
class GlassBox extends StatelessWidget {
  const GlassBox({
    super.key,
    required this.child,
    this.radius = 24,
    this.padding = const EdgeInsets.all(16),
    this.blur = 14,
  });

  final Widget child;
  final double radius;
  final EdgeInsets padding;
  final double blur;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white.withValues(alpha: 0.16), Colors.white.withValues(alpha: 0.05)],
            ),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Adds a springy press-down effect to any child.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, required this.onTap, this.scale = 0.92});

  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final scale = _down ? widget.scale : (_hover ? 1.045 : 1.0);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) {
          setState(() => _down = false);
          widget.onTap?.call();
        },
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutBack,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Large gradient call-to-action button with a sweeping shine.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.gradient = AppGradients.gold,
    this.height = 64,
    this.textColor = AppColors.ink,
    this.expand = false,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final Gradient gradient;
  final double height;
  final Color textColor;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        height: height,
        width: expand ? double.infinity : null,
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: expand ? 20 : 36),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(height / 2),
          boxShadow: [
            BoxShadow(color: AppColors.orange.withValues(alpha: 0.55), blurRadius: 28, offset: const Offset(0, 10)),
            BoxShadow(color: Colors.white.withValues(alpha: 0.4), blurRadius: 0, offset: const Offset(0, -2), spreadRadius: -1),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: textColor, size: height * 0.46),
              const SizedBox(width: 10),
            ],
            Text(label, style: AppText.display(height * 0.36, color: textColor, spacing: 1.5)),
          ],
        ),
      )
          .animate(onPlay: (c) => c.repeat())
          .shimmer(delay: 1800.ms, duration: 1400.ms, color: Colors.white.withValues(alpha: 0.7)),
    );
  }
}

/// Round glass action button with optional cost badge.
class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.cost,
    this.badge,
    this.size = 58,
    this.gradient = AppGradients.cool,
  });

  final IconData icon;
  final VoidCallback onTap;
  final int? cost;
  final String? badge;
  final double size;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.85,
      child: SizedBox(
        width: size + 10,
        height: size + 12,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: gradient,
                border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 2),
                boxShadow: [
                  BoxShadow(color: gradient.colors.last.withValues(alpha: 0.5), blurRadius: 18, offset: const Offset(0, 6)),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      margin: EdgeInsets.only(top: size * 0.14),
                      width: size * 0.42,
                      height: size * 0.18,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(size),
                      ),
                    ),
                  ),
                  Icon(icon, color: Colors.white, size: size * 0.5),
                ],
              ),
            ),
            if (cost != null || badge != null)
              Positioned(
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.gold, width: 1.2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (cost != null) ...[
                        const CoinIcon(size: 11),
                        const SizedBox(width: 3),
                      ],
                      Text(badge ?? '$cost', style: AppText.body(10.5, weight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CoinIcon extends StatelessWidget {
  const CoinIcon({super.key, this.size = 22});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppGradients.gold,
        border: Border.all(color: const Color(0xFFB45309), width: size * 0.08),
        boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: 0.6), blurRadius: size * 0.4)],
      ),
      alignment: Alignment.center,
      child: Icon(Icons.star_rounded, size: size * 0.62, color: const Color(0xFFB45309)),
    );
  }
}

/// Coin counter that rolls smoothly between values and pops on change.
class CoinChip extends StatelessWidget {
  const CoinChip({super.key, required this.coins});
  final int coins;

  @override
  Widget build(BuildContext context) {
    return GlassBox(
      radius: 30,
      blur: 8,
      padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CoinIcon(size: 26)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .rotate(begin: -0.08, end: 0.08, duration: 1600.ms, curve: Curves.easeInOut)
              .scaleXY(begin: 1, end: 1.08, duration: 1600.ms, curve: Curves.easeInOut)
              .shimmer(delay: 400.ms, duration: 900.ms),
          const SizedBox(width: 8),
          TweenAnimationBuilder<double>(
            tween: Tween(end: coins.toDouble()),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => Text('${v.round()}', style: AppText.display(18)),
          ),
        ],
      ),
    ).animate(key: ValueKey(coins)).scaleXY(begin: 1.12, end: 1, duration: 400.ms, curve: Curves.easeOutBack);
  }
}

class GlassIconButton extends StatelessWidget {
  const GlassIconButton({super.key, required this.icon, required this.onTap, this.size = 46});
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () {
        Haptics.light();
        onTap();
      },
      scale: 0.85,
      child: GlassBox(
        radius: size / 2,
        blur: 8,
        padding: EdgeInsets.zero,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: Colors.white, size: size * 0.5),
        ),
      ),
    );
  }
}

/// A single letter tile used for logos.
class LogoTile extends StatelessWidget {
  const LogoTile(this.letter, {super.key, this.size = 56, this.gradient = AppGradients.gold});
  final String letter;
  final double size;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.24);
    return Container(
      width: size,
      height: size,
      margin: EdgeInsets.all(size * 0.05),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: radius,
        border: Border.all(color: Colors.white.withValues(alpha: 0.65), width: 2),
        boxShadow: [
          BoxShadow(color: AppColors.orange.withValues(alpha: 0.5), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.2),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x8CFFFFFF), Color(0x00FFFFFF)],
                  stops: [0, 0.55],
                ),
              ),
            ),
            Center(child: Text(letter, style: AppText.display(size * 0.56, color: AppColors.ink))),
          ],
        ),
      ),
    );
  }
}
