import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import 'app_motion.dart';
import 'app_particles.dart';

/// The app's completion moment (order placed, booking confirmed, goal hit).
///
/// Plays this app's catalogue success (`AppMotion.preset.success`):
/// `check` (disc pops, check draws), `confetti` (+ a confetti burst),
/// `burst` (rays fly out), `stamp` (slams down with a turn) or `ripple`
/// (rings spread). Under reduced motion it shows the finished disc + check.
///
/// ```dart
/// AppSuccess()   // on the confirmation screen; colours come from the theme
/// ```
class AppSuccess extends StatefulWidget {
  const AppSuccess({
    super.key,
    this.size = 88,
    this.color,
    this.onColor,
    this.delay = Duration.zero,
    this.confettiColors,
    this.semanticLabel = 'Done',
  });

  final double size;

  /// Disc, rays and rings; defaults to the theme's `colorScheme.primary`.
  final Color? color;

  /// The check mark; defaults to `colorScheme.onPrimary`.
  final Color? onColor;
  final Duration delay;

  /// Confetti colours for the `confetti` style (defaults to the disc colour
  /// family plus the theme's `colorScheme.tertiary`).
  final List<Color>? confettiColors;
  final String semanticLabel;

  @override
  State<AppSuccess> createState() => _AppSuccessState();
}

class _AppSuccessState extends State<AppSuccess> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  Timer? _timer;
  bool _started = false;
  bool _confetti = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (AppMotion.reduced(context)) {
      _c.value = 1;
      return;
    }
    _c.duration = AppMotion.xl * 2.2;
    _timer = Timer(widget.delay, () {
      if (!mounted) return;
      _c.forward();
      final haptics = AppMotion.preset.haptics;
      if (haptics != MotionHaptics.none) {
        _timer = Timer(AppMotion.md, () {
          if (!mounted) return;
          haptics == MotionHaptics.rich ? HapticFeedback.mediumImpact() : HapticFeedback.lightImpact();
          if (AppMotion.preset.success == MotionSuccess.confetti) setState(() => _confetti = true);
        });
      } else if (AppMotion.preset.success == MotionSuccess.confetti) {
        _timer = Timer(AppMotion.md, () {
          if (mounted) setState(() => _confetti = true);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final style = AppMotion.preset.success;
    final scheme = Theme.of(context).colorScheme;
    final color = widget.color ?? scheme.primary;
    final onColor = widget.onColor ?? scheme.onPrimary;
    return Semantics(
      label: widget.semanticLabel,
      child: SizedBox(
        width: s,
        height: s,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            if (_confetti)
              Positioned(
                left: -s,
                top: -s * 0.6,
                width: s * 3,
                height: s * 2.6,
                child: IgnorePointer(
                  child: AppConfetti(
                    colors: widget.confettiColors ??
                        [color, Color.lerp(color, const Color(0xFFFFFFFF), .45)!, scheme.tertiary],
                  ),
                ),
              ),
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) => CustomPaint(
                  size: Size.square(s),
                  painter: _SuccessPainter(style: style, t: _c.value, color: color, onColor: onColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessPainter extends CustomPainter {
  _SuccessPainter({required this.style, required this.t, required this.color, required this.onColor});

  final MotionSuccess style;
  final double t;
  final Color color;
  final Color onColor;

  double _seg(double a, double b, [Curve curve = Curves.linear]) => curve.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    double disc;
    double angle = 0;
    double discOpacity = 1;
    double check;
    switch (style) {
      case MotionSuccess.stamp:
        final k = _seg(0, 0.3, Curves.easeIn);
        disc = 1.7 - 0.7 * k + 0.06 * math.sin(_seg(0.3, 0.5) * math.pi);
        angle = -0.35 * (1 - k);
        discOpacity = _seg(0, 0.15);
        check = _seg(0.32, 0.55, Curves.easeOut);
      case MotionSuccess.ripple:
        disc = 0.6 + 0.4 * _seg(0, 0.35, Curves.easeOutCubic);
        discOpacity = _seg(0, 0.25);
        check = _seg(0.3, 0.65, Curves.easeOut);
      case MotionSuccess.check:
      case MotionSuccess.confetti:
      case MotionSuccess.burst:
        disc = _seg(0, 0.4, AppMotion.popCurve);
        check = _seg(0.35, 0.75, Curves.easeOut);
    }

    final paint = Paint()..isAntiAlias = true;
    // Behind the disc: rays or rings.
    if (style == MotionSuccess.burst) {
      final k = _seg(0.3, 0.85, Curves.easeOutCubic);
      final fade = 1 - _seg(0.6, 1);
      if (k > 0 && fade > 0) {
        paint
          ..color = color.withValues(alpha: fade)
          ..strokeWidth = r * 0.09
          ..strokeCap = StrokeCap.round;
        for (var i = 0; i < 10; i++) {
          final a = i * math.pi / 5 + math.pi / 10;
          final dir = Offset(math.cos(a), math.sin(a));
          canvas.drawLine(c + dir * r * (1.05 + 0.25 * k), c + dir * r * (1.15 + 0.55 * k), paint);
        }
      }
    }
    if (style == MotionSuccess.ripple) {
      for (final start in [0.25, 0.45]) {
        final k = _seg(start, start + 0.5, Curves.easeOutCubic);
        if (k <= 0 || k >= 1) continue;
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.06
          ..color = color.withValues(alpha: (1 - k) * 0.8);
        canvas.drawCircle(c, r * (1 + 0.8 * k), paint);
      }
      paint.style = PaintingStyle.fill;
    }

    if (disc <= 0) return;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(angle);
    canvas.scale(disc);
    paint
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: color.a * discOpacity);
    canvas.drawCircle(Offset.zero, r, paint);
    if (check > 0) {
      final path = Path()
        ..moveTo(-r * 0.38, r * 0.02)
        ..lineTo(-r * 0.1, r * 0.3)
        ..lineTo(r * 0.42, -r * 0.28);
      final metric = path.computeMetrics().first;
      canvas.drawPath(
        metric.extractPath(0, metric.length * check),
        Paint()
          ..isAntiAlias = true
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.14
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = onColor,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SuccessPainter old) => old.t != t || old.style != style || old.color != color || old.onColor != onColor;
}
