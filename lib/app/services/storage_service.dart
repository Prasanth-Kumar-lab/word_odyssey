import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

import '../models/puzzle_model.dart';
import '../models/user_model.dart';
import 'api_service.dart';

/// Dynamic cloud-synced state service powered by the Python FastAPI + MongoDB
/// backend using Bearer Token authentication.
///
/// Local storage (`GetStorage`) has been completely removed: all game progress
/// (level, coins, words, bonus, puzzle, found, revealed, profile) is dynamically
/// loaded from and persisted to MongoDB (`word_odyssey` database).
class StorageService extends GetxService {
  final ApiService _api = Get.find<ApiService>();

  final user = UserModel.empty().obs;
  final isLoggedIn = false.obs;

  int _level = 1;
  int _coins = 250;
  int _wordsTotal = 0;
  int _bonusTotal = 0;
  bool _haptics = true;
  bool _soundOn = true;
  bool _musicOn = true;
  Puzzle? _puzzle;
  List<String> _found = [];
  List<String> _revealed = [];
  List<String> _bonus = [];

  Timer? _syncDebounce;

  int get level => _level;
  set level(int v) {
    _level = v;
    user.value = user.value.copyWith(level: v);
    _scheduleCloudSync();
  }

  int get coins => _coins;
  set coins(int v) {
    _coins = v;
    user.value = user.value.copyWith(coins: v);
    _scheduleCloudSync();
  }

  int get wordsTotal => _wordsTotal;
  set wordsTotal(int v) {
    _wordsTotal = v;
    user.value = user.value.copyWith(wordsTotal: v);
    _scheduleCloudSync();
  }

  int get bonusTotal => _bonusTotal;
  set bonusTotal(int v) {
    _bonusTotal = v;
    user.value = user.value.copyWith(bonusTotal: v);
    _scheduleCloudSync();
  }

  bool get haptics => _haptics;
  set haptics(bool v) {
    _haptics = v;
    user.value = user.value.copyWith(haptics: v);
    _scheduleCloudSync();
  }

  bool get soundOn => _soundOn;
  set soundOn(bool v) {
    _soundOn = v;
    user.value = user.value.copyWith(soundOn: v);
    _scheduleCloudSync();
  }

  bool get musicOn => _musicOn;
  set musicOn(bool v) {
    _musicOn = v;
    user.value = user.value.copyWith(musicOn: v);
    _scheduleCloudSync();
  }

  Puzzle? get puzzle => _puzzle;
  List<String> get found => List.unmodifiable(_found);
  List<String> get revealed => List.unmodifiable(_revealed);
  List<String> get bonus => List.unmodifiable(_bonus);

  void savePuzzleState({
    required Puzzle puzzle,
    required Iterable<String> found,
    required Iterable<String> revealed,
    required Iterable<String> bonus,
  }) {
    _puzzle = puzzle;
    _found = found.toList();
    _revealed = revealed.toList();
    _bonus = bonus.toList();
    _scheduleCloudSync();
  }

  void _scheduleCloudSync() {
    if (!isLoggedIn.value) return;
    _syncDebounce?.cancel();
    _syncDebounce = Timer(const Duration(milliseconds: 280), () {
      unawaited(syncToCloud());
    });
  }

  Future<void> syncToCloud() async {
    if (!isLoggedIn.value) return;
    try {
      final res = await _api.saveSoloState(
        level: _level,
        coins: _coins,
        wordsTotal: _wordsTotal,
        bonusTotal: _bonusTotal,
        haptics: _haptics,
        soundOn: _soundOn,
        musicOn: _musicOn,
        puzzle: _puzzle,
        found: _found,
        revealed: _revealed,
        bonus: _bonus,
      );
      if (res['user'] is Map) {
        user.value = UserModel.fromJson(Map<String, dynamic>.from(res['user'] as Map));
      }
    } catch (_) {}
  }

  void applyServerPayload({
    required Map<String, dynamic> userJson,
    Map<String, dynamic>? soloStateJson,
  }) {
    final u = UserModel.fromJson(userJson);
    user.value = u;
    _level = u.level;
    _coins = u.coins;
    _wordsTotal = u.wordsTotal;
    _bonusTotal = u.bonusTotal;
    _haptics = u.haptics;
    _soundOn = u.soundOn;
    _musicOn = u.musicOn;

    if (soloStateJson != null) {
      _level = (soloStateJson['level'] as num?)?.toInt() ?? _level;
      final rawPuzzle = soloStateJson['puzzle'];
      if (rawPuzzle is Map) {
        try {
          _puzzle = Puzzle.fromJson(rawPuzzle);
        } catch (_) {}
      }
      _found = ((soloStateJson['found'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList();
      _revealed = ((soloStateJson['revealed'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList();
      _bonus = ((soloStateJson['bonus'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList();
    }
  }

  Future<File> _sessionFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/word_odyssey_bearer_session.json');
  }

  Future<void> persistSessionToken(String token, {String? apiBase}) async {
    _api.setBearerToken(token);
    isLoggedIn.value = true;
    try {
      final file = await _sessionFile();
      await file.writeAsString(
        jsonEncode({
          'token': token,
          'apiBase': apiBase ?? _api.customBaseUrl.value,
        }),
      );
    } catch (_) {}
  }

  Future<void> persistCustomBaseUrl(String url) async {
    _api.customBaseUrl.value = url.trim();
    try {
      final file = await _sessionFile();
      Map<String, dynamic> existing = {};
      if (await file.exists()) {
        existing = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      }
      existing['apiBase'] = _api.customBaseUrl.value;
      await file.writeAsString(jsonEncode(existing));
    } catch (_) {}
  }

  Future<bool> restoreSessionFromApi() async {
    try {
      final file = await _sessionFile();
      if (!await file.exists()) return false;
      final map = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final savedBase = (map['apiBase'] ?? '').toString().trim();
      if (savedBase.isNotEmpty) {
        _api.customBaseUrl.value = savedBase;
      }
      final token = (map['token'] ?? '').toString().trim();
      if (token.isEmpty) return false;

      _api.setBearerToken(token);
      final meRes = await _api.fetchMe();
      applyServerPayload(
        userJson: Map<String, dynamic>.from(meRes['user'] as Map),
        soloStateJson: meRes['soloState'] is Map
            ? Map<String, dynamic>.from(meRes['soloState'] as Map)
            : null,
      );
      isLoggedIn.value = true;
      return true;
    } catch (_) {
      await clearSession();
      return false;
    }
  }

  Future<void> refreshFromServer() async {
    if (!isLoggedIn.value) return;
    try {
      final meRes = await _api.fetchMe();
      applyServerPayload(
        userJson: Map<String, dynamic>.from(meRes['user'] as Map),
        soloStateJson: meRes['soloState'] is Map
            ? Map<String, dynamic>.from(meRes['soloState'] as Map)
            : null,
      );
    } catch (_) {}
  }

  Future<void> clearSession() async {
    _syncDebounce?.cancel();
    isLoggedIn.value = false;
    _api.setBearerToken(null);
    user.value = UserModel.empty();
    _puzzle = null;
    _found = [];
    _revealed = [];
    _bonus = [];
    try {
      final file = await _sessionFile();
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}
