import 'package:flutter/animation.dart';
import 'package:get/get.dart';

import '../routes/app_routes.dart';
import '../services/dictionary_service.dart';
import '../services/storage_service.dart';

class SplashController extends GetxController {
  final progress = 0.0.obs;

  @override
  void onReady() {
    super.onReady();
    _boot();
  }

  Future<void> _boot() async {
    final started = DateTime.now();
    const minSplash = Duration(milliseconds: 2800);
    const climb = Duration(milliseconds: 2200);

    final dictFuture = Get.find<DictionaryService>().load();
    final sessionFuture = Get.find<StorageService>().restoreSessionFromApi();

    while (DateTime.now().difference(started) < climb) {
      await Future.delayed(const Duration(milliseconds: 40));
      final u = DateTime.now().difference(started).inMilliseconds / climb.inMilliseconds;
      progress.value = Curves.easeInOutCubic.transform(u.clamp(0.0, 1.0)) * 0.92;
    }

    await dictFuture;
    final loggedIn = await sessionFuture;
    progress.value = 1;

    final elapsed = DateTime.now().difference(started);
    if (elapsed < minSplash) {
      await Future.delayed(minSplash - elapsed);
    }

    if (loggedIn) {
      Get.offAllNamed(AppRoutes.home);
    } else {
      Get.offAllNamed(AppRoutes.auth);
    }
  }
}
