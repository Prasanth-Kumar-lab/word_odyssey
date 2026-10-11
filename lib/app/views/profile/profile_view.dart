import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import '../../controllers/profile_controller.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../widgets/animated_background.dart';
import '../widgets/common_widgets.dart';
import '../widgets/game_avatar.dart';
import '../widgets/premium_motion.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

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
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 14 : 22,
                      vertical: 12,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 680),
                        child: Column(
                          children: [
                            _heroBanner(compact),
                            const SizedBox(height: 16),
                            _tabSelector(compact),
                            const SizedBox(height: 16),
                            Obx(() {
                              final tab = controller.activeTab.value;
                              if (tab == 1) return _leaderboardSection();
                              if (tab == 2) return _historySection();
                              return _overviewSection(compact);
                            }),
                          ],
                        ),
                      ),
                    ),
                  ),
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
      padding: EdgeInsets.fromLTRB(compact ? 12 : 18, 8, compact ? 12 : 18, 4),
      child: Row(
        children: [
          GlassIconButton(
            icon: Icons.arrow_back_rounded,
            size: compact ? 42 : 46,
            onTap: Get.back,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'CHAMPION PROFILE',
              style: AppText.display(compact ? 18 : 21, spacing: 1.5),
            ),
          ),
          Obx(() => CoinChip(coins: controller.user.value.coins)),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: -0.4, end: 0);
  }

  Widget _heroBanner(bool compact) {
    return Obx(() {
      final u = controller.user.value;
      final avatarId = controller.selectedAvatar.value;
      final spec = GameAvatarSpec.byId(avatarId);

      return GlassBox(
        radius: 28,
        padding: EdgeInsets.all(compact ? 16 : 22),
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: compact ? 88 : 104,
                  height: compact ? 88 : 104,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      OrbitHalo(size: compact ? 88 : 104),
                      AnimatedGameAvatar(
                        avatarId: avatarId,
                        size: compact ? 68 : 78,
                        showOnline: true,
                        isOnline: true,
                        isTurnActive: true,
                        badgeText: 'LVL ${u.level}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppGradients.gold,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          u.title.toUpperCase(),
                          style: AppText.display(10.5, color: AppColors.ink, spacing: 1),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        u.name,
                        style: AppText.display(compact ? 20 : 24),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${spec.name} • ${spec.role}',
                        style: AppText.body(12, color: AppColors.cyan, weight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.phone_iphone_rounded, color: Colors.white54, size: 14),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              u.phone.isEmpty ? 'Verified Player' : u.phone,
                              style: AppText.body(11.5, color: Colors.white60),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _miniStatPill(
                    icon: Icons.emoji_events_rounded,
                    label: 'Trophies',
                    value: '${u.trophies}',
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _miniStatPill(
                    icon: Icons.sports_kabaddi_rounded,
                    label: 'Duo Wins',
                    value: '${u.duoWins}/${u.duoMatches}',
                    color: AppColors.pink,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _miniStatPill(
                    icon: Icons.local_fire_department_rounded,
                    label: 'Win Rate',
                    value: '${u.winRate}%',
                    color: AppColors.cyan,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }).animate().fadeIn(duration: 420.ms).scaleXY(begin: 0.94, end: 1);
  }

  Widget _miniStatPill({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(value, style: AppText.display(16)),
          Text(label, style: AppText.body(10.5, color: Colors.white60)),
        ],
      ),
    );
  }

  Widget _tabSelector(bool compact) {
    final tabs = [
      (0, Icons.auto_awesome_rounded, 'Avatar & Stats'),
      (1, Icons.leaderboard_rounded, 'Leaderboard'),
      (2, Icons.history_rounded, 'Duo Battles'),
    ];
    return Obx(() {
      final active = controller.activeTab.value;
      return GlassBox(
        radius: 22,
        padding: const EdgeInsets.all(5),
        child: Row(
          children: [
            for (final t in tabs)
              Expanded(
                child: Pressable(
                  onTap: () => controller.activeTab.value = t.$1,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      gradient: active == t.$1 ? AppGradients.gold : null,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          t.$2,
                          size: 16,
                          color: active == t.$1 ? AppColors.ink : Colors.white70,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            t.$3,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.body(
                              compact ? 11.5 : 12.5,
                              color: active == t.$1 ? AppColors.ink : Colors.white70,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _overviewSection(bool compact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassBox(
          radius: 26,
          padding: EdgeInsets.all(compact ? 16 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SELECT GAME AVATAR CLASS',
                style: AppText.body(
                  11.5,
                  color: AppColors.gold,
                  weight: FontWeight.w700,
                  spacing: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Obx(() {
                final selected = controller.selectedAvatar.value;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: compact ? 2 : 4,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: compact ? 1.25 : 0.92,
                  ),
                  itemCount: GameAvatarSpec.catalog.length,
                  itemBuilder: (_, i) {
                    final spec = GameAvatarSpec.catalog[i];
                    final isPicked = spec.id == selected;
                    return Pressable(
                      onTap: () => controller.pickAvatar(spec.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isPicked
                              ? spec.colors.first.withValues(alpha: 0.28)
                              : Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isPicked ? AppColors.gold : Colors.white12,
                            width: isPicked ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedGameAvatar(
                              avatarId: spec.id,
                              size: 46,
                              isTurnActive: isPicked,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              spec.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.display(12.5),
                            ),
                            Text(
                              spec.role,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.body(9.5, color: Colors.white60),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
              const SizedBox(height: 18),
              Text(
                'CHAMPION DISPLAY NAME',
                style: AppText.body(11, color: Colors.white70, weight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24),
                ),
                child: TextField(
                  controller: controller.nameController,
                  style: AppText.body(15, weight: FontWeight.w600),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    icon: Icon(Icons.badge_rounded, color: AppColors.gold),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'BATTLE MOTTO / BIO',
                style: AppText.body(11, color: Colors.white70, weight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24),
                ),
                child: TextField(
                  controller: controller.bioController,
                  style: AppText.body(14),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    icon: Icon(Icons.format_quote_rounded, color: AppColors.cyan),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Obx(
                () => GradientButton(
                  label: controller.isSaving.value ? 'SAVING...' : 'SAVE PROFILE',
                  icon: Icons.cloud_upload_rounded,
                  height: 52,
                  expand: true,
                  onTap: controller.saveProfile,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlassBox(
          radius: 24,
          padding: const EdgeInsets.all(18),
          child: Obx(() {
            final u = controller.user.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GAMEPLAY AUDIO & CONTROLS',
                  style: AppText.body(
                    11.5,
                    color: AppColors.gold,
                    weight: FontWeight.w700,
                    spacing: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                _settingToggleRow(
                  icon: Icons.volume_up_rounded,
                  title: 'Gameplay Sound Effects',
                  subtitle: 'Musical chimes, word fanfare & 30s countdown audio',
                  value: u.soundOn,
                  onTap: controller.toggleSound,
                ),
                const Divider(color: Colors.white12, height: 18),
                _settingToggleRow(
                  icon: Icons.vibration_rounded,
                  title: 'Haptic Feedback',
                  subtitle: 'Tactile vibrations on letter wheel & word completion',
                  value: u.haptics,
                  onTap: controller.toggleHaptics,
                ),
                const SizedBox(height: 14),
                Pressable(
                  onTap: controller.logout,
                  child: Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: AppGradients.danger,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text('SIGN OUT', style: AppText.display(15, spacing: 1.2)),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _settingToggleRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required VoidCallback onTap,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.cyan, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.body(14, weight: FontWeight.w600)),
              Text(subtitle, style: AppText.body(11, color: Colors.white60)),
            ],
          ),
        ),
        Switch(
          value: value,
          activeThumbColor: AppColors.gold,
          onChanged: (_) => onTap(),
        ),
      ],
    );
  }

  Widget _leaderboardSection() {
    return Obx(() {
      final list = controller.leaderboard;
      if (list.isEmpty) {
        return GlassBox(
          radius: 24,
          padding: const EdgeInsets.all(28),
          child: Center(
            child: Text('Loading Hall of Fame...', style: AppText.body(14)),
          ),
        );
      }
      return GlassBox(
        radius: 26,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (final (i, player) in list.indexed)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: player.id == controller.user.value.id
                      ? AppColors.gold.withValues(alpha: 0.16)
                      : Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: i == 0
                        ? AppColors.gold
                        : (player.id == controller.user.value.id
                            ? AppColors.cyan
                            : Colors.white12),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 30,
                      child: Text(
                        '#${i + 1}',
                        style: AppText.display(
                          16,
                          color: i == 0
                              ? AppColors.gold
                              : (i == 1
                                  ? AppColors.cyan
                                  : (i == 2 ? AppColors.orange : Colors.white70)),
                        ),
                      ),
                    ),
                    AnimatedGameAvatar(
                      avatarId: player.avatar,
                      size: 42,
                      showOnline: true,
                      isOnline: player.isOnline,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            player.name,
                            style: AppText.display(15),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${player.title} • Level ${player.level}',
                            style: AppText.body(11, color: Colors.white60),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.emoji_events_rounded,
                          color: AppColors.gold,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${player.trophies}',
                          style: AppText.display(16, color: AppColors.gold),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: (i * 40).ms).slideX(begin: 0.1, end: 0),
          ],
        ),
      );
    });
  }

  Widget _historySection() {
    return Obx(() {
      final matches = controller.duoHistory;
      final myUid = controller.user.value.id;
      if (matches.isEmpty) {
        return GlassBox(
          radius: 24,
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Icon(Icons.sports_kabaddi_rounded, color: AppColors.gold, size: 42),
              const SizedBox(height: 10),
              Text('No Duo Matches Yet', style: AppText.display(18)),
              const SizedBox(height: 4),
              Text(
                'Jump into Duo Arena from the Home screen to battle active players with a 30s turn clock!',
                textAlign: TextAlign.center,
                style: AppText.body(13, color: Colors.white60),
              ),
            ],
          ),
        );
      }
      return GlassBox(
        radius: 26,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (final (i, m) in matches.indexed)
              Builder(
                builder: (_) {
                  final opp = m.opponentOf(myUid);
                  final myScore = m.scoreOf(myUid);
                  final oppScore = opp != null ? m.scoreOf(opp.id) : 0;
                  final won = m.winnerId == myUid;
                  final tie = m.winnerId == 'tie';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: won
                            ? AppColors.green.withValues(alpha: 0.5)
                            : Colors.white12,
                      ),
                    ),
                    child: Row(
                      children: [
                        AnimatedGameAvatar(
                          avatarId: opp?.avatar ?? 'cosmic_scribe',
                          size: 44,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'vs ${opp?.name ?? "Opponent"}',
                                style: AppText.display(15),
                              ),
                              Text(
                                'Score: $myScore - $oppScore  •  ${m.found.length} words solved',
                                style: AppText.body(11.5, color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            gradient: won
                                ? AppGradients.success
                                : (tie ? AppGradients.cool : AppGradients.danger),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            won ? 'VICTORY' : (tie ? 'DRAW' : 'DEFEAT'),
                            style: AppText.display(11, spacing: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: (i * 50).ms);
                },
              ),
          ],
        ),
      );
    });
  }
}
