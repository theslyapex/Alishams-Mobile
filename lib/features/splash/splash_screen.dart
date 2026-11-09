import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../assets/app_assets.dart';

import '../../motion/motion.dart';
import '../../theme/app_chrome.dart';
import '../../theme/app_colors.dart';
import '../../ui/studio_backdrop.dart';

/// Single-path sun glyph for [AppBrandMark] draw animation.
const kAlishamsMarkPath =
    'M64 36 C76 36 86 46 86 58 C86 70 76 80 64 80 C52 80 42 70 42 58 '
    'C42 46 52 36 64 36 Z '
    'M64 18 L64 28 M64 88 L64 98 '
    'M34 28 L42 36 M86 80 L94 88 '
    'M94 28 L86 36 M42 80 L34 88 '
    'M22 58 L34 58 M94 58 L106 58 '
    'M28 108 C44 96 84 96 100 108';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _markDone = false;
  Timer? _routeTimer;

  @override
  void initState() {
    super.initState();
    _routeTimer = Timer(const Duration(milliseconds: 1700), _onMarkDone);
  }

  @override
  void dispose() {
    _routeTimer?.cancel();
    super.dispose();
  }

  void _onMarkDone() {
    if (!mounted) return;
    setState(() => _markDone = true);
    _routeTimer = Timer(AppMotion.lg + AppMotion.md, () {
      if (!mounted) return;
      final auth = ref.read(authProvider);
      if (auth.requiresMfa) {
        context.go('/mfa-verify');
      } else if (auth.isSignedIn) {
        context.go('/home');
      } else {
        context.go('/sign-in');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return ChromeScope(
      top: c.background,
      bottom: c.background,
      child: Scaffold(
        backgroundColor: c.background,
        body: StudioBackdrop(
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  MotionSlot(
                    'splash.hero',
                    child: SvgPicture.asset(
                      AppAssets.logoSvg,
                      width: 290,
                      height: 290,
                      fit: BoxFit.contain,
                      semanticsLabel: 'ALISHAMS Digital Studio',
                    ),
                  ),
                  const SizedBox(height: 28),
                  MotionSlot(
                    'splash.content',
                    index: 0,
                    child: _markDone
                        ? Column(
                            children: [
                              AppKineticText(
                                'علی‌شمس',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      color: c.ink,
                                      fontWeight: FontWeight.w700,
                                    ),
                                kinetic: KineticStyle.rise,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              AppReveal(
                                style: RevealStyle.fade,
                                delay: AppMotion.sm,
                                child: Text(
                                  'استودیو دیجیتال',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: c.muted,
                                        letterSpacing: 0.6,
                                      ),
                                ),
                              ),
                            ],
                          )
                        : const SizedBox(height: 48),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
