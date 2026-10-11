import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/duo_models.dart';
import '../models/user_model.dart';
import '../routes/app_routes.dart';
import '../services/api_service.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../utils/haptics.dart';

class ProfileController extends GetxController {
  final ApiService _api = Get.find<ApiService>();
  final StorageService _storage = Get.find<StorageService>();
  final SoundService _sound = Get.find<SoundService>();

  late final TextEditingController nameController;
  late final TextEditingController bioController;

  final selectedAvatar = 'word_mage'.obs;
  final activeTab = 0.obs; // 0: Overview, 1: Leaderboard, 2: Duo History
  final isSaving = false.obs;
  final isLoadingLists = false.obs;
  final leaderboard = <UserModel>[].obs;
  final duoHistory = <DuoMatchModel>[].obs;

  Rx<UserModel> get user => _storage.user;

  @override
  void onInit() {
    super.onInit();
    final u = _storage.user.value;
    nameController = TextEditingController(text: u.name);
    bioController = TextEditingController(text: u.bio);
    selectedAvatar.value = u.avatar;
    loadCommunityData();
  }

  Future<void> loadCommunityData() async {
    isLoadingLists.value = true;
    try {
      await _storage.refreshFromServer();
      final u = _storage.user.value;
      nameController.text = u.name;
      bioController.text = u.bio;
      selectedAvatar.value = u.avatar;

      final results = await Future.wait([
        _api.fetchLeaderboard(),
        _api.fetchDuoHistory(),
      ]);
      leaderboard.assignAll(results[0] as List<UserModel>);
      duoHistory.assignAll(results[1] as List<DuoMatchModel>);
    } catch (_) {}
    isLoadingLists.value = false;
  }

  void pickAvatar(String avatarId) {
    selectedAvatar.value = avatarId;
    Haptics.light();
    _sound.playLetterTap(2);
  }

  Future<void> saveProfile() async {
    if (isSaving.value) return;
    isSaving.value = true;
    try {
      final updated = await _api.updateProfile(
        name: nameController.text.trim(),
        bio: bioController.text.trim(),
        avatar: selectedAvatar.value,
      );
      _storage.user.value = updated;
      Haptics.success();
      _sound.playWordCorrect();
      Get.snackbar(
        'Profile Updated',
        'Your Word Odyssey profile is synced with MongoDB!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xDD1E1048),
        colorText: Colors.white,
        margin: const EdgeInsets.all(14),
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Haptics.error();
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> toggleHaptics() async {
    final next = !_storage.haptics;
    _storage.haptics = next;
    Haptics.light();
    try {
      await _api.updateProfile(haptics: next);
    } catch (_) {}
  }

  Future<void> toggleSound() async {
    final next = !_storage.soundOn;
    _storage.soundOn = next;
    if (next) _sound.playLetterTap(3);
    try {
      await _api.updateProfile(soundOn: next);
    } catch (_) {}
  }

  Future<void> logout() async {
    Haptics.light();
    await _api.logout();
    await _storage.clearSession();
    Get.offAllNamed(AppRoutes.auth);
  }

  @override
  void onClose() {
    nameController.dispose();
    bioController.dispose();
    super.onClose();
  }
}
