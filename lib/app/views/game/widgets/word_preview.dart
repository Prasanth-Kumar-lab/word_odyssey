import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import '../../../controllers/game_controller.dart';
import '../../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

/// Shows the word being built, then animated feedback after submitting.
class WordPreview extends GetView<GameController> {
  const WordPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    final bar = (h * 0.068).clamp(46.0, 64.0);
    return SizedBox(
      height: bar,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: Alignment.center,
        child: Center(
          child: Obx(() {
            final w = controller.current.value;
            final fb = controller.feedback.value;
            if (w.isNotEmpty) return _building(w);
            if (fb != null) return _feedback(fb);
            return const SizedBox.shrink();
          }),
        ),
      ),
    );
  }

  Widget _pill({required Widget child, required Gradient gradient, Color? glow}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
        boxShadow: [BoxShadow(color: (glow ?? AppColors.pink).withValues(alpha: 0.55), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: child,
    );
  }

  Widget _building(String w) {
    return _pill(
      gradient: AppGradients.hot,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, ch) in w.split('').indexed)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(ch.toUpperCase(), style: AppText.display(26, spacing: 1))
                  .animate(key: ValueKey('$i$ch'))
                  .scaleXY(begin: 0.3, end: 1, duration: 260.ms, curve: Curves.easeOutBack)
                  .moveY(begin: 10, end: 0, duration: 220.ms),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 120.ms);
  }

  Widget _feedback(WordFeedback fb) {
    final word = fb.word.toUpperCase();
    final key = ValueKey(fb.id);
    switch (fb.type) {
      case FeedbackType.correct:
        return _pill(
          gradient: AppGradients.success,
          glow: AppColors.green,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Text(word, style: AppText.display(24, spacing: 2)),
          ]),
        )
            .animate(key: key)
            .scaleXY(begin: 0.6, end: 1.1, duration: 300.ms, curve: Curves.easeOutBack)
            .then()
            .scaleXY(begin: 1, end: 0.91, duration: 150.ms)
            .then(delay: 450.ms)
            .moveY(begin: 0, end: -40, duration: 350.ms, curve: Curves.easeIn)
            .fadeOut(duration: 350.ms);
      case FeedbackType.wrong:
        return _pill(
          gradient: AppGradients.danger,
          glow: AppColors.red,
          child: Text(word, style: AppText.display(24, spacing: 2)),
        )
            .animate(key: key)
            .shake(hz: 7, offset: const Offset(10, 0), duration: 450.ms)
            .then(delay: 250.ms)
            .fadeOut(duration: 300.ms);
      case FeedbackType.bonus:
        return _pill(
          gradient: AppGradients.cool,
          glow: AppColors.cyan,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(word, style: AppText.display(22, spacing: 1.5)),
            const SizedBox(width: 10),
            const CoinIcon(size: 20),
            Text(' +${GameController.bonusReward}', style: AppText.display(18, color: AppColors.gold)),
          ]),
        )
            .animate(key: key)
            .scaleXY(begin: 0.4, end: 1, duration: 450.ms, curve: Curves.elasticOut)
            .shimmer(duration: 700.ms)
            .then(delay: 600.ms)
            .moveY(begin: 0, end: -30, duration: 300.ms)
            .fadeOut(duration: 300.ms);
      case FeedbackType.repeat:
      case FeedbackType.bonusRepeat:
      case FeedbackType.noCoins:
      case FeedbackType.tooShort:
        final text = switch (fb.type) {
          FeedbackType.repeat => 'Already found',
          FeedbackType.bonusRepeat => 'Bonus already found',
          FeedbackType.noCoins => 'Not enough coins',
          _ => 'Too short',
        };
        return GlassBox(
          radius: 26,
          blur: 6,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Text(text, style: AppText.body(15, weight: FontWeight.w600, color: AppColors.gold)),
        )
            .animate(key: key)
            .fadeIn(duration: 150.ms)
            .slideY(begin: 0.5, end: 0, duration: 250.ms, curve: Curves.easeOutBack)
            .then(delay: 900.ms)
            .fadeOut(duration: 300.ms);
    }
  }
}
