import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../widgets/animated_background.dart';
import '../widgets/common_widgets.dart';
import '../widgets/game_avatar.dart';
import '../widgets/premium_motion.dart';

class AuthView extends GetView<AuthController> {
  const AuthView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, box) {
                final compact = box.maxWidth < 380;
                return Column(
                  children: [
                    _topBar(context, compact),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: compact ? 16 : 24,
                          vertical: 12,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: max(0, box.maxHeight - 80),
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 470),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _heroLogo(compact),
                                  const SizedBox(height: 20),
                                  Obx(
                                    () => AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 420),
                                      switchInCurve: Curves.easeOutBack,
                                      switchOutCurve: Curves.easeInCubic,
                                      transitionBuilder: (child, anim) => FadeTransition(
                                        opacity: anim,
                                        child: ScaleTransition(
                                          scale: Tween<double>(begin: 0.9, end: 1.0)
                                              .animate(anim),
                                          child: child,
                                        ),
                                      ),
                                      child: controller.isOtpStep.value
                                          ? _otpStepCard(context, compact)
                                          : _phoneStepCard(context, compact),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBar(BuildContext context, bool compact) {
    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 14 : 20, 8, compact ? 14 : 20, 0),
      child: Row(
        children: [
          GlassBox(
            radius: 20,
            blur: 8,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.green,
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scaleXY(begin: 0.8, end: 1.35, duration: 900.ms),
                const SizedBox(width: 7),
                Text(
                  'FASTAPI • MONGODB LIVE',
                  style: AppText.body(
                    10.5,
                    color: Colors.white70,
                    weight: FontWeight.w700,
                    spacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Pressable(
            onTap: () => _showServerDialog(context),
            child: GlassBox(
              radius: 20,
              blur: 8,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.dns_rounded, color: AppColors.cyan, size: 15),
                  const SizedBox(width: 6),
                  Text(
                    'API URL',
                    style: AppText.body(11, color: AppColors.cyan, weight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.4, end: 0);
  }

  Widget _heroLogo(bool compact) {
    final tile = compact ? 42.0 : 50.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: tile * 2.2,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              OrbitHalo(size: tile * 2.4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final (i, ch) in 'WORD'.split('').indexed)
                    LogoTile(ch, size: tile)
                        .animate()
                        .fadeIn(delay: (i * 70).ms, duration: 280.ms)
                        .scaleXY(
                          begin: 0.3,
                          end: 1,
                          delay: (i * 70).ms,
                          duration: 650.ms,
                          curve: Curves.elasticOut,
                        )
                        .animate(
                          onPlay: (c) => c.repeat(reverse: true),
                          delay: (i * 150).ms,
                        )
                        .moveY(begin: 0, end: -6, duration: 1500.ms),
                ],
              ),
            ],
          ),
        ),
        ShaderMask(
          shaderCallback: (r) => AppGradients.cool.createShader(r),
          blendMode: BlendMode.srcIn,
          child: Text(
            'ODYSSEY ARENA',
            style: AppText.display(compact ? 22 : 26, spacing: 2.5),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'SOLO CROSSWORDS & 1V1 LIVE DUO BATTLES',
          textAlign: TextAlign.center,
          style: AppText.body(
            10.5,
            color: Colors.white60,
            weight: FontWeight.w700,
            spacing: 1.8,
          ),
        ),
      ],
    );
  }

  Widget _phoneStepCard(BuildContext context, bool compact) {
    return GlassBox(
      key: const ValueKey('phone_step'),
      radius: 28,
      padding: EdgeInsets.fromLTRB(
        compact ? 16 : 24,
        22,
        compact ? 16 : 24,
        24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppGradients.hot,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.phone_iphone_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mobile OTP Sign In', style: AppText.display(20)),
                    Text(
                      'Secured with Bearer Token & MongoDB',
                      style: AppText.body(11.5, color: Colors.white60),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'CHOOSE YOUR CHAMPION AVATAR',
            style: AppText.body(
              11,
              color: AppColors.gold,
              weight: FontWeight.w700,
              spacing: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 76,
            child: Obx(() {
              final currentAvatar = controller.selectedAvatar.value;
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: GameAvatarSpec.catalog.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) {
                  final spec = GameAvatarSpec.catalog[i];
                  final selected = spec.id == currentAvatar;
                  return Pressable(
                    onTap: () => controller.selectedAvatar.value = spec.id,
                    child: AnimatedScale(
                      scale: selected ? 1.08 : 0.92,
                      duration: const Duration(milliseconds: 220),
                      child: AnimatedGameAvatar(
                        avatarId: spec.id,
                        size: 56,
                        isTurnActive: selected,
                      ),
                    ),
                  );
                },
              );
            }),
          ),
          const SizedBox(height: 14),
          Text(
            'MOBILE NUMBER',
            style: AppText.body(
              11,
              color: Colors.white70,
              weight: FontWeight.w700,
              spacing: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Obx(
                () => PopupMenuButton<String>(
                  initialValue: controller.countryCode.value,
                  color: const Color(0xFF241252),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onSelected: (v) => controller.countryCode.value = v,
                  itemBuilder: (_) => [
                    for (final c in AuthController.countryCodes)
                      PopupMenuItem(
                        value: c.$1,
                        child: Text(c.$2, style: AppText.body(14)),
                      ),
                  ],
                  child: Container(
                    height: 54,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white24),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          controller.countryCode.value,
                          style: AppText.display(16, color: AppColors.gold),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white70,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  child: TextField(
                    controller: controller.phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(12),
                    ],
                    style: AppText.display(18, spacing: 1.4),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: '9876543210',
                      hintStyle: AppText.body(16, color: Colors.white30),
                      icon: const Icon(
                        Icons.call_rounded,
                        color: AppColors.cyan,
                        size: 20,
                      ),
                    ),
                    onSubmitted: (_) => controller.requestOtp(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'PLAYER DISPLAY NAME (OPTIONAL)',
            style: AppText.body(
              11,
              color: Colors.white70,
              weight: FontWeight.w700,
              spacing: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white24),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            child: TextField(
              controller: controller.nameController,
              style: AppText.body(15, weight: FontWeight.w600),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'e.g. Cosmic Wordsmith',
                hintStyle: AppText.body(14, color: Colors.white30),
                icon: const Icon(
                  Icons.person_outline_rounded,
                  color: AppColors.gold,
                  size: 20,
                ),
              ),
            ),
          ),
          Obx(() {
            final err = controller.errorMessage.value;
            if (err == null) return const SizedBox(height: 18);
            return Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.red.withValues(alpha: 0.5)),
                ),
                child: Text(
                  err,
                  style: AppText.body(12.5, color: const Color(0xFFFECACA)),
                ),
              ).animate().shake(hz: 5, duration: 350.ms),
            );
          }),
          Obx(
            () => SoftPulse(
              borderRadius: 30,
              child: GradientButton(
                label: controller.isLoading.value ? 'SENDING OTP...' : 'GET OTP CODE',
                icon: Icons.bolt_rounded,
                height: 58,
                expand: true,
                onTap: controller.isLoading.value ? () {} : controller.requestOtp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _otpStepCard(BuildContext context, bool compact) {
    return GlassBox(
      key: const ValueKey('otp_step'),
      radius: 28,
      padding: EdgeInsets.fromLTRB(
        compact ? 16 : 24,
        22,
        compact ? 16 : 24,
        24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              GlassIconButton(
                icon: Icons.arrow_back_rounded,
                size: 40,
                onTap: controller.backToPhoneStep,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Verify 6-Digit OTP', style: AppText.display(20)),
                    Obx(
                      () => Text(
                        'Sent to ${controller.normalizedPhone.value}',
                        style: AppText.body(12, color: AppColors.cyan),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Obx(() {
            final hint = controller.devOtpHint.value;
            if (hint == null || hint.isEmpty) return const SizedBox.shrink();
            return Pressable(
              onTap: controller.autoFillDevOtp,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: AppGradients.cool,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cyan.withValues(alpha: 0.35),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.auto_awesome_rounded, color: AppColors.gold, size: 18),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'INSTANT OTP: $hint  •  TAP TO AUTO-FILL',
                        style: AppText.display(13.5, color: Colors.white, spacing: 1),
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(duration: 300.ms)
                  .scaleXY(begin: 0.85, end: 1, duration: 450.ms, curve: Curves.elasticOut)
                  .shimmer(duration: 1100.ms),
            );
          }),
          // Hidden TextField + 6 animated OTP boxes
          Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: 0.01,
                child: TextField(
                  controller: controller.otpController,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  onChanged: controller.onOtpChanged,
                ),
              ),
              Obx(() {
                final digits = controller.otpDigits;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (i) {
                    final char = digits[i];
                    final filled = char.isNotEmpty;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3.5),
                        child: AspectRatio(
                          aspectRatio: 0.86,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              gradient: filled ? AppGradients.gold : null,
                              color: filled ? null : Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: filled ? Colors.white : AppColors.cyan.withValues(alpha: 0.45),
                                width: filled ? 2 : 1.3,
                              ),
                              boxShadow: filled
                                  ? [
                                      BoxShadow(
                                        color: AppColors.gold.withValues(alpha: 0.5),
                                        blurRadius: 14,
                                      ),
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              char,
                              style: AppText.display(
                                24,
                                color: filled ? AppColors.ink : Colors.white,
                              ),
                            )
                                .animate(key: ValueKey('otp_${i}_$char'))
                                .scaleXY(
                                  begin: 0.4,
                                  end: 1.0,
                                  duration: 280.ms,
                                  curve: Curves.elasticOut,
                                ),
                          ),
                        ),
                      ),
                    );
                  }),
                );
              }),
            ],
          ),
          Obx(() {
            final err = controller.errorMessage.value;
            if (err == null) return const SizedBox(height: 18);
            return Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 10),
              child: Text(
                err,
                textAlign: TextAlign.center,
                style: AppText.body(12.5, color: AppColors.red),
              ).animate().shake(hz: 6, duration: 350.ms),
            );
          }),
          Obx(
            () => SoftPulse(
              borderRadius: 30,
              child: GradientButton(
                label: controller.isLoading.value
                    ? 'VERIFYING...'
                    : 'VERIFY & ENTER ARENA',
                icon: Icons.verified_rounded,
                height: 58,
                expand: true,
                onTap: controller.isLoading.value ? () {} : controller.verifyOtp,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Obx(() {
            final wait = controller.resendSeconds.value;
            return wait > 0
                ? Text(
                    'Resend OTP in ${wait}s',
                    style: AppText.body(12.5, color: Colors.white54),
                  )
                : Pressable(
                    onTap: controller.requestOtp,
                    child: Text(
                      'Resend OTP Code',
                      style: AppText.body(
                        13,
                        color: AppColors.gold,
                        weight: FontWeight.w700,
                      ),
                    ),
                  );
          }),
        ],
      ),
    );
  }

  void _showServerDialog(BuildContext context) {
    final txt = TextEditingController(text: controller.apiBaseUrl);
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: GlassBox(
          radius: 24,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('FastAPI Server Endpoint', style: AppText.display(20)),
              const SizedBox(height: 6),
              Text(
                'Use your local FastAPI + MongoDB Compass server or paste your live Render URL:',
                style: AppText.body(12.5, color: Colors.white70),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white24),
                ),
                child: TextField(
                  controller: txt,
                  style: AppText.body(14),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'https://word-odyssey-api.onrender.com',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Pressable(
                      onTap: () {
                        controller.updateServerUrl('');
                        Get.back();
                      },
                      child: Container(
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Text('Reset Default', style: AppText.body(13)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GradientButton(
                      label: 'SAVE',
                      height: 44,
                      expand: true,
                      onTap: () {
                        controller.updateServerUrl(txt.text);
                        Get.back();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
