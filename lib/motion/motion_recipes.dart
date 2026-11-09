// Motion recipes — fluttergo-motion-brain v1.3.
//
// The premium moves from references/animation-catalog.md as ready widgets, so
// "impressive" is a widget the agent drops in, not something it has to invent:
//
//   settle       MotionSettle          LEAD set down on the table (1.04 → 1 + fade)
//   reveal_clip  MotionMaskReveal      mask opens, content counter-drifts
//   stamp        MotionStamp           confirmation mark lands hard
//   blur         MotionFocusIn         blurred → sharp (fade on web / reduced)
//   ring         MotionTouchRing       ring from the finger: cause → effect
//   roll         MotionRollingNumber   odometer digits, only changed digits move
//   glide        MotionSelectionGlide  selection indicator travels between options
//   flip         MotionFlip            3D card turn
//   tilt         MotionTilt            card tilts toward the finger, springs flat
//   pulse        MotionPulse           live indicator that breathes and stops
//   morph_shape  MotionMorph           one container reshapes, content crossfades inside
//   routes       MotionTransitions     every transition in tools/catalog.json,
//                                      growing from the last tap (MotionOrigin)
//
// Every widget: timing from AppMotion, reduced motion honoured (settles at once
// or keeps only the essential cue), controllers disposed, loops stop.

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import 'app_motion.dart';

// ───────────────────────────── origin of the last tap ─────────────────────────────

/// Where the user last touched, in global coordinates. MotionSlot CONTROLs and
/// [MotionTouchRing] record it; [MotionTransitions] grows the next surface from
/// it, so a sheet or detail screen comes *from* the button that opened it.
abstract final class MotionOrigin {
  static Rect? last;

  /// Records the rect of the widget at [context].
  static void capture(BuildContext context) {
    final box = context.findRenderObject();
    if (box is RenderBox && box.attached && box.hasSize) {
      last = box.localToGlobal(Offset.zero) & box.size;
    }
  }

  /// Returns the last origin once (a later route without a tap starts centred).
  static Rect? take() {
    final r = last;
    last = null;
    return r;
  }
}

// ───────────────────────────── shared one-shot driver ─────────────────────────────

/// Plays 0 → 1 once after [delay] with a curve or a spring; builds through
/// [builder]. Reduced motion: value 1 at once. Used by the entrance recipes.
class MotionOnce extends StatefulWidget {
  const MotionOnce({
    super.key,
    required this.builder,
    required this.child,
    this.delay = Duration.zero,
    this.duration,
    this.curve,
    this.spring,
  });

  final Widget Function(BuildContext context, double t, Widget child) builder;
  final Widget child;
  final Duration delay;
  final Duration? duration;
  final Curve? curve;
  final SpringDescription? spring;

  @override
  State<MotionOnce> createState() => _MotionOnceState();
}

class _MotionOnceState extends State<MotionOnce> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController.unbounded(vsync: this);
  Timer? _timer;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (AppMotion.reduced(context)) {
      _c.value = 1;
      return;
    }
    if (widget.delay == Duration.zero) {
      _play();
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) _play();
      });
    }
  }

  void _play() {
    final spring = widget.spring;
    if (spring != null) {
      _c.animateWith(SpringSimulation(spring, 0, 1, 0));
    } else {
      _c.animateTo(1, duration: widget.duration ?? AppMotion.lg, curve: widget.curve ?? AppMotion.enter);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        child: widget.child,
        builder: (context, child) => widget.builder(context, _c.value, child!),
      );
}

double _unit(double t) => t.clamp(0.0, 1.0);

/// settle: scales from 1.04 to 1 while fading in — a card set down on a table.
class MotionSettle extends StatelessWidget {
  const MotionSettle({super.key, required this.child, this.delay = Duration.zero, this.duration, this.curve, this.spring, this.from = 1.04});

  final Widget child;
  final Duration delay;
  final Duration? duration;
  final Curve? curve;
  final SpringDescription? spring;
  final double from;

