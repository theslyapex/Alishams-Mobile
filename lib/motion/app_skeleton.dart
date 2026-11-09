import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_motion.dart';

/// Shimmering placeholder in the shape of the content that is loading.
/// Prefer this over a spinner whenever the layout is known.
/// Plays this app's catalogue loading (`AppMotion.preset.loading`): a
/// shimmer sweep, a soft pulse or a quick diagonal glint. It stops under
/// reduced motion.
class AppSkeleton extends StatefulWidget {
  const AppSkeleton({
    super.key,
    this.width,
    this.height = 14,
    this.radius = 8,
    this.base,
    this.highlight,
  });

  /// A circle (avatars).
  const AppSkeleton.circle({
    super.key,
    double size = 40,
    this.base,
    this.highlight,
  })  : width = size,
        height = size,
        radius = size / 2;

  final double? width;
  final double height;
  final double radius;
  /// Resting fill; defaults to the theme's `colorScheme.surfaceContainerHighest`.
  final Color? base;

  /// Sweep / pulse peak; defaults to `colorScheme.surfaceContainerLow`.
  final Color? highlight;

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: AppMotion.shimmer);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduced(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = widget.base ?? scheme.surfaceContainerHighest;
    final highlight = widget.highlight ?? scheme.surfaceContainerLow;
    return Semantics(
      label: 'Loading',
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value;
            final radius = BorderRadius.circular(widget.radius);
            switch (AppMotion.preset.loading) {
              case MotionLoading.pulse:
                final k = 0.5 - 0.5 * math.cos(t * 2 * math.pi);
                return Container(
                  width: widget.width,
                  height: widget.height,
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    color: Color.lerp(base, highlight, k),
                  ),
                );
              case MotionLoading.glint:
                // A fast sweep in the first 45% of the cycle, then rest.
                final p = (t / 0.45).clamp(0.0, 1.0);
                return Container(
                  width: widget.width,
                  height: widget.height,
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [base, highlight, base],
                      stops: const [0.4, 0.5, 0.6],
                      transform: _Slide(p * 2.4 - 1.2),
                    ),
                  ),
                );
              case MotionLoading.shimmer:
                return Container(
                  width: widget.width,
                  height: widget.height,
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    gradient: LinearGradient(
                      colors: [base, highlight, base],
                      stops: const [0.25, 0.5, 0.75],
                      transform: _Slide(t * 2 - 1),
                    ),
                  ),
                );
            }
          },
        ),
      ),
    );
  }
}

class _Slide extends GradientTransform {
  const _Slide(this.p);
  final double p;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * p, 0, 0);
}
