import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/user_model.dart';
import '../routes/app_routes.dart';
import '../services/api_service.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../utils/haptics.dart';

class AuthController extends GetxController {
  final ApiService _api = Get.find<ApiService>();
  final StorageService _storage = Get.find<StorageService>();
  final SoundService _sound = Get.find<SoundService>();

  final phoneController = TextEditingController();
  final nameController = TextEditingController();
  final otpController = TextEditingController();

  final countryCode = '+91'.obs;
  final selectedAvatar = GameAvatarSpec.catalog.first.id.obs;
  final isOtpStep = false.obs;
  final isLoading = false.obs;
  final errorMessage = RxnString();
  final devOtpHint = RxnString();
  final normalizedPhone = ''.obs;
  final resendSeconds = 0.obs;
  final otpDigits = List<String>.filled(6, '').obs;

  Timer? _resendTimer;

  static const List<(String, String)> countryCodes = [
    ('+91', 'IN +91'),
    ('+1', 'US +1'),
    ('+44', 'UK +44'),
    ('+971', 'AE +971'),
    ('+61', 'AU +61'),
    ('+65', 'SG +65'),
  ];

  String get apiBaseUrl => _api.baseUrl;

  void onOtpChanged(String val) {
    final clean = val.replaceAll(RegExp(r'[^0-9]'), '');
    for (var i = 0; i < 6; i++) {
      otpDigits[i] = i < clean.length ? clean[i] : '';
    }
    otpDigits.refresh();
    errorMessage.value = null;
    if (clean.length == 6 && !isLoading.value) {
      verifyOtp();
    }
  }

  void autoFillDevOtp() {
    final code = devOtpHint.value;
    if (code == null || code.length != 6) return;
    Haptics.success();
    _sound.playBonusWord();
    otpController.text = code;
    onOtpChanged(code);
  }

  Future<void> requestOtp() async {
    final rawPhone = phoneController.text.trim();
    final digits = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 6) {
      errorMessage.value = 'Enter a valid mobile number (at least 6 digits)';
      Haptics.error();
      _sound.playWrongWord();
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;
    try {
      final res = await _api.sendOtp(
        phone: digits,
        countryCode: countryCode.value,
      );
      normalizedPhone.value = (res['phone'] ?? '${countryCode.value}$digits').toString();
      devOtpHint.value = res['otp']?.toString();
      isOtpStep.value = true;
      otpController.clear();
      otpDigits.assignAll(List<String>.filled(6, ''));
      _startResendCountdown();
      Haptics.success();
      _sound.playWordCorrect();
    } on ApiException catch (e) {
      errorMessage.value = e.message;
      Haptics.error();
      _sound.playWrongWord();
    } catch (e) {
      errorMessage.value = 'Could not connect to FastAPI server ($apiBaseUrl)';
      Haptics.error();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyOtp() async {
    final otp = otpController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (otp.length != 6) {
      errorMessage.value = 'Please enter the 6-digit OTP code';
      Haptics.error();
      _sound.playWrongWord();
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;
    try {
      final res = await _api.verifyOtp(
        phone: normalizedPhone.value,
        otp: otp,
        name: nameController.text.trim(),
        avatar: selectedAvatar.value,
      );

      final token = (res['token'] ?? '').toString();
      final userMap = Map<String, dynamic>.from(res['user'] as Map);
      final soloMap = res['soloState'] is Map
          ? Map<String, dynamic>.from(res['soloState'] as Map)
          : null;

      await _storage.persistSessionToken(token);
      _storage.applyServerPayload(userJson: userMap, soloStateJson: soloMap);

      Haptics.success();
      _sound.playVictory();
      Get.offAllNamed(AppRoutes.home);
    } on ApiException catch (e) {
      errorMessage.value = e.message;
      Haptics.error();
      _sound.playWrongWord();
    } catch (_) {
      errorMessage.value = 'OTP verification failed. Please try again.';
      Haptics.error();
    } finally {
      isLoading.value = false;
    }
  }

  void backToPhoneStep() {
    isOtpStep.value = false;
    errorMessage.value = null;
    Haptics.light();
  }

  Future<void> updateServerUrl(String url) async {
    await _storage.persistCustomBaseUrl(url);
    errorMessage.value = null;
    Haptics.success();
  }

  void _startResendCountdown() {
    _resendTimer?.cancel();
    resendSeconds.value = 30;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (resendSeconds.value <= 1) {
        resendSeconds.value = 0;
        t.cancel();
      } else {
        resendSeconds.value--;
      }
    });
  }

  @override
  void onClose() {
    _resendTimer?.cancel();
    phoneController.dispose();
    nameController.dispose();
    otpController.dispose();
    super.onClose();
  }
}
