// FlutterGo motion presets — one of the 5,000 catalogue styles.
//
// The FlutterGo host picks a style for each new app from its idea and writes
// it to `motion_style.g.dart`. Every motion widget in `lib/motion/` reads it:
// durations, curves, how things enter, page transitions, press feedback,
// loading and the success moment. Feature code never sets these by hand.
// Catalogue: skills/fluttergo-motion-system/references/motion-styles.md

/// Overall speed. Scales every duration token.
enum MotionTempo { snappy, brisk, measured, relaxed, cinematic }

/// The easing family entrances and pops use.
enum MotionCurve { standard, expo, back, elastic, cubic, sine }

/// How content arrives (the default for `AppReveal`).
enum MotionEntrance { rise, fall, slideStart, slideEnd, grow, settle, tilt, wipe, fade }

/// How far content travels when it enters.
enum MotionTravel { subtle, medium, bold }

/// Gap between items in a staggered group.
enum MotionStagger { tight, normal, airy, cascade }

/// Page transition for routes (the default for `AppMotion.page`).
enum MotionPage { sharedAxisX, sharedAxisY, fadeThrough, slideUp, fade, zoom, parallax }

/// Press feedback for `AppPressable`.
enum MotionPress { shrink, deep, lift, dim, tilt }

/// Loading placeholder for `AppSkeleton`.
enum MotionLoading { shimmer, pulse, glint }

/// The completion moment for `AppSuccess`.
enum MotionSuccess { check, confetti, burst, stamp, ripple }

/// Haptics on taps and success.
enum MotionHaptics { none, light, rich }

/// Onboarding flow the agent writes (see screen-recipes.md).
enum MotionOnboarding { editorial, carousel, scene, fan, demo, welcome }

/// One complete motion style.
class MotionPreset {
  const MotionPreset({
    required this.id,
    required this.name,
    required this.mood,
    this.tempo = MotionTempo.measured,
    this.curve = MotionCurve.standard,
    this.entrance = MotionEntrance.rise,
    this.travel = MotionTravel.medium,
    this.stagger = MotionStagger.normal,
    this.page = MotionPage.fadeThrough,
    this.press = MotionPress.shrink,
    this.loading = MotionLoading.shimmer,
    this.success = MotionSuccess.check,
    this.haptics = MotionHaptics.light,
    this.onboarding = MotionOnboarding.editorial,
  });

  /// Catalogue id, e.g. `fgm-0417`.
  final String id;
  final String name;

  /// calm, playful, bold, premium, technical, warm, energetic, editorial,
  /// natural or futuristic.
  final String mood;
  final MotionTempo tempo;
  final MotionCurve curve;
  final MotionEntrance entrance;
  final MotionTravel travel;
  final MotionStagger stagger;
  final MotionPage page;
  final MotionPress press;
  final MotionLoading loading;
  final MotionSuccess success;
  final MotionHaptics haptics;
  final MotionOnboarding onboarding;
}
