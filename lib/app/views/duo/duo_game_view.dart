import 'dart:math';
import 'dart:ui';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';

import '../../controllers/duo_game_controller.dart';
import '../../controllers/game_controller.dart' show FeedbackType, WordFeedback;
import '../../models/duo_models.dart';
import '../../services/call_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/haptics.dart';
import '../widgets/animated_background.dart';
import '../widgets/common_widgets.dart';
import '../widgets/game_avatar.dart';
import '../widgets/premium_motion.dart';

class DuoGameView extends GetView<DuoGameController> {
  const DuoGameView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: Obx(() {
              if (controller.isSearching.value) {
                return _AutoMatchRadarView(controller: controller);
              }
              return _DuoArenaStage(controller: controller);
            }),
          ),
          // Floating incoming / active video PiP overlay
          Obx(() {
            if (controller.isSearching.value || controller.match.value == null) {
              return const SizedBox.shrink();
            }
            final call = controller.callController;
            if (call == null) return const SizedBox.shrink();
            return _DuoAudioVideoOverlay(
              call: call,
              opponent: controller.opponentInfo,
            );
          }),
          // Floating live chat toast bubble when opponent messages
          Obx(() {
            final toast = controller.latestChatToast.value;
            if (toast == null) return const SizedBox.shrink();
            return Positioned(
              top: MediaQuery.paddingOf(context).top + 118,
              right: 16,
              left: 16,
              child: Center(
                child: Pressable(
                  onTap: () => _openChatSheet(context),
                  child: GlassBox(
                    radius: 22,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedGameAvatar(avatarId: toast.senderAvatar, size: 28),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '${toast.senderName}: ${toast.text}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.body(12.5, weight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate(key: ValueKey(toast.id))
                      .fadeIn(duration: 200.ms)
                      .slideY(begin: -0.4, end: 0),
                ),
              ),
            );
          }),
          // Match Complete Overlay
          Obx(() {
            final m = controller.match.value;
            if (m == null || !m.isCompleted) return const SizedBox.shrink();
            return _DuoCompleteOverlay(controller: controller);
          }),
        ],
      ),
    );
  }

  void _openChatSheet(BuildContext context) {
    controller.isChatSheetOpen.value = true;
    controller.markChatRead();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DuoChatBottomSheet(controller: controller),
    ).whenComplete(() {
      controller.isChatSheetOpen.value = false;
      controller.markChatRead();
    });
  }
}

