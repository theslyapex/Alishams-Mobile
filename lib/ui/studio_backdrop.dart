import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Deep navy stage with soft purple / cyan orbs — no photo noise.
class StudioBackdrop extends StatelessWidget {
  const StudioBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return ColoredBox(
      color: c.background,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -80,
            left: -40,
            child: _Orb(color: c.primary, size: 260, opacity: 0.28),
          ),
          Positioned(
            bottom: 40,
            right: -60,
            child: _Orb(color: c.secondary, size: 220, opacity: 0.18),
          ),
          Positioned(
            top: 220,
            right: 20,
            child: _Orb(color: c.tertiary, size: 120, opacity: 0.16),
          ),
          child,
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({
    required this.color,
    required this.size,
    required this.opacity,
  });

  final Color color;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
