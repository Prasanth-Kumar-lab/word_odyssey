import 'dart:math';
import 'dart:ui';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import '../../../controllers/game_controller.dart';
import '../../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class LevelCompleteOverlay extends StatefulWidget {
  const LevelCompleteOverlay({super.key});

  @override
  State<LevelCompleteOverlay> createState() => _LevelCompleteOverlayState();
}

class _LevelCompleteOverlayState extends State<LevelCompleteOverlay> {
  final _c = Get.find<GameController>();
  final _confetti = ConfettiController(duration: const Duration(seconds: 2));
  static const _praise = ['Brilliant!', 'Amazing!', 'Fantastic!', 'Superb!', 'Genius!', 'Splendid!', 'Wonderful!'];
  late final String _title = _praise[Random().nextInt(_praise.length)];

  @override
  void initState() {
    super.initState();
    _confetti.play();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withValues(alpha: 0.45)),
          ).animate().fadeIn(duration: 350.ms),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 40,
            emissionFrequency: 0.06,
            gravity: 0.18,
            maxBlastForce: 22,
            minBlastForce: 8,
            colors: const [AppColors.gold, AppColors.pink, AppColors.cyan, AppColors.green, AppColors.violet, Colors.white],
          ),
        ),
        Center(
          child: IgnorePointer(
            child: SizedBox.square(
              dimension: 240,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  for (var i = 0; i < 3; i++)
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: (i == 1 ? AppColors.pink : AppColors.gold).withValues(alpha: 0.8), width: 2),
                      ),
                    )
                        .animate()
                        .scaleXY(begin: 0.2, end: 3.4, delay: (80 + i * 160).ms, duration: 1100.ms, curve: Curves.easeOut)
                        .fadeOut(delay: (280 + i * 160).ms, duration: 800.ms),
                ],
              ),
            ),
          ),
        ),
        Center(
          child: LayoutBuilder(builder: (context, box) {
            final maxCard = min(420.0, box.maxWidth - 28);
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: box.maxWidth < 360 ? 16 : 24, vertical: 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxCard),
                child: _card(maxCard),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _card(double maxWidth) {
    final titleSize = (maxWidth * 0.11).clamp(30.0, 46.0);
    return GlassBox(
      radius: 32,
      padding: EdgeInsets.fromLTRB(maxWidth < 340 ? 16 : 24, 28, maxWidth < 340 ? 16 : 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShaderMask(
            shaderCallback: (r) => AppGradients.gold.createShader(r),
            blendMode: BlendMode.srcIn,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(_title, style: AppText.display(titleSize)),
            ),
          )
              .animate()
              .fadeIn(delay: 120.ms, duration: 200.ms)
              .scaleXY(begin: 0.3, end: 1, delay: 160.ms, duration: 720.ms, curve: Curves.elasticOut)
              .blurXY(begin: 8, end: 0, delay: 160.ms, duration: 500.ms)
              .then()
              .shimmer(duration: 1200.ms, color: Colors.white),
          const SizedBox(height: 4),
          Text('Level ${_c.completedLevel.value} complete',
                  style: AppText.body(15, color: Colors.white70, weight: FontWeight.w600))
              .animate()
              .fadeIn(delay: 400.ms),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < 3; i++)
                Padding(
                  padding: EdgeInsets.only(bottom: i == 1 ? 14 : 0, left: 4, right: 4),
                  child: Icon(Icons.star_rounded,
                          size: i == 1 ? 76 : 58,
                          color: AppColors.gold,
                          shadows: [Shadow(color: AppColors.orange.withValues(alpha: 0.9), blurRadius: 24)])
                      .animate()
                      .fadeIn(delay: (500 + i * 180).ms, duration: 150.ms)
                      .moveY(begin: -36, end: 0, delay: (500 + i * 180).ms, duration: 650.ms, curve: Curves.bounceOut)
                      .scaleXY(begin: 0.2, end: 1, delay: (500 + i * 180).ms, duration: 700.ms, curve: Curves.elasticOut)
                      .rotate(begin: -0.8, end: 0, delay: (500 + i * 180).ms, duration: 600.ms)
                      .then()
                      .shimmer(duration: 900.ms, color: Colors.white)
                      .animate(onPlay: (c) => c.repeat(reverse: true), delay: (1400 + i * 120).ms)
                      .scaleXY(begin: 1, end: 1.06, duration: 900.ms, curve: Curves.easeInOut),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _stat('Words', '${_c.found.length}', Icons.grid_view_rounded),
              const SizedBox(width: 12),
              _stat('Bonus', '${_c.bonus.length}', Icons.auto_awesome_rounded),
            ],
          ).animate().fadeIn(delay: 1100.ms).slideY(begin: 0.4, end: 0, curve: Curves.easeOutBack),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CoinIcon(size: 32)
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(begin: 1, end: 1.15, duration: 700.ms),
              const SizedBox(width: 10),
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: _c.reward.value),
                duration: const Duration(milliseconds: 1400),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => Text('+$v', style: AppText.display(34, color: AppColors.gold)),
              ),
            ],
          ).animate().fadeIn(delay: 1300.ms).scaleXY(begin: 0.5, end: 1, curve: Curves.easeOutBack),
          const SizedBox(height: 26),
          SizedBox(
            width: double.infinity,
            child: GradientButton(
              label: 'NEXT LEVEL',
              icon: Icons.arrow_forward_rounded,
              expand: true,
              onTap: _c.nextPuzzle,
            ),
          )
              .animate()
              .fadeIn(delay: 1500.ms)
              .slideY(begin: 0.6, end: 0, delay: 1500.ms, curve: Curves.easeOutBack)
              .then()
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 1, end: 1.05, duration: 900.ms, curve: Curves.easeInOut),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 280.ms)
        .scaleXY(begin: 0.55, end: 1, duration: 720.ms, curve: Curves.elasticOut)
        .moveY(begin: 40, end: 0, duration: 600.ms, curve: Curves.easeOutCubic)
        .rotate(begin: -0.03, end: 0, duration: 600.ms);
  }

  Widget _stat(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(children: [
        Icon(icon, color: AppColors.cyan, size: 20),
        const SizedBox(width: 8),
        Text(value, style: AppText.display(20)),
        const SizedBox(width: 6),
        Text(label, style: AppText.body(12, color: Colors.white60)),
      ]),
    );
  }
}
