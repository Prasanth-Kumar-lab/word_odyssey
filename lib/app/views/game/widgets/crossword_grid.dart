import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import '../../../controllers/game_controller.dart';
import '../../../theme/app_theme.dart';

class CrosswordGrid extends GetView<GameController> {
  const CrosswordGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      return Obx(() {
        final p = controller.puzzle.value;
        if (p == null) return const SizedBox.shrink();
        final revealed = controller.revealed.toSet();
        final flash = controller.flashWord.value;
        final tick = controller.flashTick.value;
        final flashCells = flash.isEmpty
            ? const <String>{}
            : (p.wordOf(flash)?.cells.map((c) => c.key).toSet() ?? const <String>{});

        final gapRatio = 0.1;
        final cap = box.biggest.shortestSide > 700 ? 92.0 : 74.0;
        final cell = min(
          box.maxWidth / (p.cols + (p.cols - 1) * gapRatio),
          box.maxHeight / (p.rows + (p.rows - 1) * gapRatio),
        ).clamp(0.0, cap);
        final gap = cell * gapRatio;
        final width = cell * p.cols + gap * (p.cols - 1);
        final height = cell * p.rows + gap * (p.rows - 1);

        return Center(
          child: SizedBox(
            key: ValueKey(p.id),
            width: width,
            height: height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (final e in p.letterMap.entries)
                  _positioned(e.key, e.value, cell, gap, revealed, flashCells, tick),
              ],
            ),
          ),
        );
      });
    });
  }

  Widget _positioned(String key, String letter, double cell, double gap, Set<String> revealed,
      Set<String> flashCells, int tick) {
    final parts = key.split(',');
    final r = int.parse(parts[0]), c = int.parse(parts[1]);
    Widget tile = _LetterCell(
      letter: letter,
      size: cell,
      visible: revealed.contains(key),
      delay: controller.revealDelay[key] ?? 0,
    );
    if (flashCells.contains(key)) {
      tile = tile
          .animate(key: ValueKey('flash$tick'))
          .scaleXY(begin: 1, end: 1.18, duration: 160.ms, curve: Curves.easeOut)
          .then()
          .scaleXY(begin: 1, end: 1 / 1.18, duration: 260.ms, curve: Curves.elasticOut)
          .shake(hz: 5, rotation: 0.06, duration: 400.ms);
    }
    return Positioned(
      left: c * (cell + gap),
      top: r * (cell + gap),
      width: cell,
      height: cell,
      child: tile
          .animate()
          .fadeIn(delay: ((r + c) * 35).ms, duration: 300.ms)
          .scaleXY(begin: 0.4, end: 1, delay: ((r + c) * 35).ms, duration: 450.ms, curve: Curves.easeOutBack),
    );
  }
}

class _LetterCell extends StatelessWidget {
  const _LetterCell({
    required this.letter,
    required this.size,
    required this.visible,
    required this.delay,
  });

  final String letter;
  final double size;
  final bool visible;
  final int delay;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.22);
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            color: Colors.white.withValues(alpha: 0.13),
            border: Border.all(color: Colors.white.withValues(alpha: 0.22), width: 1.2),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 6, offset: const Offset(0, 3))],
          ),
        ),
        if (visible)
          Container(
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: AppGradients.gold,
              border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 1.5),
              boxShadow: [
                BoxShadow(color: AppColors.orange.withValues(alpha: 0.55), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              letter.toUpperCase(),
              style: AppText.display(size * 0.58, color: AppColors.ink),
            ),
          )
              .animate()
              .fadeIn(delay: delay.ms, duration: 120.ms)
              .scaleXY(begin: 0.2, end: 1, delay: delay.ms, duration: 650.ms, curve: Curves.elasticOut)
              .flipH(begin: -0.5, end: 0, delay: delay.ms, duration: 400.ms, curve: Curves.easeOut)
              .then(delay: 100.ms)
              .shimmer(duration: 800.ms, color: Colors.white.withValues(alpha: 0.85)),
      ],
    );
  }
}
