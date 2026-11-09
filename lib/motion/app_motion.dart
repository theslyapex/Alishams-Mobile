// FlutterGo Motion System — tokens and page transitions.
//
// Feature code uses these tokens instead of hardcoded Duration(...) or
// Curves.* values, so every screen in the app moves the same way.
// See skills/fluttergo-motion-system/SKILL.md.

import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'motion_preset.dart';
import 'motion_style.g.dart';

export 'motion_preset.dart';

/// App-wide motion personality, chosen once in docs/app-plan.md.
enum MotionPersonality { calm, balanced, expressive }

/// Legacy feel switch. New apps get their feel from [AppMotion.preset] (the
/// host-picked catalogue style in motion_style.g.dart); setting this has no
/// effect on the motion widgets any more.
enum MotionStyle {
  /// Gentle fade with a short rise and a long soft landing (health, wellness,
  /// AI assistants, finance).
  soft,

  /// Bigger travel, overshoot and bounce (kids, pets, social, games, fun food).
  springy,

  /// Slow fades that settle from slightly zoomed in, never bounce (premium,
  /// fashion, travel, editorial, real estate).
  cinematic,

  /// Short, fast, precise moves with no overshoot (productivity, tools,
  /// fintech, B2B).
  crisp,
}

/// Intentional page transitions for go_router routes.
enum PageMotion { platform, sharedAxisX, sharedAxisY, fadeThrough, slideUp, fade, zoom, parallax }

abstract final class AppMotion {
  /// Set once in main() from the design direction.
  static MotionPersonality personality = MotionPersonality.balanced;

  /// Legacy; see [MotionStyle]. The feel comes from [preset].
  static MotionStyle style = MotionStyle.soft;

  /// This app's catalogue motion style, written by the FlutterGo host to
  /// `motion_style.g.dart`. Every token below reads it.
  static MotionPreset preset = appMotionPreset;

  /// Optional in-app "Reduce motion" setting; OR-ed with the OS flag.
  static bool appReduceMotion = false;

  static double get scale =>
      switch (preset.tempo) {
        MotionTempo.snappy => 0.75,
        MotionTempo.brisk => 0.88,
        MotionTempo.measured => 1.0,
        MotionTempo.relaxed => 1.2,
        MotionTempo.cinematic => 1.45,
      } *
      switch (personality) {
        MotionPersonality.calm => 1.0,
        MotionPersonality.balanced => 1.0,
        MotionPersonality.expressive => 1.1,
      };

  static Duration _d(int ms) => Duration(milliseconds: (ms * scale).round());

  // ── Durations ──────────────────────────────────────────────────────────
  static const Duration instant = Duration.zero;
  static Duration get xs => _d(100);
  static Duration get sm => _d(150);
  static Duration get md => _d(250);
  static Duration get lg => _d(350);
  static Duration get xl => _d(500);
  static Duration get sheetDuration => _d(520);
  static Duration get stagger => Duration(
        milliseconds: switch (preset.stagger) {
          MotionStagger.tight => 30,
          MotionStagger.normal => 45,
          MotionStagger.airy => 70,
          MotionStagger.cascade => 95,
        },
      );
  static const int maxStaggerItems = 8;
  static const Duration shimmer = Duration(milliseconds: 1300);
  static const Duration ambient = Duration(seconds: 6);

  /// Exits and reverse animations are ~25% shorter than enters.
  static Duration exit(Duration enter) => enter * 0.75;

  /// A storyboard beat or one-off length in milliseconds, scaled by this
  /// app's tempo. Use it for choreography (the delay before step 3, a 900 ms
  /// count-up) instead of `Duration(...)`, so the motion style and the
  /// preview's "Shuffle feel" reach it too.
  static Duration ms(int milliseconds) => _d(milliseconds);

