// MotionSlot — fluttergo-motion-brain v1.3 runtime contract.
// Drop into lib/motion/ next to app_motion.dart, together with the generated
// motion_spec.g.dart (`python3 tools/motionctl.py gen design/motion_brain.json
// --dart lib/motion/motion_spec.g.dart`), and export it from motion.dart.
//
// Every element the brain planned is wrapped once in feature code:
//
//   MotionSlot('today.task_row', onTap: () => open(task), child: TaskRow(task))
//   MotionSlot('today.day_count', value: done, child: Text('$done of $total'))
//   MotionSlot('feed.post_photo', heroTag: 'photo-${post.id}', child: Photo(post))
//
// The slot reads the element's plan (role, motion, token, replay, reduced) and
// applies it with the existing lib/motion widgets — so the code cannot drift
// from design/motion_brain.json, and `motionctl inventory` can prove every
// planned element exists. An id that is not in the plan fails fast in debug.
//
// SIGNATURE, GRAPHIC and FEEDBACK slots are markers: their motion lives in the
// widget they wrap (a direction kit, AppStatusButton, AppConfetti…). ANCHOR
// slots never move. Timing always comes from AppMotion, so the host's motion
// style (motion_style.g.dart) still sets the feel.

import 'dart:async';

import 'package:flutter/widgets.dart';

import 'app_count_up.dart';
import 'app_fly_to.dart' show AppBump;
import 'app_kinetic_text.dart';
import 'app_motion.dart';
import 'app_pressable.dart';
import 'app_reveal.dart';
import 'app_text_motion.dart' show AppTypewriter;
import 'motion_recipes.dart';
import 'motion_spec.g.dart';

enum MotionRole { lead, follower, anchor, control, value, traveller, surface, signature, feedback, graphic }

enum MotionKind {
  none, reveal, rise, fade, pop, drop, slideIn, sheet, settle, press, squish, tint, bump, shake,
  crossfade, count, roll, draw, fill, progressLinear, collapse, expand, resize, hero, morphShape,
  revealClip, stamp, kinetic, shimmer, particles, blur, glass, shader, followDrag, parallax, scrollMorph,
  loopContent, typeOn, ring, glide, fly, reorder, tilt, flip, pulse, sequence,
}

enum MotionTrigger {
  enter, tap, longPress, drag, value, state, scroll, route, loop, insert, remove, error, success,
  loading, keyboard, none,
}

enum MotionDur { instant, xs, sm, md, lg, xl, sheet, style, ms }

enum MotionCurveToken { enter, exitCurve, standard, linear, sheet, inOut, out, sizeCurve, pop, revealCurve, popCurve, style }

enum MotionSpringToken { springSnappy, springSmooth, springBouncy }

enum MotionReduced { none, settled, crossfade, keepFeedback, staticCue }

enum MotionReplay { oncePerSession, oncePerVisit, everyTime }

/// One planned element, generated from design/motion_brain.json.
@immutable
class MotionSpec {
  const MotionSpec({
    required this.id,
    required this.screen,
    required this.role,
    required this.motion,
    this.trigger = MotionTrigger.none,
    this.duration = MotionDur.style,
    this.ms = 0,
    this.curve,
    this.spring,
    this.delayMs = 0,
    this.stagger = false,
    this.group,
    this.replay = MotionReplay.oncePerVisit,
    this.reduced = MotionReduced.none,
    this.signatureForm,
    this.deciding = false,
    this.loopCycles = 0,
  });

  final String id;
  final String screen;
  final MotionRole role;
  final MotionKind motion;
  final MotionTrigger trigger;
  final MotionDur duration;
  final int ms;
  final MotionCurveToken? curve;
  final MotionSpringToken? spring;
  final int delayMs;
  final bool stagger;
  final String? group;
  final MotionReplay replay;
  final MotionReduced reduced;
  final String? signatureForm;