  @override
  Widget build(BuildContext context) => MotionOnce(
        delay: delay,
        duration: duration ?? AppMotion.lg,
        curve: curve ?? AppMotion.out,
        spring: spring,
        child: child,
        builder: (context, t, child) => Opacity(
          opacity: _unit(t * 1.6),
          child: Transform.scale(scale: from + (1 - from) * t, child: child),
        ),
      );
}

enum MaskFrom { bottom, start, circle }

/// reveal_clip: a mask opens over [child] while the content drifts 8 px the
/// other way, so it reads as a reveal, not a loading bar.
class MotionMaskReveal extends StatelessWidget {
  const MotionMaskReveal({super.key, required this.child, this.from = MaskFrom.bottom, this.delay = Duration.zero, this.duration, this.curve});

  final Widget child;
  final MaskFrom from;
  final Duration delay;
  final Duration? duration;
  final Curve? curve;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.maybeOf(context) == TextDirection.rtl;
    return MotionOnce(
      delay: delay,
      duration: duration ?? AppMotion.lg,
      curve: curve ?? AppMotion.enter,
      child: child,
      builder: (context, t, child) {
        final v = _unit(t);
        final drift = (1 - v) * 8;
        return switch (from) {
          MaskFrom.circle => ClipOval(
              clipper: _CircleClip(v),
              child: Transform.scale(scale: 1.06 - 0.06 * v, child: child),
            ),
          MaskFrom.start => ClipRect(
              clipper: _EdgeClip(v, horizontal: true, rtl: rtl),
              child: Transform.translate(offset: Offset(rtl ? drift : -drift, 0), child: child),
            ),
          MaskFrom.bottom => ClipRect(
              clipper: _EdgeClip(v, horizontal: false, rtl: rtl),
              child: Transform.translate(offset: Offset(0, drift), child: child),
            ),
        };
      },
    );
  }
}

class _EdgeClip extends CustomClipper<Rect> {
  const _EdgeClip(this.t, {required this.horizontal, required this.rtl});
  final double t;
  final bool horizontal;
  final bool rtl;

  @override
  Rect getClip(Size s) {
    if (!horizontal) return Rect.fromLTRB(0, s.height * (1 - t), s.width, s.height);
    return rtl ? Rect.fromLTRB(s.width * (1 - t), 0, s.width, s.height) : Rect.fromLTRB(0, 0, s.width * t, s.height);
  }

  @override
  bool shouldReclip(_EdgeClip old) => old.t != t || old.horizontal != horizontal || old.rtl != rtl;
}

class _CircleClip extends CustomClipper<Rect> {
  const _CircleClip(this.t);
  final double t;

  @override
  Rect getClip(Size s) {
    final r = math.sqrt(s.width * s.width + s.height * s.height) / 2 * t;
    return Rect.fromCircle(center: s.center(Offset.zero), radius: r);
  }

  @override
  bool shouldReclip(_CircleClip old) => old.t != t;
}

/// stamp: lands from 1.15 with a hard stop — approved, paid, booked.
class MotionStamp extends StatelessWidget {
  const MotionStamp({super.key, required this.child, this.delay = Duration.zero, this.duration});

  final Widget child;
  final Duration delay;
  final Duration? duration;

  @override
  Widget build(BuildContext context) => MotionOnce(
        delay: delay,
        duration: duration ?? AppMotion.md,
        curve: AppMotion.popCurve,
        child: child,
        builder: (context, t, child) => Opacity(
          opacity: _unit(t * 3),
          child: Transform.scale(scale: 1.15 - 0.15 * t, child: child),
        ),
      );
}

/// blur (entrance): blurred → sharp while fading in (Focus Pull). On web and
/// under reduced motion it is a plain fade.
class MotionFocusIn extends StatelessWidget {
  const MotionFocusIn({super.key, required this.child, this.delay = Duration.zero, this.duration, this.sigma = 8});

  final Widget child;
  final Duration delay;
  final Duration? duration;
  final double sigma;

  @override
  Widget build(BuildContext context) => MotionOnce(
        delay: delay,
        duration: duration ?? AppMotion.lg,
        curve: AppMotion.out,
        child: child,
        builder: (context, t, child) {
          final v = _unit(t);
          final faded = Opacity(opacity: v, child: child);
          final s = sigma * (1 - v);
          if (kIsWeb || s < 0.05) return faded;
          return ImageFiltered(imageFilter: ui.ImageFilter.blur(sigmaX: s, sigmaY: s), child: faded);
        },
      );
}

