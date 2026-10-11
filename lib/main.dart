import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/services/api_service.dart';
import 'app/services/dictionary_service.dart';
import 'app/services/sound_service.dart';
import 'app/services/storage_service.dart';
import 'app/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Get.put(ApiService(), permanent: true);
  Get.put(StorageService(), permanent: true);
  Get.put(SoundService(), permanent: true);
  Get.put(DictionaryService(), permanent: true);

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const WordOdysseyApp());
}

class WordOdysseyApp extends StatelessWidget {
  const WordOdysseyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Word Odyssey',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      initialRoute: AppRoutes.splash,
      getPages: AppPages.pages,
      defaultTransition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 600),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: media.textScaler.clamp(minScaleFactor: 0.85, maxScaleFactor: 1.15),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
