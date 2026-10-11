import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/user_model.dart';
import '../../theme/app_theme.dart';

/// Animated game character avatar with rotating rune/cosmic ring, glowing gradient core,
/// and optional online status dot.
class AnimatedGameAvatar extends StatelessWidget {
  const AnimatedGameAvatar({
    super.key,
    required this.avatarId,
    this.size = 56,
    this.showOnline = false,
    this.isOnline = true,
    this.isTurnActive = false,
    this.badgeText,
  });

  final String avatarId;
  final double size;
  final bool showOnline;
  final bool isOnline;
  final bool isTurnActive;
  final String? badgeText;

  @override
  Widget build(BuildContext context) {
    final spec = GameAvatarSpec.byId(avatarId);
    return SizedBox(
      width: size * 1.15,
      height: size * 1.15,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (isTurnActive)
            Container(
              width: size * 1.14,
              height: size * 1.14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    spec.accent,
                    spec.colors.first,
                    spec.colors.last,
                    spec.accent,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: spec.accent.withValues(alpha: 0.65),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ).animate(onPlay: (c) => c.repeat()).rotate(duration: 3200.ms),
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: spec.colors,
              ),
              border: Border.all(
                color: isTurnActive
                    ? AppColors.gold
                    : Colors.white.withValues(alpha: 0.72),
                width: size * 0.048,
              ),
              boxShadow: [
                BoxShadow(
                  color: spec.colors.first.withValues(alpha: 0.55),
                  blurRadius: size * 0.28,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    margin: EdgeInsets.only(top: size * 0.09),
                    width: size * 0.52,
                    height: size * 0.22,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.26),
                      borderRadius: BorderRadius.circular(size),
                    ),
                  ),
                ),
                Icon(
                  spec.icon,
                  color: Colors.white,
                  size: size * 0.52,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 8,
                    ),
                  ],
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scaleXY(begin: 0.94, end: 1.08, duration: 1600.ms, curve: Curves.easeInOut),
              ],
            ),
          ),
          if (showOnline)
            Positioned(
              right: size * 0.04,
              bottom: size * 0.04,
              child: Container(
                width: (size * 0.24).clamp(10.0, 16.0),
                height: (size * 0.24).clamp(10.0, 16.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isOnline ? AppColors.green : Colors.white38,
                  border: Border.all(color: AppColors.ink, width: 2),
                  boxShadow: isOnline
                      ? [
                          BoxShadow(
                            color: AppColors.green.withValues(alpha: 0.8),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          if (badgeText != null && badgeText!.isNotEmpty)
            Positioned(
              bottom: -size * 0.08,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                decoration: BoxDecoration(
                  gradient: AppGradients.gold,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.ink, width: 1.2),
                ),
                child: Text(
                  badgeText!,
                  style: AppText.display(
                    (size * 0.18).clamp(9.0, 12.0),
                    color: AppColors.ink,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Animated equalizer / audio-video visualizer bars for gameplay HUD.
class AudioEqualizerBars extends StatefulWidget {
  const AudioEqualizerBars({
    super.key,
    this.active = true,
    this.color = AppColors.cyan,
    this.barCount = 5,
    this.height = 18,
  });

  final bool active;
  final Color color;
  final int barCount;
  final double height;

  @override
  State<AudioEqualizerBars> createState() => _AudioEqualizerBarsState();
}

class _AudioEqualizerBarsState extends State<AudioEqualizerBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(widget.barCount, (i) {
            final wave = widget.active
                ? (0.25 + 0.75 * ((sin(_c.value * pi * 2 + i * 1.1) + 1) / 2))
                : 0.22;
            return Container(
              width: 3,
              height: widget.height * wave,
              margin: const EdgeInsets.symmetric(horizontal: 1.2),
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(3),
                boxShadow: widget.active
                    ? [
                        BoxShadow(
                          color: widget.color.withValues(alpha: 0.6),
                          blurRadius: 4,
                        ),
                      ]
                    : null,
              ),
            );
          }),
        );
      },
    );
  }
}