// ───────────────────────────── feedback ─────────────────────────────

/// ring: a soft ring expands from the touch point; records [MotionOrigin].
/// The action fires on tap-up immediately — the ring never delays it.
class MotionTouchRing extends StatefulWidget {
  const MotionTouchRing({super.key, required this.child, required this.onTap, this.color, this.semanticLabel});

  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final String? semanticLabel;

  @override
  State<MotionTouchRing> createState() => _MotionTouchRingState();
}

class _MotionTouchRingState extends State<MotionTouchRing> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  Offset _at = Offset.zero;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _down(TapDownDetails d) {
    _at = d.localPosition;
    MotionOrigin.capture(context);
    _c.duration = AppMotion.resolve(context, AppMotion.md, essential: true);
    _c.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    final reduced = AppMotion.reduced(context);
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.onTap == null ? null : _down,
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _c,
          child: widget.child,
          builder: (context, child) => CustomPaint(
            foregroundPainter: _c.isAnimating
                ? _RingPainter(center: _at, t: AppMotion.out.transform(_c.value), color: color, grow: !reduced)
                : null,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.center, required this.t, required this.color, required this.grow});
  final Offset center;
  final double t;
  final Color color;
  final bool grow;

  @override
  void paint(Canvas canvas, Size size) {
    final maxR = size.longestSide * 0.6 + 12;
    final r = grow ? 8 + (maxR - 8) * t : maxR * 0.5;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = color.withValues(alpha: 0.45 * (1 - t));
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.drawCircle(center, r, p);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.t != t || old.center != center || old.color != color;
}

// ───────────────────────────── values ─────────────────────────────

/// roll: an odometer number; only the digits that change roll, up when the
/// number grows and down when it shrinks. Tabular figures, no width jitter.
class MotionRollingNumber extends StatefulWidget {
  const MotionRollingNumber({super.key, required this.value, this.style, this.format, this.duration});

  final num value;
  final TextStyle? style;
  final String Function(num value)? format;
  final Duration? duration;

  @override
  State<MotionRollingNumber> createState() => _MotionRollingNumberState();
}

class _MotionRollingNumberState extends State<MotionRollingNumber> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, value: 1);
  late String _old = _text(widget.value);
  bool _up = true;

  String _text(num v) => widget.format?.call(v) ?? '$v';

  @override
  void didUpdateWidget(MotionRollingNumber old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _old = _text(old.value);
      _up = widget.value >= old.value;
      _c.duration = AppMotion.resolve(context, widget.duration ?? AppMotion.md);
      if (_c.duration == Duration.zero) {
        _c.value = 1;
      } else {
        _c.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = (widget.style ?? DefaultTextStyle.of(context).style)
        .copyWith(fontFeatures: const [ui.FontFeature.tabularFigures()]);
    final now = _text(widget.value);
    final width = math.max(now.length, _old.length);
    final a = _old.padLeft(width);
    final b = now.padLeft(width);
    return Semantics(
      label: now,
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = AppMotion.out.transform(_c.value);
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < width; i++)
                if (a[i] == b[i] || t >= 1)
                  Text(b[i] == ' ' ? '' : b[i], style: style)
                else
                  ClipRect(
                    child: Stack(
                      children: [
                        FractionalTranslation(
                          translation: Offset(0, (_up ? -1 : 1) * t),
                          child: Opacity(opacity: 1 - t, child: Text(a[i], style: style)),
                        ),
                        FractionalTranslation(
                          translation: Offset(0, (_up ? 1 : -1) * (1 - t)),
                          child: Opacity(opacity: t, child: Text(b[i], style: style)),
                        ),
                      ],
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}

/// glide: a selection indicator travels between options instead of jumping.
class MotionSelectionGlide extends StatelessWidget {
  const MotionSelectionGlide({
    super.key,
    required this.selected,
    required this.children,
    this.indicator,
    this.height = 40,
  });

  final int selected;
  final List<Widget> children;
  final Decoration? indicator;
  final double height;

  @override
  Widget build(BuildContext context) {
    final n = children.length;
    final deco = indicator ??
        BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(height / 2),
        );
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth / math.max(1, n);
          return Stack(
            children: [
              AnimatedPositioned(
                duration: AppMotion.resolve(context, AppMotion.md),
                curve: AppMotion.out,
                left: w * selected.clamp(0, math.max(0, n - 1)),
                top: 0,
                bottom: 0,
                width: w,
                child: DecoratedBox(decoration: deco),
              ),
              Row(children: [for (final c in children) Expanded(child: Center(child: c))]),
            ],
          );
        },
      ),
    );
  }
}

