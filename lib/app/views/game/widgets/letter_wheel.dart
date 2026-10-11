import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import '../../../controllers/game_controller.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/haptics.dart';

/// Circular letter wheel: drag across letters to build a word.
class LetterWheel extends StatefulWidget {
  const LetterWheel({super.key, required this.size});
  final double size;

  @override
  State<LetterWheel> createState() => _LetterWheelState();
}

class _LetterWheelState extends State<LetterWheel> with SingleTickerProviderStateMixin {
  final _c = Get.find<GameController>();
  final List<int> _selected = [];
  Offset? _finger;
  late final AnimationController _spin =
      AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  int get _n => _c.wheel.length;

  double get _tile => widget.size * (_n <= 4 ? 0.27 : _n == 5 ? 0.25 : _n == 6 ? 0.225 : 0.205);

  Offset _slotCenter(int slot) {
    final s = widget.size;
    final r = s / 2 - _tile / 2 - s * 0.055;
    final a = -pi / 2 + 2 * pi * slot / _n;
    return Offset(s / 2 + r * cos(a), s / 2 + r * sin(a));
  }

  Offset _centerOf(int id) => _slotCenter(_c.wheel.indexWhere((l) => l.id == id));

  String get _word => _selected.map((id) => _c.wheel.firstWhere((l) => l.id == id).char).join();

  int? _hit(Offset p) {
    for (var i = 0; i < _n; i++) {
      if ((p - _slotCenter(i)).distance < _tile * 0.6) return _c.wheel[i].id;
    }
    return null;
  }

  void _track(Offset p) {
    final id = _hit(p);
    if (id != null) {
      if (!_selected.contains(id)) {
        _selected.add(id);
        Haptics.tick();
        _c.onLetterSelected(_selected.length);
      } else if (_selected.length >= 2 && _selected[_selected.length - 2] == id) {
        _selected.removeLast();
        Haptics.tick();
        _c.onLetterSelected(_selected.length);
      }
    }
    setState(() => _finger = p);
    _c.current.value = _word;
  }

  void _end({bool submit = true}) {
    final w = _word;
    setState(() {
      _selected.clear();
      _finger = null;
    });
    if (submit) {
      _c.submit(w);
    } else {
      _c.current.value = '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final letters = _c.wheel.toList();
      final pid = _c.puzzle.value?.id ?? '';
      final s = widget.size;
      final tile = _tile;

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanDown: (d) {
          if (_c.completed.value) return;
          _c.startSelection();
          _selected.clear();
          _track(d.localPosition);
        },
        onPanUpdate: (d) {
          if (_c.completed.value) return;
          _track(d.localPosition);
        },
        onPanEnd: (_) => _end(),
        onPanCancel: () => _end(submit: _selected.length > 1),
        child: SizedBox.square(
          dimension: s,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Rotating glow ring + glass disc
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _spin,
                  builder: (_, __) {
                    final breathe = 0.5 + 0.5 * sin(_spin.value * pi * 2);
                    return Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          transform: GradientRotation(_spin.value * pi * 2),
                          colors: [
                            AppColors.violet.withValues(alpha: 0.9),
                            AppColors.cyan.withValues(alpha: 0.9),
                            AppColors.pink.withValues(alpha: 0.9),
                            AppColors.gold.withValues(alpha: 0.9),
                            AppColors.violet.withValues(alpha: 0.9),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.violet.withValues(alpha: 0.28 + 0.28 * breathe),
                            blurRadius: 28 + 18 * breathe,
                            spreadRadius: 1 + breathe,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(3),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [
                            const Color(0xFF3B2280).withValues(alpha: 0.95),
                            const Color(0xFF1C0F4A).withValues(alpha: 0.97),
                          ]),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _LinkPainter(
                    points: _selected.map(_centerOf).toList(),
                    finger: _finger,
                    width: tile * 0.2,
                  ),
                ),
              ),
              for (final (i, l) in letters.indexed)
                AnimatedPositioned(
                  key: ValueKey('$pid-${l.id}'),
                  duration: const Duration(milliseconds: 520),
                  curve: Curves.easeInOutBack,
                  left: _slotCenter(i).dx - tile / 2,
                  top: _slotCenter(i).dy - tile / 2,
                  width: tile,
                  height: tile,
                  child: _WheelTile(
                    letter: l.char,
                    size: tile,
                    selected: _selected.contains(l.id),
                  )
                      .animate()
                      .scaleXY(begin: 0, end: 1, delay: (150 + l.id * 80).ms, duration: 600.ms, curve: Curves.elasticOut)
                      .rotate(begin: -0.25, end: 0, delay: (150 + l.id * 80).ms, duration: 500.ms),
                ),
            ],
          ),
        ),
      );
    });
  }
}

class _WheelTile extends StatelessWidget {
  const _WheelTile({required this.letter, required this.size, required this.selected});
  final String letter;
  final double size;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: selected ? 1.14 : 1,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutBack,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: selected ? AppGradients.hot : AppGradients.tile,
          border: Border.all(color: Colors.white.withValues(alpha: selected ? 0.9 : 0.6), width: 2),
          boxShadow: [
            BoxShadow(
              color: (selected ? AppColors.pink : Colors.black).withValues(alpha: selected ? 0.7 : 0.3),
              blurRadius: selected ? 22 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 220),
          style: AppText.display(size * 0.52, color: selected ? Colors.white : AppColors.ink),
          child: Text(letter.toUpperCase()),
        ),
      ),
    );
  }
}

class _LinkPainter extends CustomPainter {
  _LinkPainter({required this.points, required this.finger, required this.width});
  final List<Offset> points;
  final Offset? finger;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    if (finger != null) path.lineTo(finger!.dx, finger!.dy);

    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.pink.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = width * 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawPath(
      path,
      Paint()
        ..shader = AppGradients.hot.createShader(Offset.zero & size)
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _LinkPainter old) => true;
}
