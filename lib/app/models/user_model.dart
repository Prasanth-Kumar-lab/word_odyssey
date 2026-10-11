import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class GameAvatarSpec {
  const GameAvatarSpec({
    required this.id,
    required this.name,
    required this.role,
    required this.icon,
    required this.colors,
    required this.accent,
  });

  final String id;
  final String name;
  final String role;
  final IconData icon;
  final List<Color> colors;
  final Color accent;

  static const List<GameAvatarSpec> catalog = [
    GameAvatarSpec(
      id: 'word_mage',
      name: 'Arcane Wordmage',
      role: 'Spellcaster of Syllables',
      icon: Icons.auto_fix_high_rounded,
      colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
      accent: AppColors.gold,
    ),
    GameAvatarSpec(
      id: 'lexicon_knight',
      name: 'Lexicon Knight',
      role: 'Guardian of the Grid',
      icon: Icons.shield_rounded,
      colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
      accent: AppColors.cyan,
    ),
    GameAvatarSpec(
      id: 'cosmic_scribe',
      name: 'Cosmic Scribe',
      role: 'Weaver of Starlight',
      icon: Icons.auto_awesome_rounded,
      colors: [Color(0xFF6366F1), Color(0xFF14B8A6)],
      accent: AppColors.gold,
    ),
    GameAvatarSpec(
      id: 'phoenix_bard',
      name: 'Phoenix Bard',
      role: 'Blazing Verse Master',
      icon: Icons.local_fire_department_rounded,
      colors: [Color(0xFFFF5E8A), Color(0xFFFF8A3D)],
      accent: AppColors.gold,
    ),
    GameAvatarSpec(
      id: 'rune_scholar',
      name: 'Rune Scholar',
      role: 'Keeper of Ancient Tomes',
      icon: Icons.menu_book_rounded,
      colors: [Color(0xFF10B981), Color(0xFF059669)],
      accent: AppColors.green,
    ),
    GameAvatarSpec(
      id: 'cyber_poet',
      name: 'Cyber Wordsmith',
      role: 'Neon Grid Hacker',
      icon: Icons.bolt_rounded,
      colors: [Color(0xFF22D3EE), Color(0xFF8B5CF6)],
      accent: AppColors.cyan,
    ),
    GameAvatarSpec(
      id: 'dragon_wordsmith',
      name: 'Dragon Sovereign',
      role: 'Emperor of Anagrams',
      icon: Icons.whatshot_rounded,
      colors: [Color(0xFFEF4444), Color(0xFFF59E0B)],
      accent: AppColors.gold,
    ),
    GameAvatarSpec(
      id: 'crowned_oracle',
      name: 'Crowned Oracle',
      role: 'Grand Odyssey Champion',
      icon: Icons.workspace_premium_rounded,
      colors: [Color(0xFFF59E0B), Color(0xFF7C3AED)],
      accent: AppColors.gold,
    ),
  ];

  static GameAvatarSpec byId(String? id) {
    for (final item in catalog) {
      if (item.id == id) return item;
    }
    return catalog.first;
  }
}

class UserModel {
  const UserModel({
    required this.id,
    required this.phone,
    required this.name,
    required this.avatar,
    required this.title,
    required this.bio,
    required this.level,
    required this.coins,
    required this.wordsTotal,
    required this.bonusTotal,
    required this.duoMatches,
    required this.duoWins,
    required this.winRate,
    required this.winStreak,
    required this.bestStreak,
    required this.trophies,
    required this.haptics,
    required this.soundOn,
    required this.musicOn,
    required this.isOnline,
    required this.inGameplay,
    this.isSearchingDuo = false,
  });

  final String id;
  final String phone;
  final String name;
  final String avatar;
  final String title;
  final String bio;
  final int level;
  final int coins;
  final int wordsTotal;
  final int bonusTotal;
  final int duoMatches;
  final int duoWins;
  final int winRate;
  final int winStreak;
  final int bestStreak;
  final int trophies;
  final bool haptics;
  final bool soundOn;
  final bool musicOn;
  final bool isOnline;
  final bool inGameplay;
  final bool isSearchingDuo;