/// flip: turns a card over in 3D. Reduced motion: a cross-fade.
class MotionFlip extends StatefulWidget {
  const MotionFlip({super.key, required this.front, required this.back, required this.flipped, this.duration});

  final Widget front;
  final Widget back;
  final bool flipped;
  final Duration? duration;

  @override
  State<MotionFlip> createState() => _MotionFlipState();
}

class _MotionFlipState extends State<MotionFlip> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, value: widget.flipped ? 1 : 0);

  @override
  void didUpdateWidget(MotionFlip old) {
    super.didUpdateWidget(old);
    if (old.flipped != widget.flipped) {
      _c.duration = widget.duration ?? AppMotion.lg;
      widget.flipped ? _c.forward() : _c.reverse();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduced(context)) {
      return AnimatedSwitcher(
        duration: AppMotion.sm,
        child: KeyedSubtree(key: ValueKey<bool>(widget.flipped), child: widget.flipped ? widget.back : widget.front),
      );
    }
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = AppMotion.inOut.transform(_c.value);
        final angle = t * math.pi;
        final showBack = angle > math.pi / 2;
        final shade = (math.sin(angle).abs() * 0.25).clamp(0.0, 0.25);
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0015)
            ..rotateY(angle),
          child: Stack(
            children: [
              if (showBack)
                Transform(alignment: Alignment.center, transform: Matrix4.rotationY(math.pi), child: widget.back)
              else
                widget.front,
              Positioned.fill(
                child: IgnorePointer(child: ColoredBox(color: Colors.black.withValues(alpha: shade))),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// tilt: the card tilts up to [maxDegrees] toward the finger and springs flat
/// on release. Vestibular: off under reduced motion.
class MotionTilt extends StatefulWidget {
  const MotionTilt({super.key, required this.child, this.onTap, this.maxDegrees = 8});

  final Widget child;
  final VoidCallback? onTap;
  final double maxDegrees;

  @override
  State<MotionTilt> createState() => _MotionTiltState();
}

class _MotionTiltState extends State<MotionTilt> with SingleTickerProviderStateMixin {
  late final AnimationController _back = AnimationController.unbounded(vsync: this);
  Offset _tilt = Offset.zero; // -1…1 on each axis
  Offset _from = Offset.zero;

  @override
  void initState() {
    super.initState();
    _back.addListener(_settleBack);
  }

  void _settleBack() {
    final k = (1 - _back.value).clamp(-0.2, 1.0);
    setState(() => _tilt = _from * k);
  }

  @override
  void dispose() {
    _back.dispose();
    super.dispose();
  }

  void _move(Offset local, Size size) {
    _back.stop();
    setState(() => _tilt = Offset((local.dx / size.width) * 2 - 1, (local.dy / size.height) * 2 - 1));
  }

  void _release() {
    _from = _tilt;
    _back.value = 0;
    _back.animateWith(SpringSimulation(AppMotion.springSmooth, 0, 1, 0));
  }

  @override
  Widget build(BuildContext context) {
    final tappable = widget.onTap == null
        ? widget.child
        : GestureDetector(
            onTapDown: (_) => MotionOrigin.capture(context),
            onTap: widget.onTap,
            child: widget.child,
          );
    if (AppMotion.reduced(context)) return tappable;
    final rad = widget.maxDegrees * math.pi / 180;
    return LayoutBuilder(
      builder: (context, box) {
        final size = Size(box.maxWidth.isFinite ? box.maxWidth : 300, box.maxHeight.isFinite ? box.maxHeight : 200);
        return Listener(
          onPointerDown: (e) => _move(e.localPosition, size),
          onPointerMove: (e) => _move(e.localPosition, size),
          onPointerUp: (_) => _release(),
          onPointerCancel: (_) => _release(),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateX(-_tilt.dy * rad)
              ..rotateY(_tilt.dx * rad),
            child: tappable,
          ),
        );
      },
    );
  }
}

/// pulse: a live indicator that breathes while [active]; stops after
/// [cycles] (0 = while active). Static halo under reduced motion. Tickers stop
/// off-screen through TickerMode.
class MotionPulse extends StatefulWidget {
  const MotionPulse({super.key, required this.child, this.active = true, this.cycles = 0, this.color});

  final Widget child;
  final bool active;
  final int cycles;
  final Color? color;

  @override
  State<MotionPulse> createState() => _MotionPulseState();
}

class _MotionPulseState extends State<MotionPulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: AppMotion.ms(1400));
  int _done = 0;

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        _done++;
        if (widget.active && (widget.cycles == 0 || _done < widget.cycles)) {
          _c.forward(from: 0);
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(MotionPulse old) {
    super.didUpdateWidget(old);
    if (old.active != widget.active) {
      _done = 0;
      _sync();
    }
  }

  void _sync() {
    if (widget.active && !AppMotion.reduced(context)) {
      if (!_c.isAnimating) _c.forward(from: 0);
    } else {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    final reduced = AppMotion.reduced(context);
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final t = Curves.easeInOutSine.transform(_c.value);
        final glow = !widget.active ? 0.0 : reduced ? 0.35 : 0.45 * math.sin(t * math.pi);
        return DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: color.withValues(alpha: glow), blurRadius: 4 + 10 * glow, spreadRadius: 6 * glow)],
          ),
          child: child,
        );
      },
    );
  }
}

