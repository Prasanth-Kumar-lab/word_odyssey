import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import '../../controllers/home_controller.dart';
import '../../theme/app_theme.dart';
import '../widgets/animated_background.dart';
import '../widgets/common_widgets.dart';
import '../widgets/game_avatar.dart';
import '../widgets/premium_motion.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 380;
    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: Column(
              children: [
                _topBar(compact),
                Expanded(
                  child: LayoutBuilder(builder: (context, box) {
                    final wide = box.maxWidth >= 900 ||
                        (box.maxWidth > box.maxHeight && box.maxWidth >= 740);
                    final padH = box.maxWidth < 360 ? 14.0 : 22.0;
                    final padV = box.maxHeight < 640 ? 8.0 : 14.0;
                    return SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: max(0, box.maxHeight - padV * 2),
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: wide ? 1120 : 540),
                            child: wide ? _sideBySide(box) : _stacked(box),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBar(bool compact) {
    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 10 : 16, 8, compact ? 10 : 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Obx(() {
                final u = controller.user.value;
                return Pressable(
                  onTap: controller.openProfile,
                  child: GlassBox(
                    radius: 28,
                    blur: 10,
                    padding: const EdgeInsets.fromLTRB(6, 5, 12, 5),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedGameAvatar(
                          avatarId: u.avatar,
                          size: compact ? 36 : 40,
                          showOnline: true,
                          isOnline: true,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                u.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.display(compact ? 13.5 : 15),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.emoji_events_rounded,
                                    color: AppColors.gold,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 3),
                                  Flexible(
                                    child: Text(
                                      '${u.trophies} • ${u.title}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppText.body(
                                        10,
                                        color: AppColors.cyan,
                                        weight: FontWeight.w700,
                                      ),
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
                );
              }),
            ),
          ),
          const SizedBox(width: 6),
          Obx(
            () => GlassIconButton(
              size: compact ? 38 : 44,
              icon: controller.soundOn.value
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_rounded,
              onTap: controller.toggleSound,
            ),
          ),
          const SizedBox(width: 6),
          Obx(
            () => GlassIconButton(
              size: compact ? 38 : 44,
              icon: controller.haptics.value
                  ? Icons.vibration_rounded
                  : Icons.phone_android_rounded,
              onTap: controller.toggleHaptics,
            ),
          ),
          const SizedBox(width: 6),
          Obx(() => CoinChip(coins: controller.coins.value)),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 450.ms)
        .slideY(begin: -0.8, end: 0, duration: 600.ms, curve: Curves.easeOutBack);
  }

  Widget _stacked(BoxConstraints box) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _hero(box, wide: false),
        SizedBox(height: (box.maxHeight * 0.025).clamp(12, 24)),
        _actions(box),
      ],
    );
  }

  Widget _sideBySide(BoxConstraints box) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: _hero(box, wide: true)),
        SizedBox(width: max(24, box.maxWidth * 0.04)),
        Expanded(child: _actions(box)),
      ],
    );
  }

  Widget _hero(BoxConstraints box, {required bool wide}) {
    final short = box.maxHeight < 680;
    final base = wide ? min(box.maxWidth * 0.46, 540.0) : min(box.maxWidth, 500.0);
    final tile = (base / 7.5).clamp(short ? 30.0 : 36.0, wide ? 72.0 : 62.0);
    final orb = tile * (short ? 1.7 : (wide ? 2.15 : 2.15));
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (i, letter) in 'WORD'.split('').indexed)
              LogoTile(letter, size: tile)
                  .animate()
                  .fadeIn(delay: (i * 80).ms, duration: 280.ms)
                  .scaleXY(
                    begin: 0.3,
                    end: 1,
                    delay: (i * 80).ms,
                    duration: 700.ms,
                    curve: Curves.elasticOut,
                  )
                  .rotate(
                    begin: i.isEven ? -0.25 : 0.25,
                    end: 0,
                    delay: (i * 80).ms,
                    duration: 600.ms,
                  )
                  .then(delay: 200.ms)
                  .shimmer(duration: 900.ms, color: Colors.white.withValues(alpha: 0.75))
                  .animate(
                    onPlay: (c) => c.repeat(reverse: true),
                    delay: (i * 160).ms,
                  )
                  .moveY(begin: 0, end: -7, duration: 1500.ms, curve: Curves.easeInOut),
          ],
        ),
        const SizedBox(height: 6),
        ShaderMask(
          shaderCallback: (r) => AppGradients.cool.createShader(r),
          blendMode: BlendMode.srcIn,
          child: Text(
            'ODYSSEY',
            style: AppText.display((tile * 0.56).clamp(20, 44), spacing: tile * 0.08),
          ),
        )
            .animate()
            .fadeIn(delay: 280.ms, duration: 500.ms)
            .slideX(begin: 0.15, end: 0, delay: 280.ms, duration: 600.ms),
        const SizedBox(height: 4),
        Text(
          'SOLO QUEST & 1V1 LIVE DUO ARENA',
          style: AppText.body(
            (tile * 0.19).clamp(9.5, 12.5),
            color: Colors.white60,
            weight: FontWeight.w700,
            spacing: 2.0,
          ),
        ).animate().fadeIn(delay: 420.ms),
        SizedBox(height: short ? 12 : 18),
        _levelOrb(orb),
      ],
    );
  }

  Widget _levelOrb(double size) {
    return Pressable(
      onTap: controller.openProfile,
      child: SizedBox.square(
        dimension: size * 1.2,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            OrbitHalo(size: size * 1.2),
            SizedBox.square(
              dimension: size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const SweepGradient(colors: [
                        AppColors.gold,
                        AppColors.pink,
                        AppColors.violet,
                        AppColors.cyan,
                        AppColors.gold,
                      ]),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.pink.withValues(alpha: 0.45),
                          blurRadius: 34,
                        ),
                      ],
                    ),
                  ).animate(onPlay: (c) => c.repeat()).rotate(duration: 8000.ms),
                  Container(
                    margin: EdgeInsets.all(size * 0.045),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [Color(0xFF4A2A9A), Color(0xFF1C0F4A)],
                      ),
                    ),
                  ),
                  Obx(
                    () => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'LEVEL',
                          style: AppText.body(
                            size * 0.09,
                            color: Colors.white70,
                            weight: FontWeight.w700,
                            spacing: 2.4,
                          ),
                        ),
                        Text(
                          '${controller.level.value}',
                          style: AppText.display(size * 0.3, color: AppColors.gold),
                        )
                            .animate(key: ValueKey(controller.level.value))
                            .scaleXY(
                              begin: 0.4,
                              end: 1,
                              duration: 700.ms,
                              curve: Curves.elasticOut,
                            )
                            .shimmer(duration: 800.ms, color: Colors.white),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .scaleXY(
          begin: 0.2,
          end: 1,
          delay: 250.ms,
          duration: 900.ms,
          curve: Curves.elasticOut,
        )
        .fadeIn(delay: 200.ms, duration: 300.ms);
  }

  Widget _actions(BoxConstraints box) {
    final short = box.maxHeight < 640;
    final buttonH = short ? 56.0 : 64.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. SOLO MODE BUTTON
        SoftPulse(
          borderRadius: buttonH / 2,
          child: GradientButton(
            label: 'SOLO ODYSSEY',
            icon: Icons.play_arrow_rounded,
            height: buttonH,
            expand: true,
            onTap: controller.playSolo,
          ),
        )
            .animate()
            .fadeIn(delay: 350.ms, duration: 300.ms)
            .slideY(begin: 0.4, end: 0, delay: 350.ms, duration: 550.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 12),
        // 2. DUO MULTIPLAYER (AUTO-MATCH + 30S TIMER + CHAT + AUDIO/VIDEO)
        Pressable(
          onTap: controller.playDuo,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF8B5CF6), Color(0xFFEC4899), Color(0xFFFF8A3D)],
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: Colors.white.withValues(alpha: 0.65), width: 1.8),
              boxShadow: [
                BoxShadow(
                  color: AppColors.pink.withValues(alpha: 0.5),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  child: const Icon(
                    Icons.sports_kabaddi_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'DUO MULTIPLAYER',
                            style: AppText.display(18, spacing: 1.2),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.ink,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.gold),
                            ),
                            child: Text(
                              '30s TIMER',
                              style: AppText.display(9.5, color: AppColors.gold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Auto-Match • Live Audio/Video • In-Game Chat',
                        style: AppText.body(
                          11.5,
                          color: Colors.white.withValues(alpha: 0.9),
                          weight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ],
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .shimmer(delay: 2200.ms, duration: 1400.ms, color: Colors.white54),
        )
            .animate()
            .fadeIn(delay: 460.ms, duration: 320.ms)
            .slideY(begin: 0.4, end: 0, delay: 460.ms, duration: 550.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 14),
        _activePlayersBar(),
        const SizedBox(height: 14),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Obx(
            () => Row(
              children: [
                Expanded(
                  child: _statCard(
                    'Words',
                    controller.wordsTotal.value,
                    Icons.text_fields_rounded,
                    AppColors.cyan,
                    0,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _statCard(
                    'Bonus',
                    controller.bonusTotal.value,
                    Icons.auto_awesome_rounded,
                    AppColors.pink,
                    1,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _statCard(
                    'Duo Wins',
                    controller.user.value.duoWins,
                    Icons.sports_kabaddi_rounded,
                    AppColors.gold,
                    2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _activePlayersBar() {
    return Obx(() {
      final players = controller.activeUsers;
      return Pressable(
        onTap: controller.playDuo,
        child: GlassBox(
          radius: 20,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.green,
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(begin: 0.8, end: 1.35, duration: 800.ms),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ACTIVE IN GAMEPLAY (${max(players.length, 3)} ONLINE)',
                      style: AppText.body(
                        10.5,
                        color: AppColors.cyan,
                        weight: FontWeight.w700,
                        spacing: 1.1,
                      ),
                    ),
                    Text(
                      players.isEmpty
                          ? 'Tap to auto-match with active Wordsmiths!'
                          : '${players.take(3).map((p) => p.name.split(' ').first).join(', ')} ready for Duo!',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(11.5, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              if (players.isNotEmpty)
                SizedBox(
                  width: min(players.length, 3) * 26.0 + 10,
                  height: 34,
                  child: Stack(
                    children: [
                      for (var i = 0; i < min(players.length, 3); i++)
                        Positioned(
                          left: i * 22.0,
                          child: AnimatedGameAvatar(
                            avatarId: players[i].avatar,
                            size: 30,
                            showOnline: true,
                            isOnline: true,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    }).animate().fadeIn(delay: 550.ms);
  }

  Widget _statCard(String label, int value, IconData icon, Color color, int i) {
    return GlassBox(
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            Icon(icon, color: color, size: 22)
                .animate(
                  onPlay: (c) => c.repeat(reverse: true),
                  delay: (i * 180).ms,
                )
                .scaleXY(begin: 1, end: 1.14, duration: 1400.ms, curve: Curves.easeInOut),
            const SizedBox(height: 4),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value.toDouble()),
              duration: const Duration(milliseconds: 1100),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('${v.round()}', style: AppText.display(20)),
              ),
            ),
            Text(label, style: AppText.body(11, color: Colors.white60)),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: (620 + i * 100).ms, duration: 350.ms)
        .slideY(begin: 0.45, end: 0, delay: (620 + i * 100).ms, duration: 500.ms);
  }
}
