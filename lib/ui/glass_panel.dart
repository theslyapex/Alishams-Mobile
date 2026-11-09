import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Restrained frosted glass panel for ALISHAMS dark-glass surfaces.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 22,
    this.blur = 22,
    this.opacity = 0.55,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double blur;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final radius = BorderRadius.circular(borderRadius);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            color: c.surface.withValues(alpha: opacity),
            border: Border.all(color: c.outline),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                c.primary.withValues(alpha: 0.14),
                c.surface.withValues(alpha: opacity),
                c.secondary.withValues(alpha: 0.08),
              ],
            ),
          ),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(22),
            child: child,
          ),
        ),
      ),
    );
  }
}