  /// A value the user is deciding (amount, date, recipient): never animated by
  /// the slot; only the keystroke tint/cross-fade the plan allows.
  final bool deciding;

  /// From the plan's loop.stop `cycles:N` (0 = runs while its state lasts).
  final int loopCycles;

  /// Loops never settle; tests pump them for a fixed time instead.
  bool get loops =>
      motion == MotionKind.pulse || motion == MotionKind.loopContent ||
      motion == MotionKind.progressLinear || motion == MotionKind.shimmer;

  bool get moves => motion != MotionKind.none;
  bool get isEntrance =>
      moves && (trigger == MotionTrigger.enter || trigger == MotionTrigger.insert) &&
      (role == MotionRole.lead || role == MotionRole.follower);

  /// The planned duration from AppMotion, or null for "use the host style".
  Duration? get baseDuration => switch (duration) {
        MotionDur.instant => AppMotion.instant,
        MotionDur.xs => AppMotion.xs,
        MotionDur.sm => AppMotion.sm,
        MotionDur.md => AppMotion.md,
        MotionDur.lg => AppMotion.lg,
        MotionDur.xl => AppMotion.xl,
        MotionDur.sheet => AppMotion.sheetDuration,
        MotionDur.ms => AppMotion.ms(ms),
        MotionDur.style => null,
      };

  /// Duration with reduced motion applied: a planned cross-fade keeps
  /// AppMotion.sm, everything else becomes instant.
  Duration resolve(BuildContext context, {Duration? fallback}) => AppMotion.resolve(
        context,
        baseDuration ?? fallback ?? AppMotion.md,
        essential: reduced == MotionReduced.crossfade || reduced == MotionReduced.keepFeedback,
      );

  Curve get curveValue => switch (curve) {
        MotionCurveToken.enter => AppMotion.enter,
        MotionCurveToken.exitCurve => AppMotion.exitCurve,
        MotionCurveToken.standard => AppMotion.standard,
        MotionCurveToken.linear => AppMotion.linear,
        MotionCurveToken.sheet => AppMotion.sheet,
        MotionCurveToken.inOut => AppMotion.inOut,
        MotionCurveToken.out => AppMotion.out,
        MotionCurveToken.sizeCurve => AppMotion.sizeCurve,
        MotionCurveToken.pop => AppMotion.pop,
        MotionCurveToken.revealCurve => AppMotion.revealCurve,
        MotionCurveToken.popCurve => AppMotion.popCurve,
        MotionCurveToken.style || null => AppMotion.standard,
      };

  SpringDescription? get springValue => switch (spring) {
        MotionSpringToken.springSnappy => AppMotion.springSnappy,
        MotionSpringToken.springSmooth => AppMotion.springSmooth,
        MotionSpringToken.springBouncy => AppMotion.springBouncy,
        null => null,
      };
}

/// Wraps one planned element and applies its plan.
class MotionSlot extends StatefulWidget {
  const MotionSlot(
    this.id, {
    super.key,
    required this.child,
    this.onTap,
    this.value,
    this.index = 0,
    this.heroTag,
    this.semanticLabel,
    this.format,
  });

  /// `<screen>.<element>` id from design/motion_brain.json.
  final String id;
  final Widget child;

  /// CONTROL: the action. Press feedback comes from the plan.
  final VoidCallback? onTap;

  /// VALUE: the value whose change animates (cross-fade / bump).
  final Object? value;

  /// Position in a staggered group (FOLLOWER/LEAD with stagger).
  final int index;

  /// TRAVELLER: a unique tag per item (defaults to the id).
  final Object? heroTag;
  final String? semanticLabel;

  /// VALUE count/roll: how the number is written (`(v) => '\$${v.toStringAsFixed(2)}'`).
  final String Function(num value)? format;

  static final Set<String> _played = <String>{};

  /// Ids built in this run (debug builds only) — for coverage checks in tests.
  static final Set<String> debugBuilt = <String>{};

  static MotionSpec? specOf(String id) => motionSpecs[id];