  // ── Curves (Material 3 + two named extras) ─────────────────────────────
  // Overshoot rule: overshooting curves (pop, popCurve, and revealCurve on the
  // back / elastic styles) only ever drive scale or translate. Size, opacity,
  // colour, clip and painter progress use a non-overshoot token — enter,
  // exitCurve, standard, sheet, inOut, out, sizeCurve — or wrap the curve in
  // [clamped]. An overshoot on an AnimatedContainer width can go negative and
  // throw; on opacity it leaves 0…1 and asserts.
  static const Curve enter = Easing.emphasizedDecelerate;
  static const Curve exitCurve = Easing.emphasizedAccelerate;
  static const Curve standard = Easing.standard;
  static const Curve linear = Curves.linear;

  /// iOS-style sheet curve: fast start, long soft landing.
  static const Curve sheet = Cubic(0.32, 0.72, 0, 1);

  /// Small overshoot for pops (pins, badges, stars). Rare delight only.
  /// Scale / translate only — never size, opacity or colour.
  static const Curve pop = Curves.easeOutBack;

  // ── Preset-driven entrance feel (AppReveal, AppPressable, pages) ─────
  /// The style's entrance curve. Overshoots on the back / elastic styles:
  /// scale / translate only — for opacity use [enter] or [clamped].
  static Curve get revealCurve => switch (preset.curve) {
        MotionCurve.standard => Easing.emphasizedDecelerate,
        MotionCurve.expo => const Cubic(0.16, 1, 0.3, 1),
        MotionCurve.back => const Cubic(0.34, 1.56, 0.64, 1),
        MotionCurve.elastic => const Cubic(0.3, 1.8, 0.5, 1),
        MotionCurve.cubic => Curves.easeOutCubic,
        MotionCurve.sine => Curves.easeInOutSine,
      };

  /// Symmetric ease for progress-driven drawing (a route drawing itself, a
  /// clip growing): follows the style, never overshoots.
  static Curve get inOut => preset.curve == MotionCurve.sine ? Curves.easeInOutSine : Curves.easeInOutCubic;

  /// Decelerating ease with no overshoot, for values that must stay in 0…1
  /// (clip radii, painter progress, opacity).
  static Curve get out => preset.curve == MotionCurve.expo ? const Cubic(0.16, 1, 0.3, 1) : Curves.easeOutCubic;

  /// The style's pop. Overshoots on most styles (elastic strongly): scale /
  /// translate only — never size, opacity or colour.
  static Curve get popCurve => switch (preset.curve) {
        MotionCurve.standard => Curves.easeOutBack,
        MotionCurve.expo => const Cubic(0.16, 1, 0.3, 1),
        MotionCurve.back => Curves.easeOutBack,
        MotionCurve.elastic => const ElasticOutCurve(0.7),
        MotionCurve.cubic => Curves.easeOutCubic,
        MotionCurve.sine => Curves.easeInOutSine,
      };

  /// Size changes (AnimatedContainer / AnimatedSize width, height, radius,
  /// colour): follows the style's deceleration, never overshoots.
  static Curve get sizeCurve => out;

  /// [c] with its output held in 0…1, so any curve (even [popCurve]) can
  /// safely drive opacity, size or colour.
  static Curve clamped(Curve c) => _ClampedCurve(c);

  /// Entrance travel in logical pixels.
  static double get revealDistance => switch (preset.entrance) {
        MotionEntrance.fade || MotionEntrance.settle => 0,
        _ => switch (preset.travel) {
            MotionTravel.subtle => 12,
            MotionTravel.medium => 22,
            MotionTravel.bold => 36,
          },
      };

  /// Scale an entering element starts from (settle comes down from > 1).
  static double get revealScaleFrom => switch (preset.entrance) {
        MotionEntrance.grow => 0.9,
        MotionEntrance.settle => 1.06,
        _ => 1,
      };

  /// Scale a popping element starts from.
  static double get popScaleFrom => switch (preset.curve) {
        MotionCurve.elastic => 0.4,
        MotionCurve.back => 0.55,
        MotionCurve.standard => 0.7,
        _ => 0.82,
      };

