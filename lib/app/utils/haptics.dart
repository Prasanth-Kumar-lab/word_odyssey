import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../services/storage_service.dart';

abstract class Haptics {
  static bool get _on => Get.find<StorageService>().haptics;

  static void tick() {
    if (_on) HapticFeedback.selectionClick();
  }

  static void light() {
    if (_on) HapticFeedback.lightImpact();
  }

  static void success() {
    if (_on) HapticFeedback.mediumImpact();
  }

  static void error() {
    if (_on) HapticFeedback.heavyImpact();
  }
}