  @visibleForTesting
  static void debugResetPlayed() {
    _played.clear();
    debugBuilt.clear();
  }

  @override
  State<MotionSlot> createState() => _MotionSlotState();
}

class _MotionSlotState extends State<MotionSlot> {
  bool _animateEntrance = true;

  @override
  void initState() {
    super.initState();
    final spec = motionSpecs[widget.id];
    if (spec != null && spec.isEntrance && spec.replay == MotionReplay.oncePerSession) {
      _animateEntrance = MotionSlot._played.add('${widget.id}#${widget.index}');
    }
  }

  /// Records where the tap happened so the next surface grows from it.
  void _tap() {
    MotionOrigin.capture(context);
    widget.onTap?.call();
  }

  Widget _count(MotionSpec spec, Text? text) => AppCountUp(
        value: widget.value! as num,
        duration: spec.baseDuration,
        curve: AppMotion.out,
        style: text?.style,
        format: widget.format == null ? null : (v) => widget.format!(v),
      );

  /// Kinds that behave the same for VALUE, SURFACE, CONTROL and FEEDBACK.
  Widget? _byKind(MotionSpec spec, Widget child) {
    switch (spec.motion) {
      case MotionKind.crossfade when spec.role != MotionRole.control:
        return AnimatedSwitcher(
          duration: spec.resolve(context, fallback: AppMotion.sm),
          switchInCurve: AppMotion.out,
          switchOutCurve: AppMotion.out,
          child: KeyedSubtree(key: ValueKey<Object?>(widget.value), child: child),
        );
      case MotionKind.bump:
        return AppBump(trigger: widget.value, child: child);
      case MotionKind.count when widget.value is num:
        return _count(spec, child is Text ? child : null);
      case MotionKind.roll when widget.value is num:
        return MotionRollingNumber(
          value: widget.value! as num,
          style: child is Text ? child.style : null,
          format: widget.format,
          duration: spec.baseDuration,
        );
      case MotionKind.expand || MotionKind.resize || MotionKind.collapse:
        return AnimatedSize(
          duration: spec.resolve(context, fallback: AppMotion.md),
          curve: AppMotion.sizeCurve,
          alignment: Alignment.topCenter,
          child: child,
        );
      case MotionKind.morphShape when spec.trigger != MotionTrigger.route:
        return MotionMorph(state: widget.value, duration: spec.baseDuration, child: child);
      case MotionKind.pulse:
        return MotionPulse(active: widget.value != false, cycles: spec.loopCycles, child: child);
      case MotionKind.tilt:
        return MotionTilt(onTap: widget.onTap == null ? null : _tap, child: child);
      case MotionKind.ring when widget.onTap != null:
        return MotionTouchRing(onTap: _tap, semanticLabel: widget.semanticLabel, child: child);
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final spec = motionSpecs[widget.id];
    assert(
      spec != null,
      'MotionSlot("${widget.id}") is not planned in design/motion_brain.json. '
      'Add the element (edit mode) and run `motionctl gen`.',
    );
    if (spec == null) return widget.child;
    assert(() {
      MotionSlot.debugBuilt.add(widget.id);
      return true;
    }());
    final child = widget.child;
    if (!spec.moves) return child;
    if (spec.deciding && spec.role != MotionRole.value) return child;

    if (spec.isEntrance) {
      if (!_animateEntrance) return child;
      final delay = spec.delayMs > 0 ? AppMotion.ms(spec.delayMs) : Duration.zero;
      final index = spec.stagger ? widget.index : 0;
      final start = delay + AppMotion.staggerDelay(index);
      final text = child is Text ? child : null;
      switch (spec.motion) {
        case MotionKind.fill || MotionKind.draw:
          // Bars and meters grow from their baseline (progress clamps 0…1, no overshoot).
          return _GrowIn(
            delay: start,
            duration: spec.baseDuration ?? AppMotion.md,
            curve: spec.curve == null ? AppMotion.standard : AppMotion.clamped(spec.curveValue),
            child: child,
          );
        case MotionKind.settle:
          return MotionSettle(delay: start, duration: spec.baseDuration, curve: spec.curve == null ? null : spec.curveValue, spring: spec.springValue, child: child);
        case MotionKind.revealClip:
          return MotionMaskReveal(delay: start, duration: spec.baseDuration, child: child);
        case MotionKind.stamp:
          return MotionStamp(delay: start, duration: spec.baseDuration, child: child);
        case MotionKind.blur:
          return MotionFocusIn(delay: start, duration: spec.baseDuration, child: child);
        case MotionKind.kinetic when text?.data != null:
          return AppKineticText(text!.data!, style: text.style, delay: start, textAlign: text.textAlign ?? TextAlign.start);
        case MotionKind.typeOn when text?.data != null:
          return AppTypewriter(text: text!.data!, style: text.style, delay: start);
        case MotionKind.count when widget.value is num:
          return AppReveal(style: RevealStyle.fade, delay: start, child: _count(spec, text));
        default:
          break;
      }
      final style = switch (spec.motion) {
        MotionKind.rise => RevealStyle.rise,
        MotionKind.fade || MotionKind.crossfade => RevealStyle.fade,
        MotionKind.pop => RevealStyle.pop,
        MotionKind.drop => RevealStyle.drop,
        MotionKind.slideIn => RevealStyle.slideIn,
        MotionKind.sheet => RevealStyle.sheet,
        _ => RevealStyle.auto,
      };
      return AppReveal(style: style, index: index, delay: delay, duration: spec.baseDuration, child: child);
    }

    // SIGNATURE / GRAPHIC slots are markers: their kit widget owns the motion.
    const markers = {MotionRole.signature, MotionRole.graphic, MotionRole.anchor, MotionRole.traveller};
    if (!markers.contains(spec.role)) {
      final w = _byKind(spec, child);
      if (w != null) return w;
    }

    switch (spec.role) {
      case MotionRole.control:
        return switch (spec.motion) {
          MotionKind.press => AppPressable(onTap: widget.onTap == null ? null : _tap, semanticLabel: widget.semanticLabel, child: child),
          MotionKind.squish => AppPressable(
              onTap: widget.onTap == null ? null : _tap,
              scale: AppMotion.pressScaleIcon,
              semanticLabel: widget.semanticLabel,
              child: child,
            ),
          MotionKind.tint => AppPressable(
              onTap: widget.onTap == null ? null : _tap,
              scale: 1,
              semanticLabel: widget.semanticLabel,
              child: child,
            ),
          _ => child,
        };
      case MotionRole.value:
        return child;
      case MotionRole.traveller:
        return Hero(tag: widget.heroTag ?? spec.id, child: child);
      case MotionRole.surface:
      case MotionRole.lead:
      case MotionRole.follower:
      case MotionRole.anchor:
      case MotionRole.signature:
      case MotionRole.feedback:
      case MotionRole.graphic:
        return child;
    }
  }
}

/// Grows [child] from its bottom edge once (scaleY 0 → 1). Reduced motion: shown at once.
class _GrowIn extends StatefulWidget {
  const _GrowIn({required this.delay, required this.duration, required this.curve, required this.child});

  final Duration delay;
  final Duration duration;
  final Curve curve;
  final Widget child;

  @override
  State<_GrowIn> createState() => _GrowInState();
}

class _GrowInState extends State<_GrowIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration);
  Timer? _timer;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (AppMotion.reduced(context)) {
      _c.value = 1;
    } else if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      _timer = Timer(widget.delay, () {
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
    final grow = _c.drive(CurveTween(curve: widget.curve));
    return AnimatedBuilder(
      animation: grow,
      child: widget.child,
      builder: (context, child) => Transform(
        alignment: Alignment.bottomCenter,
        transform: Matrix4.diagonal3Values(1, grow.value, 1),
        child: child,
      ),
    );
  }
}
