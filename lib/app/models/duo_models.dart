import 'puzzle_model.dart';
import 'user_model.dart';

class DuoPlayerInfo {
  const DuoPlayerInfo({
    required this.id,
    required this.name,
    required this.avatar,
    required this.title,
    required this.level,
    required this.trophies,
    required this.isBot,
  });

  final String id;
  final String name;
  final String avatar;
  final String title;
  final int level;
  final int trophies;
  final bool isBot;

  GameAvatarSpec get avatarSpec => GameAvatarSpec.byId(avatar);

  factory DuoPlayerInfo.fromJson(Map<String, dynamic> m) => DuoPlayerInfo(
        id: (m['id'] ?? '').toString(),
        name: (m['name'] ?? 'Challenger').toString(),
        avatar: (m['avatar'] ?? 'cosmic_scribe').toString(),
        title: (m['title'] ?? 'Word Weaver').toString(),
        level: (m['level'] as num?)?.toInt() ?? 1,
        trophies: (m['trophies'] as num?)?.toInt() ?? 100,
        isBot: m['isBot'] as bool? ?? false,
      );
}

class DuoAction {
  const DuoAction({
    required this.type,
    required this.message,
    required this.at,
    this.userId,
    this.fromUserId,
    this.toUserId,
    this.word,
    this.points,
  });

  final String type;
  final String message;
  final int at;
  final String? userId;
  final String? fromUserId;
  final String? toUserId;
  final String? word;
  final int? points;

  factory DuoAction.fromJson(Map<String, dynamic> m) => DuoAction(
        type: (m['type'] ?? '').toString(),
        message: (m['message'] ?? '').toString(),
        at: (m['at'] as num?)?.toInt() ?? 0,
        userId: m['userId']?.toString(),
        fromUserId: m['fromUserId']?.toString(),
        toUserId: m['toUserId']?.toString(),
        word: m['word']?.toString(),
        points: (m['points'] as num?)?.toInt(),
      );
}

class DuoMatchModel {
  const DuoMatchModel({
    required this.id,
    required this.status,
    required this.playerIds,
    required this.players,
    required this.puzzle,
    required this.found,
    required this.wordOwners,
    required this.revealed,
    required this.bonus,
    required this.scores,
    required this.turnUserId,
    required this.turnNumber,
    required this.turnDurationSeconds,
    required this.turnStartedAtMs,
    required this.turnDeadlineMs,
    required this.remainingMs,
    this.lastAction,
    this.winnerId,
  });

  final String id;
  final String status;
  final List<String> playerIds;
  final Map<String, DuoPlayerInfo> players;
  final Puzzle puzzle;
  final List<String> found;
  final Map<String, String> wordOwners;
  final List<String> revealed;
  final List<String> bonus;
  final Map<String, int> scores;
  final String turnUserId;
  final int turnNumber;
  final int turnDurationSeconds;
  final int turnStartedAtMs;
  final int turnDeadlineMs;
  final int remainingMs;
  final DuoAction? lastAction;
  final String? winnerId;

  bool get isCompleted => status == 'completed';

  DuoPlayerInfo? playerOf(String uid) => players[uid];

  DuoPlayerInfo? opponentOf(String myUid) {
    for (final e in players.entries) {
      if (e.key != myUid) return e.value;
    }
    return players.values.isNotEmpty ? players.values.last : null;
  }

  int scoreOf(String uid) => scores[uid] ?? 0;

  factory DuoMatchModel.fromJson(Map<String, dynamic> m) {
    final rawPlayers = (m['players'] as Map?) ?? const {};
    final playersMap = <String, DuoPlayerInfo>{};
    for (final e in rawPlayers.entries) {
      if (e.value is Map) {
        playersMap[e.key.toString()] = DuoPlayerInfo.fromJson(
          Map<String, dynamic>.from(e.value as Map),
        );
      }
    }

    final rawScores = (m['scores'] as Map?) ?? const {};
    final scoresMap = <String, int>{
      for (final e in rawScores.entries)
        e.key.toString(): (e.value as num?)?.toInt() ?? 0,
    };

    final rawOwners = (m['wordOwners'] as Map?) ?? const {};
    final ownersMap = <String, String>{
      for (final e in rawOwners.entries)
        e.key.toString(): e.value.toString(),
    };

    return DuoMatchModel(
      id: (m['id'] ?? '').toString(),
      status: (m['status'] ?? 'active').toString(),
      playerIds: ((m['playerIds'] as List?) ?? const []).map((e) => e.toString()).toList(),
      players: playersMap,
      puzzle: Puzzle.fromJson((m['puzzle'] as Map?) ?? const {}),
      found: ((m['found'] as List?) ?? const []).map((e) => e.toString()).toList(),
      wordOwners: ownersMap,
      revealed: ((m['revealed'] as List?) ?? const []).map((e) => e.toString()).toList(),
      bonus: ((m['bonus'] as List?) ?? const []).map((e) => e.toString()).toList(),
      scores: scoresMap,
      turnUserId: (m['turnUserId'] ?? '').toString(),
      turnNumber: (m['turnNumber'] as num?)?.toInt() ?? 1,
      turnDurationSeconds: (m['turnDurationSeconds'] as num?)?.toInt() ?? 30,
      turnStartedAtMs: (m['turnStartedAtMs'] as num?)?.toInt() ?? 0,
      turnDeadlineMs: (m['turnDeadlineMs'] as num?)?.toInt() ?? 0,
      remainingMs: (m['remainingMs'] as num?)?.toInt() ?? 30000,
      lastAction: m['lastAction'] is Map
          ? DuoAction.fromJson(Map<String, dynamic>.from(m['lastAction'] as Map))
          : null,
      winnerId: m['winnerId']?.toString(),
    );
  }
}

class ChatMessageModel {
  const ChatMessageModel({
    required this.id,
    required this.matchId,
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
    required this.text,
    required this.isQuick,
    required this.createdAt,
  });

  final String id;
  final String matchId;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final String text;
  final bool isQuick;
  final int createdAt;

  factory ChatMessageModel.fromJson(Map<String, dynamic> m) => ChatMessageModel(
        id: (m['id'] ?? '').toString(),
        matchId: (m['matchId'] ?? '').toString(),
        senderId: (m['senderId'] ?? '').toString(),
        senderName: (m['senderName'] ?? 'Player').toString(),
        senderAvatar: (m['senderAvatar'] ?? 'word_mage').toString(),
        text: (m['text'] ?? '').toString(),
        isQuick: m['isQuick'] as bool? ?? false,
        createdAt: (m['createdAt'] as num?)?.toInt() ?? 0,
      );
}
