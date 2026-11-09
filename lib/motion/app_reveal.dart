import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'app_motion.dart';

/// How an element arrives on screen.
enum RevealStyle {
  /// This app's catalogue entrance (rise, fall, slide, grow, settle, tilt,
  /// wipe or fade — `AppMotion.preset.entrance`). The default.
  auto,

  /// Fade + rise 16 dp. Text, list rows, cards.
  rise,

  /// Opacity only. Content swapped in place, map overlays.
  fade,

  /// Scale 0.5 → 1 with a small overshoot. Pins, badges, stars, chips that "land".
  pop,

  /// Slide up from below like an iOS sheet. Bottom cards, sheets, toasts.
  sheet,

  /// Drop from above with an overshoot. In-app notifications.
  drop,

  /// Slide in from the right. Chip rails, horizontal carousels.
  slideIn,
}

/// One-shot entrance animation.
///
/// Plays once when the widget is first built (after [delay] plus a stagger of
/// [index] × 40 ms). It never replays on rebuild; give it a new [Key] to replay.
/// Under reduced motion it renders the final state immediately.
///
/// ```dart
/// AppReveal(index: i, child: ProRow(pro))           // staggered list row
/// AppReveal.pop(delay: AppMotion.ms(700), child: MapPin(...))
/// AppReveal.sheet(delay: AppMotion.ms(1750), child: ProCard(...))
/// ```
class AppReveal extends StatefulWidget {
  const AppReveal({
    super.key,
    required this.child,
    this.style = RevealStyle.auto,
    this.index = 0,
    this.delay = Duration.zero,
    this.duration,
    this.distance,
  });

  const AppReveal.fade({
    super.key,
    required this.child,
    this.index = 0,
    this.delay = Duration.zero,
    this.duration,
  })  : style = RevealStyle.fade,
        distance = null;

  const AppReveal.pop({
    super.key,
    required this.child,
    this.index = 0,
    this.delay = Duration.zero,
    this.duration,
  })  : style = RevealStyle.pop,
        distance = null;

  const AppReveal.sheet({
    super.key,
    required this.child,
    this.index = 0,
    this.delay = Duration.zero,
    this.duration,
    this.distance,
  }) : style = RevealStyle.sheet;

  const AppReveal.drop({
    super.key,
    required this.child,
    this.index = 0,
    this.delay = Duration.zero,
    this.duration,
    this.distance,
  }) : style = RevealStyle.drop;

  const AppReveal.slideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.delay = Duration.zero,
    this.duration,
    this.distance,
  }) : style = RevealStyle.slideIn;

  final Widget child;
  final RevealStyle style;

  /// Position in a staggered group; adds index × [AppMotion.stagger].
  final int index;
  final Duration delay;

  /// Overrides the style's default duration.
  final Duration? duration;

  /// Travel distance in logical pixels (rise/sheet/drop/slideIn).
  final double? distance;

  @override
  State<AppReveal> createState() => _AppRevealState();
}