/// morph_shape (inline): one container reshapes when [state] changes — size,
/// radius and colour interpolate, content cross-fades inside at the midpoint.
class MotionMorph extends StatelessWidget {
  const MotionMorph({super.key, required this.state, required this.child, this.decoration, this.duration, this.alignment = Alignment.center});

  final Object? state;
  final Widget child;
  final Decoration? decoration;
  final Duration? duration;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final d = AppMotion.resolve(context, duration ?? AppMotion.lg);
    final inner = AnimatedSize(
      duration: d,
      curve: AppMotion.sizeCurve,
      alignment: alignment,
      child: AnimatedSwitcher(
        duration: AppMotion.resolve(context, AppMotion.md, essential: true),
        switchInCurve: const Interval(0.3, 1, curve: Curves.easeOut),
        switchOutCurve: const Interval(0, 0.6, curve: Curves.easeIn),
        layoutBuilder: (current, previous) => Stack(
          alignment: alignment,
          children: [...previous, if (current != null) current],
        ),
        child: KeyedSubtree(key: ValueKey<Object?>(state), child: child),
      ),
    );
    if (decoration == null) return inner;
    return AnimatedContainer(duration: d, curve: AppMotion.standard, decoration: decoration, clipBehavior: Clip.antiAlias, child: inner);
  }
}

// ───────────────────────────── route transitions ─────────────────────────────

/// Every transition in tools/catalog.json → transitions. Generated routes
/// (motion_routes.g.dart) pick one per route from the plan's grammar.
enum MotionTransitionKind {
  platform, sharedAxisX, sharedAxisY, sharedAxisZ, fadeThrough, instant, crossfade, containerTransform,
  heroZoom, zoomFromCard, popFromTap, sheet, morph, revealCircle, fullBleedZoom, storyPage, pushBlur,
  slideUp, maskWipe,
}

abstract final class MotionTransitions {
  /// Overlays that leave the host visible behind them.
  static bool isOverlay(MotionTransitionKind k) =>
      k == MotionTransitionKind.sheet || k == MotionTransitionKind.popFromTap;

  static Duration duration(MotionTransitionKind k) => switch (k) {
        MotionTransitionKind.instant => Duration.zero,
        MotionTransitionKind.crossfade || MotionTransitionKind.popFromTap => AppMotion.md,
        MotionTransitionKind.sheet || MotionTransitionKind.slideUp => AppMotion.sheetDuration,
        _ => AppMotion.lg,
      };