  /// Multiplier on entrance durations for the preset.
  static double get revealDurationFactor =>
      switch (preset.entrance) {
        MotionEntrance.settle => 1.6,
        MotionEntrance.wipe => 1.4,
        MotionEntrance.tilt => 1.3,
        _ => 1.15,
      } +
      (preset.curve == MotionCurve.elastic || preset.curve == MotionCurve.back ? 0.2 : 0);

  /// Pressed scale for `AppPressable` (dim keeps 1 and fades instead).
  static double get pressScaleFor => switch (preset.press) {
        MotionPress.shrink => 0.97,
        MotionPress.deep => 0.93,
        MotionPress.lift => 1.03,
        MotionPress.dim => 1.0,
        MotionPress.tilt => 0.98,
      };

  /// Page transition routes use unless they ask for another.
  static PageMotion get defaultPage => switch (preset.page) {
        MotionPage.sharedAxisX => PageMotion.sharedAxisX,
        MotionPage.sharedAxisY => PageMotion.sharedAxisY,
        MotionPage.fadeThrough => PageMotion.fadeThrough,
        MotionPage.slideUp => PageMotion.slideUp,
        MotionPage.fade => PageMotion.fade,
        MotionPage.zoom => PageMotion.zoom,
        MotionPage.parallax => PageMotion.parallax,
      };

  // ── Springs (gesture settle) ───────────────────────────────────────────
  static final SpringDescription springSnappy =
      SpringDescription.withDampingRatio(mass: 1, stiffness: 600, ratio: 0.9);
  static final SpringDescription springSmooth =
      SpringDescription.withDampingRatio(mass: 1, stiffness: 300, ratio: 1.0);
  static final SpringDescription springBouncy =
      SpringDescription.withDampingRatio(mass: 1, stiffness: 400, ratio: 0.6);

  // ── Distance and scale ─────────────────────────────────────────────────
  static const double riseDistance = 16;
  static const double slidePage = 0.08; // fractional offset for shared-axis pages
  static const double pressScale = 0.97;
  static const double pressScaleIcon = 0.92;

  // ── Reduced motion ─────────────────────────────────────────────────────
  static bool reduced(BuildContext context) =>
      appReduceMotion || previewReduceMotion || (MediaQuery.maybeDisableAnimationsOf(context) ?? false);

  /// The FlutterGo web preview's "Reduce motion" switch loads the app with
  /// `?reduceMotion=1`. Read once at start-up; always false on devices.
  static final bool previewReduceMotion = _previewFlag();

  static bool _previewFlag() {
    try {
      return Uri.base.queryParameters['reduceMotion'] == '1';
    } catch (_) {
      return false;
    }
  }

  /// Duration given reduced motion: essential motion (state that would
  /// otherwise teleport) shrinks to [sm]; decorative motion becomes 0.
  static Duration resolve(BuildContext context, Duration d, {bool essential = false}) {
    if (!reduced(context)) return d;
    return essential ? sm : instant;
  }

  /// Overshooting curves become [standard] under reduced motion.
  static Curve curve(BuildContext context, Curve c) => reduced(context) ? standard : c;

  /// Delay for item [index] in a staggered list (capped at [maxStaggerItems]).
  static Duration staggerDelay(int index) =>
      stagger * (index < maxStaggerItems ? index : maxStaggerItems);

  // ── Platform page transitions (set on ThemeData) ───────────────────────
  static const PageTransitionsTheme pageTransitions = PageTransitionsTheme(
    builders: <TargetPlatform, PageTransitionsBuilder>{
      TargetPlatform.android: ZoomPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
    },
  );

