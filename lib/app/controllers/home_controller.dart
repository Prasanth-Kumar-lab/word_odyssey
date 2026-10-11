import 'dart:async';

import 'package:get/get.dart';

import '../models/user_model.dart';
import '../routes/app_routes.dart';
import '../services/api_service.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../utils/haptics.dart';

class HomeController extends GetxController {
  final StorageService _storage = Get.find<StorageService>();
  final ApiService _api = Get.find<ApiService>();
  final SoundService _sound = Get.find<SoundService>();

  final level = 1.obs;
  final coins = 250.obs;
  final wordsTotal = 0.obs;
  final bonusTotal = 0.obs;
  final haptics = true.obs;
  final soundOn = true.obs;
  final activeUsers = <UserModel>[].obs;

  Timer? _presenceTimer;

  Rx<UserModel> get user => _storage.user;

  @override
  void onInit() {
    super.onInit();
    refreshStats();
    _syncPresence();
    _presenceTimer = Timer.periodic(const Duration(seconds: 9), (_) => _syncPresence());
  }

  Future<void> _syncPresence() async {
    try {
      final list = await _api.heartbeat(inGameplay: false, mode: 'lobby');
      activeUsers.assignAll(list);
    } catch (_) {}
  }

  Future<void> refreshStats() async {
    await _storage.refreshFromServer();
    level.value = _storage.level;
    coins.value = _storage.coins;
    wordsTotal.value = _storage.wordsTotal;
    bonusTotal.value = _storage.bonusTotal;
    haptics.value = _storage.haptics;
    soundOn.value = _storage.soundOn;
  }

  Future<void> playSolo() async {
    Haptics.success();
    _sound.playWordCorrect();
    await Get.toNamed(AppRoutes.game);
    await refreshStats();
    unawaited(_syncPresence());
  }

  Future<void> playDuo() async {
    Haptics.success();
    _sound.playBonusWord();
    await Get.toNamed(AppRoutes.duoGame);
    await refreshStats();
    unawaited(_syncPresence());
  }

  Future<void> openProfile() async {
    Haptics.light();
    _sound.playLetterTap(2);
    await Get.toNamed(AppRoutes.profile);
    await refreshStats();
  }

  void toggleHaptics() {
    haptics.toggle();
    _storage.haptics = haptics.value;
    Haptics.light();
  }

  void toggleSound() {
    soundOn.toggle();
    _storage.soundOn = soundOn.value;
    if (soundOn.value) _sound.playLetterTap(4);
  }

  @override
  void onClose() {
    _presenceTimer?.cancel();
    super.onClose();
  }
}