  /// A route for Navigator.push. [origin] defaults to the last tap.
  static Route<T> route<T>(MotionTransitionKind kind, WidgetBuilder builder, {Rect? origin, RouteSettings? settings}) {
    if (kind == MotionTransitionKind.platform) {
      return MaterialPageRoute<T>(builder: builder, settings: settings);
    }
    final o = origin ?? MotionOrigin.take();
    final overlay = isOverlay(kind);
    return PageRouteBuilder<T>(
      settings: settings,
      opaque: !overlay,
      barrierDismissible: overlay,
      barrierColor: overlay ? Colors.black38 : null,
      barrierLabel: overlay ? 'Dismiss' : null,
      transitionDuration: duration(kind),
      reverseTransitionDuration: AppMotion.exit(duration(kind)),
      pageBuilder: (context, a, s) => builder(context),
      transitionsBuilder: (context, a, s, child) => build(context, kind, a, s, child, origin: o),
    );
  }

  /// The transition itself. The screen *behind* recedes (0.94, dimmed) while
  /// overlays and drill-downs arrive, so the app has depth.
  static Widget build(
    BuildContext context,
    MotionTransitionKind kind,
    Animation<double> animation,
    Animation<double> secondary,
    Widget child, {
    Rect? origin,
  }) {
    if (kind == MotionTransitionKind.instant) return child;
    if (AppMotion.reduced(context)) return FadeTransition(opacity: animation, child: child);
    final size = MediaQuery.sizeOf(context);
    final full = Offset.zero & size;
    final from = origin ?? Rect.fromCenter(center: full.center, width: size.width * 0.6, height: size.height * 0.3);
    final enter = CurvedAnimation(parent: animation, curve: AppMotion.enter, reverseCurve: AppMotion.exitCurve);
    final fadeIn = CurvedAnimation(parent: animation, curve: const Interval(0.25, 1, curve: Curves.easeOut));
    Alignment alignOf(Rect r) => Alignment(
          size.width == 0 ? 0 : (r.center.dx / size.width) * 2 - 1,
          size.height == 0 ? 0 : (r.center.dy / size.height) * 2 - 1,
        );

    final Widget arriving = switch (kind) {
      MotionTransitionKind.platform || MotionTransitionKind.instant => child,
      MotionTransitionKind.sharedAxisX => AppMotion.transition(context, PageMotion.sharedAxisX, animation, secondary, child),
      MotionTransitionKind.sharedAxisY => AppMotion.transition(context, PageMotion.sharedAxisY, animation, secondary, child),
      MotionTransitionKind.fadeThrough => AppMotion.transition(context, PageMotion.fadeThrough, animation, secondary, child),
      MotionTransitionKind.slideUp => AppMotion.transition(context, PageMotion.slideUp, animation, secondary, child),
      MotionTransitionKind.crossfade => FadeTransition(opacity: CurvedAnimation(parent: animation, curve: AppMotion.out), child: child),
      MotionTransitionKind.sharedAxisZ => FadeTransition(
          opacity: fadeIn,
          child: ScaleTransition(scale: Tween<double>(begin: 0.8, end: 1).animate(enter), child: child),
        ),
      MotionTransitionKind.heroZoom => FadeTransition(
          opacity: fadeIn,
          child: ScaleTransition(scale: Tween<double>(begin: 0.96, end: 1).animate(enter), child: child),
        ),
      MotionTransitionKind.fullBleedZoom => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: const Interval(0, 0.6, curve: Curves.easeOut)),
          child: ScaleTransition(scale: Tween<double>(begin: 1.08, end: 1).animate(enter), child: child),
        ),
      MotionTransitionKind.zoomFromCard => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: const Interval(0, 0.5, curve: Curves.easeOut)),
          child: ScaleTransition(
            alignment: alignOf(from),
            scale: Tween<double>(begin: math.min(0.9, from.width / math.max(1, size.width)), end: 1).animate(enter),
            child: child,
          ),
        ),
      MotionTransitionKind.popFromTap => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: const Interval(0, 0.4, curve: Curves.easeOut)),
          child: ScaleTransition(
            alignment: alignOf(from),
            scale: Tween<double>(begin: 0.6, end: 1).animate(CurvedAnimation(parent: animation, curve: AppMotion.popCurve, reverseCurve: AppMotion.exitCurve)),
            child: child,
          ),
        ),
      MotionTransitionKind.sheet => SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
              .animate(CurvedAnimation(parent: animation, curve: AppMotion.sheet, reverseCurve: AppMotion.exitCurve)),
          child: child,
        ),
      MotionTransitionKind.containerTransform || MotionTransitionKind.morph => AnimatedBuilder(
          animation: enter,
          child: child,
          builder: (context, child) {
            final t = enter.value;
            return ClipRRect(
              clipper: _RectClip(Rect.lerp(from, full, t)!, 24 * (1 - t)),
              child: FadeTransition(opacity: fadeIn, child: child),
            );
          },
        ),
      MotionTransitionKind.revealCircle => AnimatedBuilder(
          animation: enter,
          child: child,
          builder: (context, child) => ClipPath(clipper: _CirclePath(from.center, enter.value), child: child),
        ),
      MotionTransitionKind.maskWipe => AnimatedBuilder(
          animation: enter,
          child: child,
          builder: (context, child) => ClipRect(
            clipper: _EdgeClip(enter.value, horizontal: true, rtl: Directionality.maybeOf(context) == TextDirection.rtl),
            child: child,
          ),
        ),
      MotionTransitionKind.storyPage => SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(enter),
          child: child,
        ),
      MotionTransitionKind.pushBlur => SlideTransition(
          position: Tween<Offset>(begin: const Offset(0.15, 0), end: Offset.zero).animate(enter),
          child: FadeTransition(opacity: fadeIn, child: child),
        ),
    };
    return _recede(kind, secondary, arriving);
  }

  // The route underneath: shared-axis kinds already move it; the rest step back.
  static Widget _recede(MotionTransitionKind kind, Animation<double> secondary, Widget child) {
    switch (kind) {
      case MotionTransitionKind.sharedAxisX:
      case MotionTransitionKind.sharedAxisY:
      case MotionTransitionKind.fadeThrough:
      case MotionTransitionKind.platform:
      case MotionTransitionKind.instant:
      case MotionTransitionKind.crossfade:
        return child;
      default:
        final s = CurvedAnimation(parent: secondary, curve: AppMotion.standard);
        return AnimatedBuilder(
          animation: s,
          child: child,
          builder: (context, child) {
            final t = s.value;
            if (t == 0) return child!;
            final scale = 1 - 0.06 * t;
            Widget w = Transform.scale(scale: scale, child: child);
            if (kind == MotionTransitionKind.pushBlur && !kIsWeb) {
              w = ImageFiltered(imageFilter: ui.ImageFilter.blur(sigmaX: 6 * t, sigmaY: 6 * t), child: w);
            }
            if (kind == MotionTransitionKind.sharedAxisZ) {
              // Moving deeper: the old level grows past the camera and fades.
              return Opacity(opacity: 1 - t, child: Transform.scale(scale: 1 + 0.1 * t, child: child));
            }
            return ColorFiltered(
              colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.18 * t), BlendMode.srcATop),
              child: w,
            );
          },
        );
    }
  }
}

class _RectClip extends CustomClipper<RRect> {
  const _RectClip(this.rect, this.radius);
  final Rect rect;
  final double radius;

  @override
  RRect getClip(Size size) => RRect.fromRectAndRadius(rect, Radius.circular(radius));

  @override
  bool shouldReclip(_RectClip old) => old.rect != rect || old.radius != radius;
}

class _CirclePath extends CustomClipper<Path> {
  const _CirclePath(this.center, this.t);
  final Offset center;
  final double t;

  @override
  Path getClip(Size s) {
    final far = [Offset.zero, Offset(s.width, 0), Offset(0, s.height), Offset(s.width, s.height)]
        .map((c) => (c - center).distance)
        .reduce(math.max);
    return Path()..addOval(Rect.fromCircle(center: center, radius: far * t));
  }

  @override
  bool shouldReclip(_CirclePath old) => old.t != t || old.center != center;
}
