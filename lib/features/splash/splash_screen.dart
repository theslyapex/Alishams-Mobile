import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import '../../assets/app_assets.dart';

import '../../motion/motion.dart';
import '../../theme/app_chrome.dart';
import '../../theme/app_colors.dart';
import '../../ui/studio_backdrop.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _expanded = false;
  Timer? _expandTimer;
  Timer? _routeTimer;

  @override
  void initState() {
    super.initState();
    _expandTimer = Timer(const Duration(milliseconds: 1250), () {
      if (mounted) setState(() => _expanded = true);
    });
    _routeTimer = Timer(const Duration(milliseconds: 3300), _continue);
  }

  @override
  void dispose() {
    _expandTimer?.cancel();
    _routeTimer?.cancel();
    super.dispose();
  }

  void _continue() {
    if (!mounted) return;
    final auth = ref.read(authProvider);
    if (auth.requiresMfa) {
      context.go('/mfa-verify');
    } else if (auth.isSignedIn) {
      context.go('/home');
    } else {
      context.go('/sign-in');
    }
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
                    child: Image.asset(
                      AppAssets.logo,
                      width: 290,
                      height: 290,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(Icons.auto_awesome, size: 120, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 30),
                  MotionSlot(
                    'splash.brand',
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Alishams ',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: c.ink,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.8,
                            ),
                          ),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 850),
                            curve: Curves.easeInOutCubic,
                            alignment: Alignment.centerLeft,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 650),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              transitionBuilder: (child, animation) {
                                final slide = Tween<Offset>(
                                  begin: const Offset(0.0, 0.28),
                                  end: Offset.zero,
                                ).animate(animation);
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(position: slide, child: child),
                                );
                              },
                              child: Text(
                                _expanded ? 'Digital Studio' : 'DS',
                                key: ValueKey(_expanded),
                                maxLines: 1,
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: c.secondary,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.8,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  AnimatedOpacity(
                    opacity: _expanded ? 1 : 0,
                    duration: const Duration(milliseconds: 500),
                    child: Text(
                      'CREATIVE • DIGITAL • EXPERIENCE',
                      textDirection: TextDirection.ltr,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: c.muted,
                        letterSpacing: 2.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
