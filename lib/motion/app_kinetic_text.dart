import 'dart:async';
import 'package:flutter/widgets.dart';

import 'app_motion.dart';

/// How each word (or character) of [AppKineticText] arrives.
enum KineticStyle {
  /// Fades in and rises half a line. Headlines, onboarding titles.
  rise,

  /// Each word is revealed left to right, like ink. Editorial, premium.
  wipe,

  /// Each word scales up from 60% as it fades in. Playful, bold.
  scaleIn,

  /// Each word rolls up into its line like a slot reel. Numbers, launches.
  slot,
}

/// Kinetic typography: [text] arrives word by word (or character by
/// character with [byChar]), staggered with this app's [AppMotion.stagger].
///
/// For headlines and hero statements only — one per screen at most, never
/// body copy. The first 12 pieces are staggered; the rest arrive together so
/// long text never makes the reader wait. Plays once; give it a new [Key] to
/// replay. Screen readers get the whole string as one label.
/// Reduced motion: the full text is shown immediately.
///
/// ```dart
/// AppKineticText('Find your next trail', style: t.displaySmall, kinetic: KineticStyle.rise)
/// ```
class AppKineticText extends StatefulWidget {
  const AppKineticText(
    this.text, {
    super.key,
    this.style,
    this.kinetic = KineticStyle.rise,
    this.byChar = false,
    this.delay = Duration.zero,
    this.textAlign = TextAlign.start,
    this.onDone,
  });

  final String text;
  final TextStyle? style;
  final KineticStyle kinetic;

  /// Animate each character instead of each word (short words only: a
  /// number, a brand name).
  final bool byChar;
  final Duration delay;
  final TextAlign textAlign;
  final VoidCallback? onDone;

  @override
  State<AppKineticText> createState() => _AppKineticTextState();
}

class _AppKineticTextState extends State<AppKineticText> with SingleTickerProviderStateMixin {
  static const int _maxStaggered = 12;

  late final AnimationController _c = AnimationController(vsync: this);

  Timer? _delay;
  bool _started = false;

  List<String> get _words => widget.text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

  int get _pieceCount =>
      widget.byChar ? _words.fold<int>(0, (n, w) => n + w.characters.length) : _words.length;

  Duration get _piece => AppMotion.lg * AppMotion.revealDurationFactor;

  Duration _startOf(int i) => AppMotion.stagger * (i < _maxStaggered ? i : _maxStaggered);

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone?.call();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (AppMotion.reduced(context)) {
      _c.value = 1;
      return;
    }
    final n = _pieceCount;
    _c.duration = _startOf(n <= 0 ? 0 : n - 1) + _piece;
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      _delay = Timer(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _delay?.cancel();
    _c.dispose();
    super.dispose();
  }

  WrapAlignment get _wrapAlignment => switch (widget.textAlign) {
        TextAlign.center => WrapAlignment.center,
        TextAlign.right || TextAlign.end => WrapAlignment.end,
        _ => WrapAlignment.start,
      };

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style.merge(widget.style);
    final fontSize = style.fontSize ?? 14;
    final total = _c.duration ?? Duration.zero;
    final words = _words;

    int index = 0;
    final children = <Widget>[];
    for (final word in words) {
      if (widget.byChar) {
        final chars = <Widget>[];
        for (final ch in word.characters) {
          chars.add(_buildPiece(ch, index++, total, style, fontSize));
        }
        children.add(Row(mainAxisSize: MainAxisSize.min, children: chars));
      } else {
        children.add(_buildPiece(word, index++, total, style, fontSize));
      }
    }

    return Semantics(
      label: widget.text,
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: Wrap(
            alignment: _wrapAlignment,
            spacing: fontSize * 0.28,
            children: children,
          ),
        ),
      ),
    );
  }

  Widget _buildPiece(String text, int i, Duration total, TextStyle style, double fontSize) {
    final totalMs = total.inMicroseconds;
    final Interval interval;
    if (totalMs <= 0) {
      interval = const Interval(0, 1);
    } else {
      final begin = _startOf(i).inMicroseconds / totalMs;
      final end = (_startOf(i) + _piece).inMicroseconds / totalMs;
      interval = Interval(begin.clamp(0.0, 1.0), end.clamp(0.0, 1.0));
    }
    final label = Text(text, style: style);
    final moving = AnimatedBuilder(
      animation: _c,
      child: label,
      builder: (context, child) {
        final t = interval.transform(_c.value);
        if (t >= 1) return child!;
        final v = AppMotion.revealCurve.transform(t);
        switch (widget.kinetic) {
          case KineticStyle.rise:
            return Transform.translate(offset: Offset(0, fontSize * 0.5 * (1 - v)), child: child);
          case KineticStyle.wipe:
            return ClipRect(
              clipper: _HorizontalWipe(AppMotion.out.transform(t)),
              child: child,
            );
          case KineticStyle.scaleIn:
            return Transform.scale(scale: 0.6 + 0.4 * v, child: child);
          case KineticStyle.slot:
            return Transform.translate(offset: Offset(0, fontSize * 1.2 * (1 - v)), child: child);
        }
      },
    );
    if (widget.kinetic == KineticStyle.wipe) return moving;
    // Fade on the controller (FadeTransition), not an `Opacity` rebuilt per frame.
    final faded = FadeTransition(
      opacity: _c.drive(CurveTween(curve: interval)).drive(CurveTween(curve: const Interval(0, 0.6))),
      child: moving,
    );
    return widget.kinetic == KineticStyle.slot ? ClipRect(child: faded) : faded;
  }
}

/// Shows the start of its child up to [t] of its width (RTL-agnostic: words
/// are short, so a left-to-right ink reveal reads fine either way).
class _HorizontalWipe extends CustomClipper<Rect> {
  _HorizontalWipe(this.t);
  final double t;

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, -size.height, size.width * t, size.height * 3);

  @override
  bool shouldReclip(_HorizontalWipe old) => old.t != t;
}
