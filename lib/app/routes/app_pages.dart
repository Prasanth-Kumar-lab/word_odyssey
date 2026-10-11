import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/duo_game_controller.dart';
import '../controllers/game_controller.dart';
import '../controllers/home_controller.dart';
import '../controllers/profile_controller.dart';
import '../controllers/splash_controller.dart';
import '../views/auth/auth_view.dart';
import '../views/duo/duo_game_view.dart';
import '../views/game/game_view.dart';
import '../views/home/home_view.dart';
import '../views/profile/profile_view.dart';
import '../views/splash/splash_view.dart';
import 'app_routes.dart';

abstract class AppPages {
  static final pages = <GetPage>[
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      binding: BindingsBuilder(() {
        Get.put(SplashController());
      }),
    ),
    GetPage(
      name: AppRoutes.auth,
      page: () => const AuthView(),
      binding: BindingsBuilder(() {
        Get.put(AuthController());
      }),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 560),
      curve: Curves.easeOutCubic,
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeView(),
      binding: BindingsBuilder(() {
        Get.put(HomeController());
      }),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
    ),
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfileView(),
      binding: BindingsBuilder(() {
        Get.put(ProfileController());
      }),
      transition: Transition.rightToLeftWithFade,
      transitionDuration: const Duration(milliseconds: 480),
      curve: Curves.easeOutCubic,
    ),
    GetPage(
      name: AppRoutes.game,
      page: () => const GameView(),
      binding: BindingsBuilder(() {
        Get.put(GameController());
      }),
      transition: Transition.zoom,
      transitionDuration: const Duration(milliseconds: 560),
      curve: Curves.easeOutCubic,
    ),
    GetPage(
      name: AppRoutes.duoGame,
      page: () => const DuoGameView(),
      binding: BindingsBuilder(() {
        Get.put(DuoGameController());
      }),
      transition: Transition.zoom,
      transitionDuration: const Duration(milliseconds: 560),
      curve: Curves.easeOutCubic,
    ),
  ];
}
