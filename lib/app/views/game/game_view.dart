import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import '../../controllers/game_controller.dart';
import '../../theme/app_theme.dart';
import '../widgets/animated_background.dart';
import '../widgets/common_widgets.dart';
import '../widgets/game_avatar.dart';
import 'widgets/crossword_grid.dart';
import 'widgets/letter_wheel.dart';
import 'widgets/level_complete_overlay.dart';
import 'widgets/word_preview.dart';

class GameView extends GetView<GameController> {
  const GameView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: LayoutBuilder(builder: (context, box) {
              final wide = box.maxWidth > box.maxHeight * 1.05 && box.maxWidth > 680;
              final board = wide ? _wide(box) : _portrait(box);
              if (box.maxWidth <= 1180) return board;
              return Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 1180, maxHeight: box.maxHeight),
                  child: board,
                ),
              );
            }),
          ),
          Obx(() => AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: controller.showComplete.value
                    ? const LevelCompleteOverlay(key: ValueKey('complete'))
                    : const SizedBox.shrink(),
              )),
        ],
      ),
    );
  }

  Widget _portrait(BoxConstraints box) {
    final short = box.maxHeight < 700;
    final compact = box.maxWidth < 380;
    final wheel = min(
      min(box.maxWidth * (compact ? 0.58 : 0.64), box.maxHeight * (short ? 0.3 : 0.34)),
      360.0,
    );
    final pad = compact ? 12.0 : 16.0;
    return Column(
      children: [
        _topBar(compact),
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(pad, short ? 6 : 12, pad, 4),
            child: const CrosswordGrid(),
          ),
        ),
        const WordPreview(),
        SizedBox(height: short ? 2 : 6),
        _wheelArea(wheel, box.maxWidth),
        SizedBox(height: max(8, box.maxHeight * (short ? 0.012 : 0.025))),
      ],
    );
  }

  Widget _wide(BoxConstraints box) {
    final wheel = min(min(box.maxWidth * 0.3, box.maxHeight * 0.58), 400.0);
    final pad = box.maxWidth < 900 ? 16.0 : 28.0;
    return Column(
      children: [
        _topBar(box.maxWidth < 760),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 6,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(pad, 16, 12, 24),
                  child: const CrosswordGrid(),
                ),
              ),
              Expanded(
                flex: 5,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const WordPreview(),
                    const SizedBox(height: 10),
                    _wheelArea(wheel, box.maxWidth * 5 / 11),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _topBar(bool compact) {
    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 10 : 14, 8, compact ? 10 : 14, 0),
      child: Row(
        children: [
          GlassIconButton(icon: Icons.arrow_back_rounded, size: compact ? 42 : 46, onTap: Get.back),
          const SizedBox(width: 8),
          Expanded(
            child: Center(
              child: Obx(() {
                final lvl = controller.completed.value ? controller.completedLevel.value : controller.level.value;
                return FittedBox(
                  fit: BoxFit.scaleDown,
                  child: GlassBox(
                    radius: 22,
                    blur: 8,
                    padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 20, vertical: 8),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.auto_awesome, color: AppColors.gold, size: 18)
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .rotate(begin: -0.12, end: 0.12, duration: 1400.ms, curve: Curves.easeInOut)
                          .scaleXY(begin: 1, end: 1.12, duration: 1400.ms, curve: Curves.easeInOut),
                      const SizedBox(width: 8),
                      Text('LEVEL $lvl', style: AppText.display(compact ? 16 : 18, spacing: 2)),
                    ]),
                  ),
                )
                    .animate(key: ValueKey(lvl))
                    .fadeIn(duration: 220.ms)
                    .scaleXY(begin: 0.6, end: 1, curve: Curves.elasticOut, duration: 700.ms)
                    .shimmer(duration: 800.ms, color: Colors.white.withValues(alpha: 0.45));
              }),
            ),
          ),
          const SizedBox(width: 6),
          Obx(
            () => Pressable(
              onTap: controller.toggleSound,
              child: GlassBox(
                radius: 22,
                blur: 8,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      controller.soundOn.value
                          ? Icons.volume_up_rounded
                          : Icons.volume_off_rounded,
                      color: controller.soundOn.value ? AppColors.cyan : Colors.white54,
                      size: 18,
                    ),
                    const SizedBox(width: 5),
                    AudioEqualizerBars(
                      active: controller.soundOn.value,
                      color: AppColors.cyan,
                      barCount: 4,
                      height: 15,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Obx(() => CoinChip(coins: controller.coins.value)),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.8, end: 0, duration: 550.ms, curve: Curves.easeOutBack);
  }

  Widget _pop(Widget child, int index, {double dx = 0}) {
    return child
        .animate()
        .fadeIn(delay: (260 + index * 80).ms, duration: 260.ms)
        .scaleXY(begin: 0.35, end: 1, delay: (260 + index * 80).ms, duration: 620.ms, curve: Curves.elasticOut)
        .moveX(begin: dx, end: 0, delay: (260 + index * 80).ms, duration: 480.ms, curve: Curves.easeOutBack)
        .animate(onPlay: (c) => c.repeat(reverse: true), delay: (900 + index * 140).ms)
        .moveY(begin: 0, end: -4, duration: (1500 + index * 90).ms, curve: Curves.easeInOut);
  }

  Widget _wheelArea(double wheel, double availWidth) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth.isFinite ? constraints.maxWidth : availWidth;
      return _wheelRow(wheel, width);
    });
  }

  Widget _wheelRow(double wheel, double availWidth) {
    final btn = (wheel * 0.2).clamp(40.0, 62.0);
    // ActionButton lays out at size + 10, so the row must reserve that full width.
    final buttonExtent = btn + 10;
    const minGap = 8.0;
    final buttonsBeside = availWidth >= wheel + 2 * buttonExtent + 2 * minGap;

    final shuffle = _pop(
      ActionButton(icon: Icons.shuffle_rounded, size: btn, onTap: controller.shuffle, badge: 'FREE'),
      0,
      dx: -28,
    );
    final hint = _pop(
      ActionButton(
        icon: Icons.lightbulb_rounded,
        size: btn,
        gradient: AppGradients.gold,
        cost: GameController.hintCost,
        onTap: controller.useHint,
      ),
      2,
      dx: 28,
    );
    final magic = _pop(
      ActionButton(
        icon: Icons.auto_fix_high_rounded,
        size: btn,
        gradient: AppGradients.hot,
        cost: GameController.magicCost,
        onTap: controller.useMagic,
      ),
      3,
      dx: 28,
    );
    final bonus = _pop(
      Obx(() => ActionButton(
            icon: Icons.star_rounded,
            size: btn,
            gradient: const LinearGradient(colors: [Color(0xFF34D399), Color(0xFF0EA5E9)]),
            badge: '${controller.bonus.length}',
            onTap: _showBonusSheet,
          ).animate(key: ValueKey(controller.bonus.length)).scaleXY(begin: 1.25, end: 1, duration: 500.ms, curve: Curves.elasticOut)),
      1,
      dx: -28,
    );

    final wheelWidget = LetterWheel(size: wheel)
        .animate()
        .scaleXY(begin: 0.45, end: 1, duration: 780.ms, curve: Curves.elasticOut)
        .fadeIn(duration: 280.ms)
        .rotate(begin: -0.08, end: 0, duration: 700.ms, curve: Curves.easeOutBack);

    if (buttonsBeside) {
      final gap = min(18.0, (availWidth - wheel - 2 * buttonExtent) / 2);
      return SizedBox(
        width: availWidth,
        height: max(wheel + 8, (btn + 12) * 2 + 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: buttonExtent, child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [shuffle, bonus])),
            SizedBox(width: gap),
            wheelWidget,
            SizedBox(width: gap),
            SizedBox(width: buttonExtent, child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [hint, magic])),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        wheelWidget,
        const SizedBox(height: 10),
        SizedBox(
          width: availWidth,
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [shuffle, bonus, hint, magic],
          ),
        ),
      ],
    );
  }

  void _showBonusSheet() {
    final words = controller.bonus.toList()..sort();
    Get.bottomSheet(
      GlassBox(
        radius: 28,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        child: SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: Get.height * 0.72),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(3)),
                  ).animate().scaleXY(begin: 0.2, end: 1, duration: 450.ms, curve: Curves.easeOutBack),
                  const SizedBox(height: 14),
                  Text('Bonus Words', style: AppText.display(24))
                      .animate()
                      .fadeIn(duration: 250.ms)
                      .scaleXY(begin: 0.7, end: 1, duration: 500.ms, curve: Curves.easeOutBack),
                  const SizedBox(height: 4),
                  Text('Each extra word earns ${GameController.bonusReward} coins',
                          textAlign: TextAlign.center, style: AppText.body(13, color: Colors.white60))
                      .animate()
                      .fadeIn(delay: 120.ms),
                  const SizedBox(height: 18),
                  if (words.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('No bonus words yet — try finding hidden words!',
                          textAlign: TextAlign.center, style: AppText.body(14, color: Colors.white70)),
                    ).animate().fadeIn().slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic)
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final (i, w) in words.indexed)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: AppGradients.cool,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(color: AppColors.violet.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: Text(w.toUpperCase(), style: AppText.display(15, spacing: 1)),
                          )
                              .animate()
                              .fadeIn(delay: (i * 45).ms)
                              .scaleXY(begin: 0.4, end: 1, delay: (i * 45).ms, duration: 450.ms, curve: Curves.easeOutBack)
                              .shimmer(delay: (200 + i * 45).ms, duration: 700.ms, color: Colors.white.withValues(alpha: 0.6)),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      backgroundColor: const Color(0xFF241252).withValues(alpha: 0.85),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      isScrollControlled: true,
    );
  }
}
