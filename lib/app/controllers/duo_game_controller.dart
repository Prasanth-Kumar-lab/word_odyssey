import 'dart:async';
import 'dart:math';

import 'package:get/get.dart';

import '../models/duo_models.dart';
import '../models/puzzle_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/call_service.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../utils/haptics.dart';
import 'game_controller.dart' show FeedbackType, WheelLetter, WordFeedback;

class DuoGameController extends GetxController {
  final ApiService _api = Get.find<ApiService>();
  final StorageService _storage = Get.find<StorageService>();
  final SoundService _sound = Get.find<SoundService>();
  final _rnd = Random();

  final isSearching = true.obs;
  final searchStatusText = 'Scanning active players in Word Odyssey...'.obs;
  final searchElapsedSec = 0.obs;
  final activeLobbyPlayers = <UserModel>[].obs;

  final match = Rxn<DuoMatchModel>();
  final puzzle = Rxn<Puzzle>();
  final wheel = <WheelLetter>[].obs;
  final current = ''.obs;
  final feedback = Rxn<WordFeedback>();
  final remainingSeconds = 30.0.obs;
  final actionBanner = ''.obs;

  final messages = <ChatMessageModel>[].obs;
  final unreadChat = 0.obs;
  final isChatSheetOpen = false.obs;
  final latestChatToast = Rxn<ChatMessageModel>();

  DuoCallController? callController;

  Timer? _searchTimer;
  Timer? _countdownTimer;
  Timer? _pollTimer;
  StreamSubscription<Map<String, dynamic>>? _wsSub;
  int _feedbackId = 0;
  int _lastTickedSecond = -1;
  bool _passingTurn = false;
  String? _loadedPuzzleId;

  String get myUid => _storage.user.value.id;
  bool get isMyTurn =>
      match.value != null &&
      !match.value!.isCompleted &&
      match.value!.turnUserId == myUid;

  DuoPlayerInfo? get meInfo => match.value?.playerOf(myUid);
  DuoPlayerInfo? get opponentInfo => match.value?.opponentOf(myUid);

  int get myScore => match.value?.scoreOf(myUid) ?? 0;
  int get opponentScore =>
      opponentInfo != null ? (match.value?.scoreOf(opponentInfo!.id) ?? 0) : 0;

  @override
  void onInit() {
    super.onInit();
    _wsSub = _api.wsEvents.listen(_onWsEvent);
    startAutoMatch();
  }