class _AppRevealState extends State<AppReveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  Timer? _timer;
  bool _started = false;

  Duration get _duration =>
      widget.duration ??
      switch (widget.style) {
        RevealStyle.auto || RevealStyle.rise => AppMotion.lg * AppMotion.revealDurationFactor,
        RevealStyle.fade => AppMotion.md * AppMotion.revealDurationFactor,
        RevealStyle.pop => AppMotion.xl * AppMotion.revealDurationFactor,
        RevealStyle.sheet => AppMotion.sheetDuration,
        RevealStyle.drop => AppMotion.xl * 1.2,
        RevealStyle.slideIn => AppMotion.lg,
      };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (AppMotion.reduced(context)) {
      _c.value = 1;
      return;
    }
    _c.duration = _duration;
    final wait = widget.delay + AppMotion.staggerDelay(widget.index);
    if (wait == Duration.zero) {
      _c.forward();
    } else {
      _timer = Timer(wait, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The fade runs on the controller through FadeTransition (no `Opacity`
    // widget rebuilt per frame); the builder only moves / scales.
    return FadeTransition(
      opacity: _c.drive(CurveTween(curve: _fadeCurve)),
      child: AnimatedBuilder(
        animation: _c,
        child: widget.child,
        builder: (context, child) {
          final t = _c.value;
          switch (widget.style) {
            case RevealStyle.auto:
              return _entrance(context, t, child);
            case RevealStyle.fade:
              return child ?? const SizedBox.shrink();
            case RevealStyle.rise:
              final v = AppMotion.revealCurve.transform(t);
              final double d = widget.distance ?? AppMotion.revealDistance;
              final s0 = AppMotion.revealScaleFrom;
              return Transform.translate(
                offset: Offset(0, d * (1 - v)),
                child: Transform.scale(scale: s0 + (1 - s0) * v, child: child),
              );
            case RevealStyle.slideIn:
              final v = AppMotion.revealCurve.transform(t);
              final double d = widget.distance ?? 26.0;
              return Transform.translate(offset: Offset(d * (1 - v), 0), child: child);
            case RevealStyle.pop:
              final s0 = AppMotion.popScaleFrom;
              final s = s0 + (1 - s0) * AppMotion.popCurve.transform(t);
              return Transform.scale(scale: s, child: child);
            case RevealStyle.sheet:
              final v = AppMotion.sheet.transform(t);
              final double d = widget.distance ?? 90.0;
              return Transform.translate(offset: Offset(0, d * (1 - v)), child: child);
            case RevealStyle.drop:
              final v = AppMotion.pop.transform(t);
              final double d = widget.distance ?? 90.0;
              return Transform.translate(offset: Offset(0, -d * (1 - v)), child: child);
          }
        },
      ),
    );
  }

  /// Opacity over the controller's 0…1 for each style.
  Curve get _fadeCurve => switch (widget.style) {
        RevealStyle.auto => AppMotion.preset.entrance == MotionEntrance.wipe ? const Interval(0, 0.25) : const Interval(0, 0.6),
        RevealStyle.fade => AppMotion.standard,
        RevealStyle.rise => const Interval(0, 0.6),
        // revealCurve overshoots on back / elastic styles; opacity must stay in 0…1.
        RevealStyle.slideIn => AppMotion.clamped(AppMotion.revealCurve),
        RevealStyle.pop => const Interval(0, 0.35),
        RevealStyle.sheet || RevealStyle.drop => const Interval(0, 0.3),
      };

  Widget _entrance(BuildContext context, double t, Widget? child) {
    final v = AppMotion.revealCurve.transform(t);
    final double d = widget.distance ?? AppMotion.revealDistance;
    final rtl = Directionality.maybeOf(context) == TextDirection.rtl;
    Widget body;
    switch (AppMotion.preset.entrance) {
      case MotionEntrance.rise:
        body = Transform.translate(offset: Offset(0, d * (1 - v)), child: child);
      case MotionEntrance.fall:
        body = Transform.translate(offset: Offset(0, -d * (1 - v)), child: child);
      case MotionEntrance.slideStart:
        body = Transform.translate(offset: Offset((rtl ? d : -d) * 1.4 * (1 - v), 0), child: child);
      case MotionEntrance.slideEnd:
        body = Transform.translate(offset: Offset((rtl ? -d : d) * 1.4 * (1 - v), 0), child: child);
      case MotionEntrance.grow:
        body = Transform.translate(
          offset: Offset(0, d * 0.5 * (1 - v)),
          child: Transform.scale(scale: 0.9 + 0.1 * v, child: child),
        );
      case MotionEntrance.settle:
        body = Transform.scale(scale: 1.06 - 0.06 * v, child: child);
      case MotionEntrance.tilt:
        body = Transform(
          alignment: Alignment.bottomCenter,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0015)
            ..rotateX((1 - v) * math.pi / 7)
            ..translateByDouble(0, d * 0.5 * (1 - v), 0, 1),
          child: child,
        );
      case MotionEntrance.wipe:
        body = ClipRect(
          clipper: _WipeClipper(Curves.easeOutCubic.transform(t)),
          child: Transform.translate(offset: Offset(0, d * 0.4 * (1 - v)), child: child),
        );
      case MotionEntrance.fade:
        body = child ?? const SizedBox.shrink();
    }
    return body; // faded by the FadeTransition in build()
  }
}

/// Reveals its child top-down as [t] goes 0 → 1.
class _WipeClipper extends CustomClipper<Rect> {
  _WipeClipper(this.t);
  final double t;

  @override
  Rect getClip(Size size) => Rect.fromLTWH(-size.width, -size.height, size.width * 3, size.height * (1 + t));

  @override
  bool shouldReclip(_WipeClipper old) => old.t != t;
}
