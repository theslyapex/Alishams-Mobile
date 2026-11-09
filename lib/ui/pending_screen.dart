import 'package:flutter/material.dart';

import '../motion/motion.dart';
import '../theme/app_chrome.dart';
import '../theme/app_colors.dart';
import 'studio_backdrop.dart';

/// Lightweight landing while the rest of the product is built later.
class PendingScreen extends StatelessWidget {
  const PendingScreen({
    super.key,
    this.title = 'به‌زودی',
    this.message = 'این بخش در مرحله بعد ساخته می‌شود.',
  });

  final String title;
  final String message;

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
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MotionSlot(
                      'home.hero',
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),
                    MotionSlot(
                      'home.content',
                      index: 0,
                      child: Text(
                        message,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: c.muted,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