  Future<void> startAutoMatch({bool instant = false}) async {
    isSearching.value = true;
    searchElapsedSec.value = 0;
    searchStatusText.value = 'Searching active players in gameplay...';
    match.value = null;

    _searchTimer?.cancel();
    _countdownTimer?.cancel();
    _pollTimer?.cancel();

    await _attemptMatch(instant: instant);
    if (!isSearching.value) return;

    _searchTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      searchElapsedSec.value++;
      if (searchElapsedSec.value == 2) {
        searchStatusText.value = 'Matching skill rank & active lobby...';
      } else if (searchElapsedSec.value == 4) {
        searchStatusText.value = 'Locking onto active Wordsmith opponent...';
      }
      // Every 2 seconds poll auto-match; after 4 seconds allow instant active challenger match
      if (searchElapsedSec.value % 2 == 0) {
        await _attemptMatch(instant: searchElapsedSec.value >= 4);
      }
    });
  }

  Future<void> _attemptMatch({bool instant = false}) async {
    try {
      final res = await _api.autoMatch(instantBotFallback: instant);
      final rawUsers = (res['activeUsers'] as List?) ?? const [];
      if (rawUsers.isNotEmpty) {
        activeLobbyPlayers.assignAll(
          rawUsers.map((e) => UserModel.fromJson(Map<String, dynamic>.from(e as Map))),
        );
      }
      if (res['status'] == 'matched' && res['match'] is Map) {
        final m = DuoMatchModel.fromJson(Map<String, dynamic>.from(res['match'] as Map));
        _onMatchEstablished(m);
      }
    } catch (_) {}
  }

  void _onMatchEstablished(DuoMatchModel m) {
    if (!isSearching.value && match.value?.id == m.id) return;
    _searchTimer?.cancel();
    isSearching.value = false;

    _applyMatchModel(m, initial: true);
    _api.joinMatchChannel(m.id);

    final opp = m.opponentOf(myUid);
    callController?.onClose();
    callController = DuoCallController(
      matchId: m.id,
      myUserId: myUid,
      isOpponentBot: opp?.isBot ?? false,
    )..onInit();

    _loadInitialChat(m.id);
    _startTurnCountdownLoop();
    _startMatchSyncPoll(m.id);

    Haptics.success();
    _sound.playVictory();
  }

  Future<void> _loadInitialChat(String matchId) async {
    try {
      final list = await _api.fetchMatchChat(matchId);
      messages.assignAll(list);
    } catch (_) {}
  }

  void _applyMatchModel(DuoMatchModel m, {bool initial = false}) {
    final prevTurn = match.value?.turnUserId;
    final prevStatus = match.value?.status;
    match.value = m;

    if (_loadedPuzzleId != m.puzzle.id) {
      _loadedPuzzleId = m.puzzle.id;
      puzzle.value = m.puzzle;
      wheel.assignAll([
        for (var i = 0; i < m.puzzle.letters.length; i++)
          WheelLetter(i, m.puzzle.letters[i]),
      ]);
    }

    // Sync local 30-second countdown from server's remainingMs
    remainingSeconds.value = (m.remainingMs / 1000.0).clamp(0.0, 30.0);

    if (m.lastAction != null && m.lastAction!.message.isNotEmpty) {
      actionBanner.value = m.lastAction!.message;
    }

    if (!initial && prevTurn != null && prevTurn != m.turnUserId && !m.isCompleted) {
      _lastTickedSecond = -1;
      Haptics.light();
      _sound.playTurnSwitch();
    }

    if (!initial && prevStatus != 'completed' && m.isCompleted) {
      Haptics.success();
      _sound.playVictory();
      _storage.refreshFromServer();
    }
  }

  void _startTurnCountdownLoop() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final m = match.value;
      if (m == null || m.isCompleted) return;

      final nextVal = (remainingSeconds.value - 0.1).clamp(0.0, 30.0);
      remainingSeconds.value = nextVal;

      final wholeSec = nextVal.ceil();
      if (wholeSec <= 5 && wholeSec >= 1 && wholeSec != _lastTickedSecond) {
        _lastTickedSecond = wholeSec;
        _sound.playTimerTick();
        if (isMyTurn) Haptics.tick();
      }

      // When 30s timer hits 0, automatically pass turn to opponent!
      if (nextVal <= 0.0 && !_passingTurn) {
        _passingTurn = true;
        _triggerTimeoutPass(m.id);
      }
    });
  }

  Future<void> _triggerTimeoutPass(String matchId) async {
    try {
      final updated = await _api.passDuoTurn(matchId);
      _applyMatchModel(updated);
    } catch (_) {
    } finally {
      Future.delayed(const Duration(milliseconds: 600), () {
        _passingTurn = false;
      });
    }
  }

  void _startMatchSyncPoll(String matchId) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) async {
      final m = match.value;
      if (m == null || m.isCompleted) return;
      try {
        final latest = await _api.fetchDuoMatch(matchId);
        _applyMatchModel(latest);
        final chatList = await _api.fetchMatchChat(matchId);
        if (chatList.length > messages.length) {
          final newest = chatList.last;
          messages.assignAll(chatList);
          if (newest.senderId != myUid) {
            _sound.playChatPop();
            if (!isChatSheetOpen.value) {
              unreadChat.value++;
              latestChatToast.value = newest;
            }
          }
        }
      } catch (_) {}
    });
  }

  void _onWsEvent(Map<String, dynamic> event) {
    final type = event['t']?.toString();
    if (type == 'duo_matched' && event['match'] is Map) {
      final m = DuoMatchModel.fromJson(Map<String, dynamic>.from(event['match'] as Map));
      _onMatchEstablished(m);
    } else if (type == 'match_update' && event['match'] is Map) {
      final m = DuoMatchModel.fromJson(Map<String, dynamic>.from(event['match'] as Map));
      if (match.value?.id == m.id) {
        _applyMatchModel(m);
      }
    } else if (type == 'chat_message' && event['message'] is Map) {
      final msg = ChatMessageModel.fromJson(
        Map<String, dynamic>.from(event['message'] as Map),
      );
      if (msg.matchId == match.value?.id && !messages.any((e) => e.id == msg.id)) {
        messages.add(msg);
        if (msg.senderId != myUid) {
          _sound.playChatPop();
          if (!isChatSheetOpen.value) {
            unreadChat.value++;
            latestChatToast.value = msg;
          }
        }
      }
    }
  }

  void startSelection() => feedback.value = null;

  void onLetterSelected(int count) => _sound.playLetterTap(count - 1);

  void _emit(FeedbackType type, [String word = '']) {
    feedback.value = WordFeedback(type, word, ++_feedbackId);
  }

  Future<void> submit(String w) async {
    current.value = '';
    final m = match.value;
    if (m == null || m.isCompleted || w.isEmpty) return;

    if (!isMyTurn) {
      actionBanner.value = "Wait for your opponent's 30s turn!";
      _emit(FeedbackType.wrong, w);
      Haptics.error();
      _sound.playWrongWord();
      return;
    }

    if (w.length < 3) {
      if (w.length == 2) {
        _emit(FeedbackType.tooShort, w);
        _sound.playWrongWord();
      }
      return;
    }

    try {
      final res = await _api.submitDuoMove(m.id, w);
      final outcome = (res['outcome'] ?? '').toString();
      if (res['match'] is Map) {
        _applyMatchModel(
          DuoMatchModel.fromJson(Map<String, dynamic>.from(res['match'] as Map)),
        );
      }

      switch (outcome) {
        case 'correct':
          _emit(FeedbackType.correct, w);
          Haptics.success();
          _sound.playWordCorrect();
          break;
        case 'bonus':
          _emit(FeedbackType.bonus, w);
          Haptics.success();
          _sound.playBonusWord();
          break;
        case 'repeat':
          _emit(FeedbackType.repeat, w);
          Haptics.light();
          _sound.playWrongWord();
          break;
        case 'bonus_repeat':
          _emit(FeedbackType.bonusRepeat, w);
          Haptics.light();
          _sound.playWrongWord();
          break;
        default:
          _emit(FeedbackType.wrong, w);
          Haptics.error();
          _sound.playWrongWord();
      }
    } catch (_) {
      _emit(FeedbackType.wrong, w);
      Haptics.error();
    }
  }

  void shuffle() {
    if (wheel.length < 2) return;
    final before = wheel.map((l) => l.id).join(',');
    final l = List<WheelLetter>.of(wheel);
    do {
      l.shuffle(_rnd);
    } while (l.map((e) => e.id).join(',') == before);
    wheel.assignAll(l);
    Haptics.light();
    _sound.playLetterTap(1);
  }

  Future<void> passTurnManually() async {
    final m = match.value;
    if (m == null || m.isCompleted || !isMyTurn) return;
    Haptics.light();
    _sound.playTurnSwitch();
    try {
      final updated = await _api.passDuoTurn(m.id);
      _applyMatchModel(updated);
    } catch (_) {}
  }

  Future<void> sendChatMessage(String text, {bool isQuick = false}) async {
    final m = match.value;
    if (m == null || text.trim().isEmpty) return;
    try {
      final sent = await _api.sendMatchChat(m.id, text.trim(), isQuick: isQuick);
      if (!messages.any((e) => e.id == sent.id)) {
        messages.add(sent);
      }
      Haptics.light();
      _sound.playChatPop();
    } catch (_) {}
  }

  void markChatRead() {
    unreadChat.value = 0;
    latestChatToast.value = null;
  }

  Future<void> leaveOrForfeit() async {
    _searchTimer?.cancel();
    _countdownTimer?.cancel();
    _pollTimer?.cancel();
    if (isSearching.value) {
      await _api.cancelQueue();
    } else if (match.value != null && !match.value!.isCompleted) {
      try {
        await _api.forfeitDuoMatch(match.value!.id);
      } catch (_) {}
    }
    Get.back();
  }

  @override
  void onClose() {
    _searchTimer?.cancel();
    _countdownTimer?.cancel();
    _pollTimer?.cancel();
    _wsSub?.cancel();
    if (match.value != null) {
      _api.leaveMatchChannel(match.value!.id);
    } else {
      _api.cancelQueue();
    }
    callController?.onClose();
    super.onClose();
  }
}