  GameAvatarSpec get avatarSpec => GameAvatarSpec.byId(avatar);

  factory UserModel.empty() => const UserModel(
        id: '',
        phone: '',
        name: 'Word Explorer',
        avatar: 'word_mage',
        title: 'Novice Scribe',
        bio: 'Seeking hidden words across the cosmos!',
        level: 1,
        coins: 250,
        wordsTotal: 0,
        bonusTotal: 0,
        duoMatches: 0,
        duoWins: 0,
        winRate: 0,
        winStreak: 0,
        bestStreak: 0,
        trophies: 100,
        haptics: true,
        soundOn: true,
        musicOn: true,
        isOnline: true,
        inGameplay: false,
      );

  factory UserModel.fromJson(Map<String, dynamic> m) => UserModel(
        id: (m['id'] ?? '').toString(),
        phone: (m['phone'] ?? '').toString(),
        name: (m['name'] ?? 'Word Explorer').toString(),
        avatar: (m['avatar'] ?? 'word_mage').toString(),
        title: (m['title'] ?? 'Novice Scribe').toString(),
        bio: (m['bio'] ?? 'Ready for a Word Odyssey duel!').toString(),
        level: (m['level'] as num?)?.toInt() ?? 1,
        coins: (m['coins'] as num?)?.toInt() ?? 250,
        wordsTotal: (m['wordsTotal'] as num?)?.toInt() ?? 0,
        bonusTotal: (m['bonusTotal'] as num?)?.toInt() ?? 0,
        duoMatches: (m['duoMatches'] as num?)?.toInt() ?? 0,
        duoWins: (m['duoWins'] as num?)?.toInt() ?? 0,
        winRate: (m['winRate'] as num?)?.toInt() ?? 0,
        winStreak: (m['winStreak'] as num?)?.toInt() ?? 0,
        bestStreak: (m['bestStreak'] as num?)?.toInt() ?? 0,
        trophies: (m['trophies'] as num?)?.toInt() ?? 100,
        haptics: m['haptics'] as bool? ?? true,
        soundOn: m['soundOn'] as bool? ?? true,
        musicOn: m['musicOn'] as bool? ?? true,
        isOnline: m['isOnline'] as bool? ?? true,
        inGameplay: m['inGameplay'] as bool? ?? false,
        isSearchingDuo: m['isSearchingDuo'] as bool? ?? false,
      );

  UserModel copyWith({
    String? name,
    String? avatar,
    String? title,
    String? bio,
    int? level,
    int? coins,
    int? wordsTotal,
    int? bonusTotal,
    int? duoMatches,
    int? duoWins,
    int? winRate,
    int? winStreak,
    int? bestStreak,
    int? trophies,
    bool? haptics,
    bool? soundOn,
    bool? musicOn,
    bool? isOnline,
    bool? inGameplay,
  }) {
    return UserModel(
      id: id,
      phone: phone,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      title: title ?? this.title,
      bio: bio ?? this.bio,
      level: level ?? this.level,
      coins: coins ?? this.coins,
      wordsTotal: wordsTotal ?? this.wordsTotal,
      bonusTotal: bonusTotal ?? this.bonusTotal,
      duoMatches: duoMatches ?? this.duoMatches,
      duoWins: duoWins ?? this.duoWins,
      winRate: winRate ?? this.winRate,
      winStreak: winStreak ?? this.winStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      trophies: trophies ?? this.trophies,
      haptics: haptics ?? this.haptics,
      soundOn: soundOn ?? this.soundOn,
      musicOn: musicOn ?? this.musicOn,
      isOnline: isOnline ?? this.isOnline,
      inGameplay: inGameplay ?? this.inGameplay,
      isSearchingDuo: isSearchingDuo,
    );
  }
}