// ---------------------------------------------------------------------------
// 1. Auto-Matchmaking Radar View (Active Players in Gameplay)
// ---------------------------------------------------------------------------
class _AutoMatchRadarView extends StatelessWidget {
  const _AutoMatchRadarView({required this.controller});
  final DuoGameController controller;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 380;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Column(
        children: [
          Row(
            children: [
              GlassIconButton(
                icon: Icons.close_rounded,
                size: 44,
                onTap: controller.leaveOrForfeit,
              ),
              const SizedBox(width: 12),
              Text('DUO AUTO-MATCH', style: AppText.display(20, spacing: 1.5)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.green),
                ),
                child: Obx(
                  () => Text(
                    '00:0${controller.searchElapsedSec.value}',
                    style: AppText.display(14, color: AppColors.green),
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          SizedBox.square(
            dimension: compact ? 240 : 280,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                for (var i = 0; i < 3; i++)
                  Container(
                    width: (compact ? 110.0 : 130.0) + i * 52,
                    height: (compact ? 110.0 : 130.0) + i * 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.cyan.withValues(alpha: 0.25 - i * 0.06),
                        width: 1.5,
                      ),
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat())
                      .scaleXY(
                        begin: 0.75,
                        end: 1.25,
                        delay: (i * 400).ms,
                        duration: 1800.ms,
                      )
                      .fadeOut(delay: (i * 400).ms, duration: 1800.ms),
                OrbitHalo(size: compact ? 230 : 265),
                AnimatedGameAvatar(
                  avatarId: controller.activeLobbyPlayers.isNotEmpty
                      ? controller.activeLobbyPlayers.first.avatar
                      : 'word_mage',
                  size: compact ? 84 : 96,
                  isTurnActive: true,
                  badgeText: 'SCANNING',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Obx(
            () => Text(
              controller.searchStatusText.value,
              textAlign: TextAlign.center,
              style: AppText.display(compact ? 18 : 21, color: AppColors.gold),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '30-Second Turn Timer • Auto-Pass on Timeout • Live Audio/Video & Chat',
            textAlign: TextAlign.center,
            style: AppText.body(12.5, color: Colors.white70),
          ),
          const SizedBox(height: 20),
          Obx(() {
            final list = controller.activeLobbyPlayers;
            if (list.isEmpty) return const SizedBox.shrink();
            return GlassBox(
              radius: 20,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final p in list.take(3))
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedGameAvatar(
                            avatarId: p.avatar,
                            size: 38,
                            showOnline: true,
                            isOnline: true,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            p.name.split(' ').first,
                            style: AppText.body(10.5, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          }),
          const Spacer(),
          GradientButton(
            label: 'MATCH ACTIVE OPPONENT NOW',
            icon: Icons.flash_on_rounded,
            height: 54,
            expand: true,
            onTap: () => controller.startAutoMatch(instant: true),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2. Main 1v1 Duo Arena Stage
// ---------------------------------------------------------------------------
class _DuoArenaStage extends StatelessWidget {
  const _DuoArenaStage({required this.controller});
  final DuoGameController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final compact = box.maxWidth < 380;
        final short = box.maxHeight < 710;
        final wheelSize = min(
          min(box.maxWidth * (compact ? 0.54 : 0.60), box.maxHeight * (short ? 0.27 : 0.31)),
          310.0,
        );
        return Column(
          children: [
            _topHud(context, compact),
            const SizedBox(height: 4),
            _turnBanner(),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 10 : 16,
                  vertical: 4,
                ),
                child: _DuoCrosswordGrid(controller: controller),
              ),
            ),
            _DuoWordPreview(controller: controller),
            const SizedBox(height: 4),
            _wheelControlsRow(context, wheelSize, box.maxWidth, compact),
            SizedBox(height: short ? 6 : 10),
          ],
        );
      },
    );
  }

  Widget _topHud(BuildContext context, bool compact) {
    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 8 : 14, 6, compact ? 8 : 14, 0),
      child: Obx(() {
        final me = controller.meInfo;
        final opp = controller.opponentInfo;
        final myTurn = controller.isMyTurn;
        final secs = controller.remainingSeconds.value;
        final progress = (secs / 30.0).clamp(0.0, 1.0);
        final urgent = secs <= 6.0;

        final timerColor = urgent
            ? AppColors.red
            : (secs <= 12.0 ? AppColors.orange : AppColors.green);

        return GlassBox(
          radius: 24,
          blur: 10,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 12,
            vertical: 8,
          ),
          child: Row(
            children: [
              GlassIconButton(
                icon: Icons.arrow_back_rounded,
                size: compact ? 34 : 38,
                onTap: controller.leaveOrForfeit,
              ),
              const SizedBox(width: 6),
              // Player 1 (Me)
              Expanded(
                child: _playerCard(
                  name: me?.name ?? 'You',
                  avatar: me?.avatar ?? 'word_mage',
                  score: controller.myScore,
                  active: myTurn,
                  alignRight: false,
                  compact: compact,
                ),
              ),
              // Center 30-Second Turn Timer Ring
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: compact ? 54 : 62,
                      height: compact ? 54 : 62,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox.expand(
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 5,
                              backgroundColor: Colors.white12,
                              valueColor: AlwaysStoppedAnimation<Color>(timerColor),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${secs.ceil()}s',
                                style: AppText.display(
                                  compact ? 16 : 18,
                                  color: urgent ? AppColors.red : AppColors.gold,
                                ),
                              ),
                              Text(
                                'TURN',
                                style: AppText.body(
                                  8.5,
                                  color: Colors.white60,
                                  weight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Player 2 (Opponent)
              Expanded(
                child: _playerCard(
                  name: opp?.name ?? 'Rival',
                  avatar: opp?.avatar ?? 'cosmic_scribe',
                  score: controller.opponentScore,
                  active: !myTurn,
                  alignRight: true,
                  compact: compact,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _playerCard({
    required String name,
    required String avatar,
    required int score,
    required bool active,
    required bool alignRight,
    required bool compact,
  }) {
    final avatarWidget = AnimatedGameAvatar(
      avatarId: avatar,
      size: compact ? 36 : 42,
      isTurnActive: active,
    );
    final info = Expanded(
      child: Column(
        crossAxisAlignment:
            alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name.split(' ').first,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.display(
              compact ? 12.5 : 14,
              color: active ? AppColors.gold : Colors.white,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score PTS',
                style: AppText.display(
                  compact ? 13 : 14.5,
                  color: active ? AppColors.cyan : Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: active
            ? AppColors.gold.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? AppColors.gold.withValues(alpha: 0.65) : Colors.transparent,
        ),
      ),
      child: Row(
        children: alignRight
            ? [info, const SizedBox(width: 6), avatarWidget]
            : [avatarWidget, const SizedBox(width: 6), info],
      ),
    );
  }

  Widget _turnBanner() {
    return Obx(() {
      final myTurn = controller.isMyTurn;
      final banner = controller.actionBanner.value;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            gradient: myTurn ? AppGradients.gold : AppGradients.cool,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                myTurn ? Icons.flash_on_rounded : Icons.hourglass_top_rounded,
                size: 15,
                color: myTurn ? AppColors.ink : Colors.white,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  myTurn
                      ? 'YOUR 30s TURN — DRAG LETTERS TO MAKE A WORD!'
                      : (banner.isNotEmpty
                          ? banner
                          : "OPPONENT'S 30s TURN — GET READY!"),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.display(
                    11.5,
                    color: myTurn ? AppColors.ink : Colors.white,
                    spacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _wheelControlsRow(
    BuildContext context,
    double wheelSize,
    double availWidth,
    bool compact,
  ) {
    final btnSize = (wheelSize * 0.2).clamp(40.0, 54.0);
    final call = controller.callController;

    final shuffleBtn = ActionButton(
      icon: Icons.shuffle_rounded,
      size: btnSize,
      badge: 'MIX',
      onTap: controller.shuffle,
    );

    final passBtn = Obx(
      () => ActionButton(
        icon: Icons.skip_next_rounded,
        size: btnSize,
        gradient: controller.isMyTurn ? AppGradients.hot : AppGradients.cool,
        badge: 'PASS',
        onTap: controller.passTurnManually,
      ),
    );

    final videoBtn = Obx(() {
      final inCall = call != null && call.callState.value != DuoCallState.idle;
      return ActionButton(
        icon: inCall && call.isVideo.value
            ? Icons.videocam_off_rounded
            : Icons.videocam_rounded,
        size: btnSize,
        gradient: inCall && call.isVideo.value
            ? AppGradients.danger
            : AppGradients.gold,
        badge: inCall && call.isVideo.value ? 'END' : 'VIDEO',
        onTap: () {
          if (call == null) return;
          if (call.callState.value == DuoCallState.idle) {
            call.startCall(video: true);
          } else {
            call.endCall();
          }
        },
      );
    });

    final audioChatRow = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Obx(() {
          final inCall = call != null && call.callState.value != DuoCallState.idle;
          return ActionButton(
            icon: inCall && !call.isVideo.value
                ? Icons.call_end_rounded
                : Icons.mic_rounded,
            size: btnSize,
            gradient: inCall && !call.isVideo.value
                ? AppGradients.danger
                : const LinearGradient(
                    colors: [Color(0xFF34D399), Color(0xFF0EA5E9)],
                  ),
            badge: inCall && !call.isVideo.value ? 'END' : 'AUDIO',
            onTap: () {
              if (call == null) return;
              if (call.callState.value == DuoCallState.idle) {
                call.startCall(video: false);
              } else {
                call.endCall();
              }
            },
          );
        }),
        const SizedBox(height: 8),
        Obx(() {
          final unread = controller.unreadChat.value;
          return ActionButton(
            icon: Icons.forum_rounded,
            size: btnSize,
            gradient: AppGradients.cool,
            badge: unread > 0 ? '$unread NEW' : 'CHAT',
            onTap: () => _openChat(context),
          );
        }),
      ],
    );

    return SizedBox(
      width: availWidth,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              shuffleBtn,
              const SizedBox(height: 8),
              passBtn,
            ],
          ),
          _DuoLetterWheel(controller: controller, size: wheelSize),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              videoBtn,
              const SizedBox(height: 8),
              audioChatRow,
            ],
          ),
        ],
      ),
    );
  }

  void _openChat(BuildContext context) {
    controller.isChatSheetOpen.value = true;
    controller.markChatRead();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DuoChatBottomSheet(controller: controller),
    ).whenComplete(() {
      controller.isChatSheetOpen.value = false;
      controller.markChatRead();
    });
  }
}

// ---------------------------------------------------------------------------
// 3. Shared Duo Crossword Grid (Color-coded by which player solved each word)
// ---------------------------------------------------------------------------
class _DuoCrosswordGrid extends StatelessWidget {
  const _DuoCrosswordGrid({required this.controller});
  final DuoGameController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        return Obx(() {
          final p = controller.puzzle.value;
          final m = controller.match.value;
          if (p == null || m == null) return const SizedBox.shrink();

          final revealed = m.revealed.toSet();
          final cellOwner = <String, String>{};
          for (final w in p.words) {
            final owner = m.wordOwners[w.word];
            if (owner != null) {
              for (final c in w.cells) {
                cellOwner[c.key] = owner;
              }
            }
          }

          const gapRatio = 0.1;
          final cell = min(
            box.maxWidth / (p.cols + (p.cols - 1) * gapRatio),
            box.maxHeight / (p.rows + (p.rows - 1) * gapRatio),
          ).clamp(0.0, 68.0);
          final gap = cell * gapRatio;
          final width = cell * p.cols + gap * (p.cols - 1);
          final height = cell * p.rows + gap * (p.rows - 1);

          return Center(
            child: SizedBox(
              width: width,
              height: height,
              child: Stack(
                children: [
                  for (final e in p.letterMap.entries)
                    _buildCell(
                      e.key,
                      e.value,
                      cell,
                      gap,
                      revealed.contains(e.key),
                      cellOwner[e.key] == controller.myUid,
                    ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Widget _buildCell(
    String key,
    String letter,
    double cell,
    double gap,
    bool visible,
    bool isMine,
  ) {
    final parts = key.split(',');
    final r = int.parse(parts[0]);
    final c = int.parse(parts[1]);
    final radius = BorderRadius.circular(cell * 0.22);

    return Positioned(
      left: c * (cell + gap),
      top: r * (cell + gap),
      width: cell,
      height: cell,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: radius,
              color: Colors.white.withValues(alpha: 0.13),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.24),
                width: 1.2,
              ),
            ),
          ),
          if (visible)
            Container(
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: isMine ? AppGradients.gold : AppGradients.cool,
                border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: (isMine ? AppColors.gold : AppColors.cyan)
                        .withValues(alpha: 0.5),
                    blurRadius: 10,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                letter.toUpperCase(),
                style: AppText.display(
                  cell * 0.56,
                  color: isMine ? AppColors.ink : Colors.white,
                ),
              ),
            )
                .animate()
                .scaleXY(begin: 0.3, end: 1, duration: 420.ms, curve: Curves.elasticOut),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 4. Duo Word Preview & Feedback Bar
// ---------------------------------------------------------------------------
class _DuoWordPreview extends StatelessWidget {
  const _DuoWordPreview({required this.controller});
  final DuoGameController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Center(
        child: Obx(() {
          final w = controller.current.value;
          final fb = controller.feedback.value;
          if (w.isNotEmpty) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              decoration: BoxDecoration(
                gradient: AppGradients.hot,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white70),
              ),
              child: Text(
                w.toUpperCase(),
                style: AppText.display(22, spacing: 2),
              ),
            );
          }
          if (fb != null) {
            return _feedbackPill(fb);
          }
          return const SizedBox.shrink();
        }),
      ),
    );
  }

  Widget _feedbackPill(WordFeedback fb) {
    final gradient = switch (fb.type) {
      FeedbackType.correct => AppGradients.success,
      FeedbackType.bonus => AppGradients.cool,
      _ => AppGradients.danger,
    };
    final label = switch (fb.type) {
      FeedbackType.correct => '✓ ${fb.word.toUpperCase()} (+${fb.word.length * 10} PTS)',
      FeedbackType.bonus => '★ BONUS ${fb.word.toUpperCase()} (+5 PTS)',
      FeedbackType.repeat => 'ALREADY FOUND',
      FeedbackType.tooShort => 'TOO SHORT',
      _ => controller.isMyTurn ? fb.word.toUpperCase() : "WAIT FOR YOUR TURN!",
    };
    return Container(
      key: ValueKey(fb.id),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(label, style: AppText.display(16, spacing: 1.2)),
    ).animate().scaleXY(begin: 0.6, end: 1, duration: 260.ms, curve: Curves.easeOutBack);
  }
}

// ---------------------------------------------------------------------------
// 5. Duo Circular Letter Wheel
// ---------------------------------------------------------------------------
class _DuoLetterWheel extends StatefulWidget {
  const _DuoLetterWheel({required this.controller, required this.size});
  final DuoGameController controller;
  final double size;

  @override
  State<_DuoLetterWheel> createState() => _DuoLetterWheelState();
}

class _DuoLetterWheelState extends State<_DuoLetterWheel>
    with SingleTickerProviderStateMixin {
  final List<int> _selected = [];
  Offset? _finger;
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  )..repeat();

  DuoGameController get _c => widget.controller;
  int get _n => _c.wheel.length;
  double get _tile =>
      widget.size * (_n <= 4 ? 0.27 : (_n == 5 ? 0.25 : (_n == 6 ? 0.225 : 0.205)));

  Offset _slotCenter(int slot) {
    final s = widget.size;
    final r = s / 2 - _tile / 2 - s * 0.055;
    final a = -pi / 2 + 2 * pi * slot / max(1, _n);
    return Offset(s / 2 + r * cos(a), s / 2 + r * sin(a));
  }

  Offset _centerOf(int id) =>
      _slotCenter(_c.wheel.indexWhere((l) => l.id == id).clamp(0, max(0, _n - 1)));

  String get _word =>
      _selected.map((id) => _c.wheel.firstWhere((l) => l.id == id).char).join();

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

  void _end() {
    final w = _word;
    setState(() {
      _selected.clear();
      _finger = null;
    });
    _c.submit(w);
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final letters = _c.wheel.toList();
      final myTurn = _c.isMyTurn;
      final s = widget.size;
      final tile = _tile;

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanDown: (d) {
          _c.startSelection();
          _selected.clear();
          _track(d.localPosition);
        },
        onPanUpdate: (d) => _track(d.localPosition),
        onPanEnd: (_) => _end(),
        onPanCancel: _end,
        child: SizedBox.square(
          dimension: s,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _spin,
                  builder: (_, __) {
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
                      ),
                      padding: const EdgeInsets.all(3),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF221150)
                              .withValues(alpha: myTurn ? 0.95 : 0.78),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _DuoLinkPainter(
                    points: _selected.map(_centerOf).toList(),
                    finger: _finger,
                    width: tile * 0.2,
                  ),
                ),
              ),
              for (final (i, l) in letters.indexed)
                AnimatedPositioned(
                  key: ValueKey('duo_${l.id}'),
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeOutBack,
                  left: _slotCenter(i).dx - tile / 2,
                  top: _slotCenter(i).dy - tile / 2,
                  width: tile,
                  height: tile,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient:
                          _selected.contains(l.id) ? AppGradients.hot : AppGradients.tile,
                      border: Border.all(color: Colors.white70, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      l.char.toUpperCase(),
                      style: AppText.display(
                        tile * 0.52,
                        color: _selected.contains(l.id) ? Colors.white : AppColors.ink,
                      ),
                    ),
                  ),
                ),
              if (!myTurn)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.cyan.withValues(alpha: 0.6)),
                    ),
                    child: Text(
                      "RIVAL'S TURN",
                      style: AppText.display(11, color: AppColors.cyan, spacing: 1),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}

class _DuoLinkPainter extends CustomPainter {
  _DuoLinkPainter({required this.points, required this.finger, required this.width});
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
        ..shader = AppGradients.hot.createShader(Offset.zero & size)
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _DuoLinkPainter oldDelegate) => true;
}

// ---------------------------------------------------------------------------
// 6. Live Audio / Video Call Overlay (WebRTC Camera PiP + Voice Equalizer)
// ---------------------------------------------------------------------------
class _DuoAudioVideoOverlay extends StatelessWidget {
  const _DuoAudioVideoOverlay({
    required this.call,
    required this.opponent,
  });

  final DuoCallController call;
  final DuoPlayerInfo? opponent;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = call.callState.value;
      if (state == DuoCallState.idle) return const SizedBox.shrink();

      if (state == DuoCallState.incoming) {
        return Positioned(
          top: MediaQuery.paddingOf(context).top + 78,
          left: 16,
          right: 16,
          child: GlassBox(
            radius: 22,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(
                  call.isVideo.value ? Icons.videocam_rounded : Icons.call_rounded,
                  color: AppColors.gold,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    call.statusText.value,
                    style: AppText.display(14),
                  ),
                ),
                GlassIconButton(
                  icon: Icons.call_end_rounded,
                  size: 38,
                  onTap: call.endCall,
                ),
                const SizedBox(width: 8),
                GlassIconButton(
                  icon: Icons.check_rounded,
                  size: 38,
                  onTap: call.acceptIncomingCall,
                ),
              ],
            ),
          ),
        );
      }

      // Connected or Calling: Show Audio/Video PiP HUD
      return Positioned(
        top: MediaQuery.paddingOf(context).top + 82,
        right: 12,
        child: GlassBox(
          radius: 22,
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (call.isVideo.value)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Local Camera Feed
                    Container(
                      width: 82,
                      height: 102,
                      decoration: BoxDecoration(
                        color: const Color(0xFF140B36),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.gold, width: 1.5),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (call.localVideoReady.value && !call.camOff.value)
                            RTCVideoView(
                              call.localRenderer,
                              mirror: true,
                              objectFit:
                                  RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                            )
                          else
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.videocam_rounded,
                                    color: AppColors.gold,
                                    size: 24,
                                  ),
                                  Text('YOU', style: AppText.display(10)),
                                ],
                              ),
                            ),
                          Positioned(
                            bottom: 4,
                            left: 6,
                            child: Text('YOU', style: AppText.display(9.5)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Remote Opponent Video / Holographic Feed
                    Container(
                      width: 82,
                      height: 102,
                      decoration: BoxDecoration(
                        color: const Color(0xFF140B36),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.cyan, width: 1.5),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (call.remoteVideoReady.value)
                            RTCVideoView(
                              call.remoteRenderer,
                              objectFit:
                                  RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                            )
                          else
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedGameAvatar(
                                    avatarId: opponent?.avatar ?? 'cosmic_scribe',
                                    size: 42,
                                    isTurnActive: true,
                                  ),
                                  const SizedBox(height: 6),
                                  const AudioEqualizerBars(
                                    active: true,
                                    color: AppColors.cyan,
                                    barCount: 5,
                                    height: 14,
                                  ),
                                ],
                              ),
                            ),
                          Positioned(
                            bottom: 4,
                            left: 6,
                            child: Text(
                              (opponent?.name ?? 'RIVAL').split(' ').first.toUpperCase(),
                              style: AppText.display(9.5, color: AppColors.cyan),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AudioEqualizerBars(
                    active: !call.micMuted.value,
                    color: AppColors.green,
                    barCount: 4,
                    height: 14,
                  ),
                  const SizedBox(width: 8),
                  GlassIconButton(
                    icon: call.micMuted.value ? Icons.mic_off_rounded : Icons.mic_rounded,
                    size: 32,
                    onTap: call.toggleMute,
                  ),
                  if (call.isVideo.value) ...[
                    const SizedBox(width: 6),
                    GlassIconButton(
                      icon: Icons.cameraswitch_rounded,
                      size: 32,
                      onTap: call.switchCamera,
                    ),
                  ],
                  const SizedBox(width: 6),
                  GlassIconButton(
                    icon: Icons.call_end_rounded,
                    size: 32,
                    onTap: call.endCall,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }
}

// ---------------------------------------------------------------------------
// 7. In-Game Chat Bottom Sheet (Quick Stickers + Live Chat Messages)
// ---------------------------------------------------------------------------
class _DuoChatBottomSheet extends StatefulWidget {
  const _DuoChatBottomSheet({required this.controller});
  final DuoGameController controller;

  @override
  State<_DuoChatBottomSheet> createState() => _DuoChatBottomSheetState();
}

class _DuoChatBottomSheetState extends State<_DuoChatBottomSheet> {
  final _txt = TextEditingController();

  static const _quickMessages = [
    '🔥 Nice word!',
    '⏳ Hurry up! 30s ticking!',
    '😎 Good luck!',
    '👏 Well played!',
    '🤯 So close!',
  ];

  void _send([String? preset]) {
    final text = (preset ?? _txt.text).trim();
    if (text.isEmpty) return;
    if (preset == null) _txt.clear();
    widget.controller.sendChatMessage(text, isQuick: preset != null);
  }

  @override
  void dispose() {
    _txt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: GlassBox(
        radius: 28,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.62,
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.forum_rounded, color: AppColors.gold, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Live Duel Chat with ${widget.controller.opponentInfo?.name ?? "Rival"}',
                      style: AppText.display(17),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  ),
                ],
              ),
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _quickMessages.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => Pressable(
                    onTap: () => _send(_quickMessages[i]),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Text(_quickMessages[i], style: AppText.body(12)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Obx(() {
                  final list = widget.controller.messages;
                  if (list.isEmpty) {
                    return Center(
                      child: Text(
                        'Send a message or reaction to your opponent! 👋',
                        style: AppText.body(13, color: Colors.white60),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final m = list[i];
                      final mine = m.senderId == widget.controller.myUid;
                      return Align(
                        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            gradient: mine ? AppGradients.gold : AppGradients.cool,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.senderName,
                                style: AppText.body(
                                  10,
                                  color: mine ? AppColors.ink : Colors.white70,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                m.text,
                                style: AppText.body(
                                  14,
                                  color: mine ? AppColors.ink : Colors.white,
                                  weight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: TextField(
                        controller: _txt,
                        style: AppText.body(14),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Type message...',
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Pressable(
                    onTap: _send,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppGradients.gold,
                      ),
                      child: const Icon(Icons.send_rounded, color: AppColors.ink),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 8. Duo Match Complete Overlay
// ---------------------------------------------------------------------------
class _DuoCompleteOverlay extends StatefulWidget {
  const _DuoCompleteOverlay({required this.controller});
  final DuoGameController controller;

  @override
  State<_DuoCompleteOverlay> createState() => _DuoCompleteOverlayState();
}

class _DuoCompleteOverlayState extends State<_DuoCompleteOverlay> {
  final _confetti = ConfettiController(duration: const Duration(seconds: 3));

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
    final m = widget.controller.match.value!;
    final won = m.winnerId == widget.controller.myUid;
    final tie = m.winnerId == 'tie';

    return Stack(
      children: [
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withValues(alpha: 0.55)),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 35,
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: GlassBox(
                radius: 30,
                padding: const EdgeInsets.all(26),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      won
                          ? Icons.emoji_events_rounded
                          : (tie ? Icons.handshake_rounded : Icons.military_tech_rounded),
                      size: 68,
                      color: AppColors.gold,
                    ).animate().scaleXY(begin: 0.3, end: 1, duration: 600.ms, curve: Curves.elasticOut),
                    const SizedBox(height: 10),
                    Text(
                      won ? 'DUO VICTORY!' : (tie ? 'EPIC DRAW!' : 'GOOD DUEL!'),
                      style: AppText.display(30, color: AppColors.gold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Final Score: ${widget.controller.myScore}  —  ${widget.controller.opponentScore}',
                      style: AppText.display(20),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      won
                          ? '+50 Coins  •  +30 Trophies'
                          : (tie ? '+25 Coins  •  +10 Trophies' : '+15 Coins Participation'),
                      style: AppText.body(14, color: AppColors.cyan, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 22),
                    GradientButton(
                      label: 'PLAY ANOTHER DUO',
                      icon: Icons.replay_rounded,
                      height: 54,
                      expand: true,
                      onTap: () => widget.controller.startAutoMatch(instant: false),
                    ),
                    const SizedBox(height: 10),
                    Pressable(
                      onTap: () => Get.back(),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'BACK TO LOBBY',
                          style: AppText.body(13, color: Colors.white70, weight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