  // ── go_router page helper ──────────────────────────────────────────────
  /// `GoRoute(pageBuilder: (c, s) => AppMotion.page(state: s, child: ...))`.
  /// Use on every route with no `motion:` so it plays the host-picked style's
  /// [defaultPage]; pass `motion:` only for an intentional exception.
  static Page<void> page({
    required GoRouterState state,
    required Widget child,
    PageMotion? motion,
    bool fullscreenDialog = false,
  }) {
    final m = motion ?? defaultPage;
    if (m == PageMotion.platform) {
      return MaterialPage<void>(
        key: state.pageKey,
        fullscreenDialog: fullscreenDialog,
        child: child,
      );
    }
    return CustomTransitionPage<void>(
      key: state.pageKey,
      fullscreenDialog: fullscreenDialog,
      transitionDuration: lg,
      reverseTransitionDuration: exit(lg),
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          transition(context, m, animation, secondaryAnimation, child),
    );
  }

  /// The transition used by [page]; also usable in a PageView or Navigator.
  static Widget transition(
    BuildContext context,
    PageMotion motion,
    Animation<double> animation,
    Animation<double> secondary,
    Widget child,
  ) {
    if (reduced(context)) return FadeTransition(opacity: animation, child: child);
    return switch (motion) {
      PageMotion.sharedAxisX => _sharedAxis(animation, secondary, child, Axis.horizontal),
      PageMotion.sharedAxisY => _sharedAxis(animation, secondary, child, Axis.vertical),
      PageMotion.fadeThrough => FadeTransition(
          opacity: animation.drive(
            CurveTween(curve: const Interval(0.35, 1.0, curve: Curves.easeOut)),
          ),
          child: ScaleTransition(
            scale: animation.drive(
              Tween<double>(begin: 0.92, end: 1.0).chain(CurveTween(curve: enter)),
            ),
            child: child,
          ),
        ),
      PageMotion.slideUp => SlideTransition(
          position: animation.drive(
            Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .chain(CurveTween(curve: sheet)),
          ),
          child: child,
        ),
      PageMotion.zoom => FadeTransition(
          opacity: animation.drive(CurveTween(curve: const Interval(0, 0.6, curve: Curves.easeOut))),
          child: ScaleTransition(
            scale: animation.drive(Tween<double>(begin: 0.85, end: 1.0).chain(CurveTween(curve: revealCurve))),
            child: ScaleTransition(
              scale: secondary.drive(Tween<double>(begin: 1.0, end: 1.06).chain(CurveTween(curve: standard))),
              child: child,
            ),
          ),
        ),
      PageMotion.parallax => SlideTransition(
          position: secondary.drive(
            Tween<Offset>(begin: Offset.zero, end: const Offset(-0.3, 0)).chain(CurveTween(curve: standard)),
          ),
          child: SlideTransition(
            position: animation.drive(
              Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).chain(CurveTween(curve: sheet)),
            ),
            child: child,
          ),
        ),
      PageMotion.fade || PageMotion.platform =>
        FadeTransition(opacity: animation, child: child),
    };
  }

  static Widget _sharedAxis(
    Animation<double> animation,
    Animation<double> secondary,
    Widget child,
    Axis axis,
  ) {
    Offset off(double v) => axis == Axis.horizontal ? Offset(v, 0) : Offset(0, v);
    return SlideTransition(
      position: secondary.drive(
        Tween<Offset>(begin: Offset.zero, end: off(-slidePage))
            .chain(CurveTween(curve: standard)),
      ),
      child: SlideTransition(
        position: animation.drive(
          Tween<Offset>(begin: off(slidePage), end: Offset.zero)
              .chain(CurveTween(curve: enter)),
        ),
        child: FadeTransition(
          opacity: animation.drive(
            CurveTween(curve: const Interval(0.3, 1.0, curve: Curves.easeOut)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _ClampedCurve extends Curve {
  const _ClampedCurve(this.parent);
  final Curve parent;

  @override
  double transformInternal(double t) => parent.transform(t).clamp(0.0, 1.0);
}
