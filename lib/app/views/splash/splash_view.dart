import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import '../../controllers/splash_controller.dart';
import '../../theme/app_theme.dart';
import '../widgets/animated_background.dart';
import '../widgets/common_widgets.dart';
import '../widgets/premium_motion.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: LayoutBuilder(builder: (context, box) {
              final shortest = min(box.maxWidth, box.maxHeight);
              final short = box.maxHeight < 680;
              final tile = (shortest / (short ? 9.4 : 7.4)).clamp(34.0, short ? 64.0 : 86.0);
              final pad = box.maxWidth < 360 ? 16.0 : 28.0;
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: pad, vertical: short ? 12 : 20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: max(0, box.maxHeight - (short ? 24 : 40))),
                  child: Center(
                    child: _SplashStage(
                      tile: tile,
                      short: short,
                      maxWidth: min(box.maxWidth - pad * 2, 520),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _SplashStage extends GetView<SplashController> {
  const _SplashStage({required this.tile, required this.short, required this.maxWidth});

  final double tile;
  final bool short;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final halo = min(tile * (short ? 3.35 : 4.35), maxWidth * 0.92);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: halo,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                OrbitHalo(size: halo),
                _wordMark(),
              ],
            ),
          ),
          SizedBox(height: short ? 6 : 10),
          _odyssey(),
          const SizedBox(height: 10),
          Text(
            'A journey through words',
            textAlign: TextAlign.center,
            style: AppText.body(
              (tile * 0.28).clamp(12.0, 16.0),
              color: Colors.white70,
              weight: FontWeight.w600,
              spacing: 0.6,
            ),
          )
              .animate()
              .fadeIn(delay: 1500.ms, duration: 600.ms)
              .moveY(begin: 12, end: 0, delay: 1500.ms, duration: 600.ms, curve: Curves.easeOutCubic),
          SizedBox(height: short ? 28 : 42),
          _loader(),
        ],
      ),
    );
  }

  Widget _wordMark() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (i, letter) in 'WORD'.split('').indexed)
          LogoTile(letter, size: tile)
              .animate()
              .fadeIn(delay: (180 + i * 130).ms, duration: 220.ms)
              .moveY(
                begin: -90,
                end: 0,
                delay: (180 + i * 130).ms,
                duration: 820.ms,
                curve: Curves.easeOutBack,
              )
              .rotate(
                begin: i.isEven ? -0.45 : 0.45,
                end: 0,
                delay: (180 + i * 130).ms,
                duration: 820.ms,
                curve: Curves.easeOutBack,
              )
              .scaleXY(
                begin: 0.2,
                end: 1,
                delay: (180 + i * 130).ms,
                duration: 780.ms,
                curve: Curves.elasticOut,
              )
              .then(delay: 180.ms)
              .shimmer(duration: 900.ms, color: Colors.white.withValues(alpha: 0.85))
              .animate(onPlay: (c) => c.repeat(reverse: true), delay: (1100 + i * 140).ms)
              .moveY(begin: 0, end: -7, duration: 1700.ms, curve: Curves.easeInOut),
      ],
    );
  }

  Widget _odyssey() {
    final size = (tile * 0.58).clamp(22.0, 52.0);
    return ShaderMask(
      shaderCallback: (r) => AppGradients.cool.createShader(r),
      blendMode: BlendMode.srcIn,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, ch) in 'ODYSSEY'.split('').indexed)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: size * 0.045),
              child: Text(ch, style: AppText.display(size))
                  .animate()
                  .fadeIn(delay: (760 + i * 70).ms, duration: 320.ms)
                  .moveY(
                    begin: 28,
                    end: 0,
                    delay: (760 + i * 70).ms,
                    duration: 560.ms,
                    curve: Curves.easeOutBack,
                  )
                  .blurXY(begin: 10, end: 0, delay: (760 + i * 70).ms, duration: 480.ms)
                  .then(delay: 120.ms)
                  .shimmer(duration: 1100.ms, color: Colors.white),
            ),
        ],
      ),
    );
  }

  Widget _loader() {
    final barWidth = min(maxWidth * 0.78, 300.0);
    return Obx(() {
      final p = controller.progress.value;
      final label = p < 0.34
          ? 'Gathering letters'
          : p < 0.68
              ? 'Weaving the grid'
              : p < 0.98
                  ? 'Opening the path'
                  : 'Ready';
      return Column(
        children: [
          SizedBox(width: barWidth, child: GlowProgressBar(value: p, height: 8)),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: Row(
              key: ValueKey(label),
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: AppText.body(13, color: Colors.white70, weight: FontWeight.w600)),
                if (p < 0.98) ...[
                  const SizedBox(width: 8),
                  const BouncingDots(color: AppColors.gold),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text('${(p * 100).round()}%', style: AppText.display(13, color: AppColors.gold, spacing: 1)),
        ],
      );
    }).animate().fadeIn(delay: 1100.ms, duration: 500.ms).moveY(begin: 16, end: 0, delay: 1100.ms, duration: 500.ms);
  }
}
