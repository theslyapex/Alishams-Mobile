import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show PathMetric;

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import 'app_motion.dart';

/// What [AppBrandMark] does with the app's logo shape.
enum BrandMarkMode {
  /// The outline draws itself, then the shape fills in. Splash, welcome.
  draw,

  /// A highlight travels around the outline, forever. Loading.
  loader,

  /// The mark draws, then pops with this app's pop curve and a haptic.
  /// Order placed, booking confirmed.
  success,
}

/// The app's logo shape drives its motion: splash (draw), loading (loader),
/// pull-to-refresh ([AppBrandRefresh]) and the completion moment (success).
/// One shape, four moments — so no two FlutterGo apps share a loader.
///
/// Give it the logo as SVG path data (one `d` attribute; M L H V C Q Z,
/// absolute and relative — arcs and S/T shorthands are skipped):
/// ```dart
/// const kLogo = 'M12 2 L22 20 H2 Z';
/// AppBrandMark.fromSvgPath(kLogo, color: scheme.primary, size: 96)             // splash
/// AppBrandMark.fromSvgPath(kLogo, color: scheme.primary, mode: BrandMarkMode.loader)
/// ```
/// or as a builder: `AppBrandMark(path: (size) => myPath(size), …)`.
///
/// Reduced motion: draw and success show the finished mark; the loader shows
/// the filled mark standing still.
class AppBrandMark extends StatefulWidget {
  const AppBrandMark({
    super.key,
    required this.path,
    this.color,
    this.size = 64,
    this.mode = BrandMarkMode.draw,
    this.strokeWidth,
    this.progress,
    this.delay = Duration.zero,
    this.onDone,
    this.semanticLabel,
  });

  AppBrandMark.fromSvgPath(
    String svgPathData, {
    super.key,
    this.color,
    this.size = 64,
    this.mode = BrandMarkMode.draw,
    this.strokeWidth,
    this.progress,
    this.delay = Duration.zero,
    this.onDone,
    this.semanticLabel,
  }) : path = brandPathFromSvg(svgPathData);

  /// Builds the logo outline inside a square of the given size.
  final Path Function(Size size) path;

  /// Outline and fill; defaults to the theme's `colorScheme.primary`.
  final Color? color;

  /// Width and height of the mark.
  final double size;
  final BrandMarkMode mode;

  /// Outline width while drawing (defaults to 4% of [size], min 1.5).
  final double? strokeWidth;

  /// Drive the draw by hand (0–1) instead of a timer — used by
  /// [AppBrandRefresh] while the user pulls. Only for [BrandMarkMode.draw].
  final double? progress;
  final Duration delay;

  /// Called when draw / success finish (never for the loader).
  final VoidCallback? onDone;
  final String? semanticLabel;

  @override
  State<AppBrandMark> createState() => _AppBrandMarkState();
}

class _AppBrandMarkState extends State<AppBrandMark> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  _MarkGeometry? _geometry;
  bool _started = false;
  bool _reduced = false;
  // onDone fires once per run (reduced motion sets value = 1, which also
  // reports "completed").
  bool _doneFired = false;
  Timer? _delay;

  double get _stroke => widget.strokeWidth ?? math.max(1.5, widget.size * 0.04);

  @override
  void initState() {
    super.initState();
    _c.addStatusListener(_onStatus);
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || widget.mode == BrandMarkMode.loader) return;
    _finished();
  }

  void _finished() {
    if (_doneFired) return;
    _doneFired = true;
    if (widget.mode == BrandMarkMode.success) {
      final haptics = AppMotion.preset.haptics;
      if (haptics == MotionHaptics.rich) {
        HapticFeedback.mediumImpact();
      } else if (haptics == MotionHaptics.light) {
        HapticFeedback.lightImpact();
      }
    }
    widget.onDone?.call();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = AppMotion.reduced(context);
    if (_started) return;
    _started = true;
    _start();
  }

  @override
  void didUpdateWidget(AppBrandMark old) {
    super.didUpdateWidget(old);
    if (old.path != widget.path || old.size != widget.size) _geometry = null;
    if (old.mode != widget.mode || (old.progress == null) != (widget.progress == null)) _start();
  }

  void _start() {
    _c.stop();
    _delay?.cancel();
    _doneFired = false;
    if (widget.progress != null) return;
    switch (widget.mode) {
      case BrandMarkMode.loader:
        if (_reduced) {
          _c.value = 0;
          return;
        }
        _c.duration = AppMotion.xl * 2.8;
        _c.repeat();
      case BrandMarkMode.draw:
      case BrandMarkMode.success:
        if (_reduced) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _finished();
          });
          _c.value = 1;
          return;
        }
        _c.duration = widget.mode == BrandMarkMode.draw ? AppMotion.xl * 2.2 : AppMotion.xl * 2;
        if (widget.delay == Duration.zero) {
          _c.forward(from: 0);
        } else {
          _c.value = 0;
          _delay = Timer(widget.delay, () {
            if (mounted && widget.progress == null) _c.forward(from: 0);
          });
        }
    }
  }

  _MarkGeometry _geometryFor(Size size) {
    final cached = _geometry;
    if (cached != null && cached.size == size) return cached;
    final inset = _stroke;
    final inner = Size(math.max(0, size.width - inset * 2), math.max(0, size.height - inset * 2));
    final raw = widget.path(inner).shift(Offset(inset, inset));
    return _geometry = _MarkGeometry(size, raw);
  }

  @override
  void dispose() {
    _delay?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget mark = RepaintBoundary(
      child: CustomPaint(
        size: Size.square(widget.size),
        painter: _BrandPainter(
          animation: _c,
          geometryFor: _geometryFor,
          color: widget.color ?? Theme.of(context).colorScheme.primary,
          strokeWidth: _stroke,
          mode: widget.mode,
          progress: widget.progress,
          reduced: _reduced,
        ),
      ),
    );
    if (widget.semanticLabel != null) {
      mark = Semantics(label: widget.semanticLabel, image: true, child: mark);
    }
    return mark;
  }
}

class _MarkGeometry {
  factory _MarkGeometry(Size size, Path path) {
    final List<PathMetric> metrics = path.computeMetrics().toList();
    var total = 0.0;
    for (final PathMetric m in metrics) {
      total += m.length;
    }
    return _MarkGeometry._(size, path, metrics, total);
  }

  _MarkGeometry._(this.size, this.path, this.metrics, this.total);

  final Size size;
  final Path path;
  final List<PathMetric> metrics;
  final double total;
}

class _BrandPainter extends CustomPainter {
  _BrandPainter({
    required this.animation,
    required this.geometryFor,
    required this.color,
    required this.strokeWidth,
    required this.mode,
    required this.progress,
    required this.reduced,
  }) : super(repaint: animation);

  final Animation<double> animation;
  final _MarkGeometry Function(Size) geometryFor;
  final Color color;
  final double strokeWidth;
  final BrandMarkMode mode;
  final double? progress;
  final bool reduced;

  Paint _strokePaint(double alpha) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeWidth
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = color.withValues(alpha: color.a * alpha);

  Paint _fillPaint(double alpha) => Paint()
    ..style = PaintingStyle.fill
    ..color = color.withValues(alpha: color.a * alpha);

  /// Each contour drawn from its start to [fraction] of its length.
  void _drawPartial(Canvas canvas, _MarkGeometry g, double fraction, Paint paint) {
    if (fraction <= 0) return;
    if (fraction >= 1) {
      canvas.drawPath(g.path, paint);
      return;
    }
    for (final m in g.metrics) {
      canvas.drawPath(m.extractPath(0, m.length * fraction), paint);
    }
  }

  /// The outline between [from] and [to] (in total length, may wrap).
  void _drawRange(Canvas canvas, _MarkGeometry g, double from, double to, Paint paint) {
    final total = g.total;
    if (total <= 0) return;
    final ranges = <List<double>>[
      [from, math.min(to, total)],
      if (to > total) [0, to - total],
    ];
    var offset = 0.0;
    for (final m in g.metrics) {
      final start = offset;
      final end = offset + m.length;
      for (final r in ranges) {
        final a = math.max(r[0], start);
        final b = math.min(r[1], end);
        if (b > a) canvas.drawPath(m.extractPath(a - start, b - start), paint);
      }
      offset = end;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final g = geometryFor(size);
    final t = progress ?? animation.value;

    switch (mode) {
      case BrandMarkMode.draw:
        if (progress != null) {
          // Pulled by hand: outline only, proportional to the pull.
          _drawPartial(canvas, g, t, _strokePaint(1));
          return;
        }
        _drawPartial(canvas, g, AppMotion.inOut.transform(const Interval(0, 0.75).transform(t)), _strokePaint(1));
        final fill = AppMotion.out.transform(const Interval(0.6, 1).transform(t));
        if (fill > 0) canvas.drawPath(g.path, _fillPaint(fill));
      case BrandMarkMode.loader:
        if (reduced) {
          canvas.drawPath(g.path, _fillPaint(1));
          return;
        }
        canvas.drawPath(g.path, _strokePaint(0.22));
        final start = t * g.total;
        _drawRange(canvas, g, start, start + g.total * 0.28, _strokePaint(1));
      case BrandMarkMode.success:
        final u = const Interval(0.55, 1).transform(t);
        final scale = 0.85 + 0.15 * AppMotion.popCurve.transform(u);
        final center = size.center(Offset.zero);
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.scale(scale);
        canvas.translate(-center.dx, -center.dy);
        _drawPartial(canvas, g, AppMotion.inOut.transform(const Interval(0, 0.5).transform(t)), _strokePaint(1));
        final fill = const Interval(0.4, 0.65).transform(t);
        if (fill > 0) canvas.drawPath(g.path, _fillPaint(fill));
        canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_BrandPainter old) =>
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.mode != mode ||
      old.progress != progress ||
      old.reduced != reduced ||
      old.geometryFor != geometryFor;
}

/// Pull-to-refresh that draws the app's logo as the user pulls, then runs the
/// logo loader until [onRefresh] completes. Replaces RefreshIndicator.
///
/// ```dart
/// AppBrandRefresh(
///   mark: AppBrandMark.fromSvgPath(kLogo, color: scheme.primary),
///   onRefresh: _reload,
///   child: ListView(physics: const AlwaysScrollableScrollPhysics(), children: ...),
/// )
/// ```
/// The scroll view must be scrollable even when short —
/// `AlwaysScrollableScrollPhysics()` — or a short list can't be pulled.
class AppBrandRefresh extends StatefulWidget {
  const AppBrandRefresh({
    super.key,
    required this.mark,
    required this.onRefresh,
    required this.child,
    this.triggerDistance = 80,
    this.indicatorSize = 32,
    this.backgroundColor,
  });

  /// The logo to draw — only its path and color are used.
  final AppBrandMark mark;
  final Future<void> Function() onRefresh;
  final Widget child;

  /// Pull distance (logical pixels) that triggers a refresh.
  final double triggerDistance;
  final double indicatorSize;

  /// Disc behind the mark; defaults to the theme's `colorScheme.surface`.
  final Color? backgroundColor;

  @override
  State<AppBrandRefresh> createState() => _AppBrandRefreshState();
}

class _AppBrandRefreshState extends State<AppBrandRefresh> {
  final ValueNotifier<double> _pull = ValueNotifier<double>(0);
  final ValueNotifier<bool> _refreshing = ValueNotifier<bool>(false);
  // Indicator opacity as an Animation, so it fades through FadeTransition
  // instead of an `Opacity` widget rebuilt on every pull frame.
  late final Animation<double> _fade = _ListenableValue(
    Listenable.merge([_pull, _refreshing]),
    () => _refreshing.value ? 1.0 : math.max(0.25, (_pull.value / widget.triggerDistance).clamp(0.0, 1.0)),
  );
  bool _armed = false;
  bool _crossed = false;

  void _setPull(double value) {
    final v = value.clamp(0.0, widget.triggerDistance * 1.5);
    if (!_crossed && v >= widget.triggerDistance) {
      _crossed = true;
      HapticFeedback.selectionClick();
    }
    _pull.value = v;
  }

  bool _onNotification(ScrollNotification n) {
    if (n.depth != 0 || _refreshing.value) return false;
    if (n is ScrollStartNotification) {
      _armed = n.dragDetails != null && n.metrics.extentBefore == 0;
      _crossed = false;
    } else if (n is OverscrollNotification) {
      // Clamping physics (Android): the list stays put and reports overscroll.
      if (_armed && n.dragDetails != null && n.overscroll < 0) _setPull(_pull.value - n.overscroll);
    } else if (n is ScrollUpdateNotification) {
      if (!_armed) return false;
      if (n.dragDetails == null) {
        // Finger lifted, the list is settling: decide now.
        _release();
      } else if (n.metrics.pixels < n.metrics.minScrollExtent) {
        // Bouncing physics (iOS): the list itself is pulled past the top.
        _setPull(n.metrics.minScrollExtent - n.metrics.pixels);
      } else if (n.metrics.pixels > n.metrics.minScrollExtent) {
        _armed = false;
        _setPull(0);
      }
    } else if (n is ScrollEndNotification) {
      if (_armed) _release();
    }
    return false;
  }

  void _release() {
    _armed = false;
    if (_pull.value >= widget.triggerDistance) {
      _refresh();
    } else {
      _pull.value = 0;
    }
  }

  Future<void> _refresh() async {
    _refreshing.value = true;
    _pull.value = widget.triggerDistance;
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        _refreshing.value = false;
        _pull.value = 0;
      }
    }
  }

  @override
  void dispose() {
    _pull.dispose();
    _refreshing.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = AppMotion.reduced(context);
    return Stack(
      children: [
        NotificationListener<ScrollNotification>(onNotification: _onNotification, child: widget.child),
        PositionedDirectional(
          top: 0,
          start: 0,
          end: 0,
          child: IgnorePointer(
            child: ListenableBuilder(
              listenable: Listenable.merge([_pull, _refreshing]),
              builder: (context, _) {
                final pull = _pull.value;
                final refreshing = _refreshing.value;
                if (pull <= 0 && !refreshing) return const SizedBox.shrink();
                final progress = (pull / widget.triggerDistance).clamp(0.0, 1.0);
                final dy = reduce ? 16.0 : 8 + math.min(pull, widget.triggerDistance) * 0.6;
                final mark = refreshing
                    ? AppBrandMark(
                        key: const ValueKey('brand-refresh-loading'),
                        path: widget.mark.path,
                        color: widget.mark.color,
                        size: widget.indicatorSize,
                        mode: BrandMarkMode.loader,
                      )
                    : AppBrandMark(
                        key: const ValueKey('brand-refresh-pull'),
                        path: widget.mark.path,
                        color: widget.mark.color,
                        size: widget.indicatorSize,
                        progress: progress,
                      );
                return Transform.translate(
                  offset: Offset(0, dy),
                  child: Center(
                    child: FadeTransition(
                      opacity: _fade,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: widget.backgroundColor ?? Theme.of(context).colorScheme.surface,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.14),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(padding: const EdgeInsets.all(8), child: mark),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// A read-only [Animation] over any [Listenable] (here: the pull distance), so
/// gesture-driven values can feed `FadeTransition` and friends.
class _ListenableValue extends Animation<double> {
  _ListenableValue(this._source, this._read);

  final Listenable _source;
  final double Function() _read;

  @override
  double get value => _read();

  @override
  AnimationStatus get status => AnimationStatus.forward;

  @override
  void addListener(VoidCallback listener) => _source.addListener(listener);

  @override
  void removeListener(VoidCallback listener) => _source.removeListener(listener);

  @override
  void addStatusListener(AnimationStatusListener listener) {}

  @override
  void removeStatusListener(AnimationStatusListener listener) {}
}

/// Parses SVG path data once and returns a builder that fits it, centred and
/// aspect-preserving, into any square.
Path Function(Size size) brandPathFromSvg(String svgPathData) {
  final raw = parseSvgPathData(svgPathData);
  return (size) => fitPathToSize(raw, size);
}

/// Scales [source] uniformly so its bounds fit [size], centred.
Path fitPathToSize(Path source, Size size) {
  final b = source.getBounds();
  if (b.isEmpty && b.width == 0 && b.height == 0) return source;
  final s = math.min(size.width / math.max(b.width, 1e-6), size.height / math.max(b.height, 1e-6));
  final dx = (size.width - b.width * s) / 2 - b.left * s;
  final dy = (size.height - b.height * s) / 2 - b.top * s;
  return source.transform(Float64List.fromList(<double>[s, 0, 0, 0, 0, s, 0, 0, 0, 0, 1, 0, dx, dy, 0, 1]));
}

final RegExp _svgToken = RegExp(r'[MmLlHhVvCcQqZzAaSsTt]|[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?');

/// Minimal SVG path-data parser: M L H V C Q Z (absolute and relative).
/// Unsupported commands (A, S, T) and malformed groups are skipped.
Path parseSvgPathData(String d) {
  final path = Path();
  final tokens = _svgToken.allMatches(d).map((m) => m.group(0)!).toList();
  bool isCommand(String t) => t.length == 1 && RegExp('[A-Za-z]').hasMatch(t);

  var i = 0;
  var cmd = 'M';
  var x = 0.0, y = 0.0, startX = 0.0, startY = 0.0;

  int available() {
    var n = 0;
    while (i + n < tokens.length && !isCommand(tokens[i + n])) {
      n++;
    }
    return n;
  }

  double next() => double.parse(tokens[i++]);

  while (i < tokens.length) {
    if (isCommand(tokens[i])) cmd = tokens[i++];
    final rel = cmd == cmd.toLowerCase();
    switch (cmd.toUpperCase()) {
      case 'M':
        if (available() >= 2) {
          var nx = next(), ny = next();
          if (rel) {
            nx += x;
            ny += y;
          }
          path.moveTo(nx, ny);
          x = startX = nx;
          y = startY = ny;
          // Extra pairs after a moveto are linetos.
          cmd = rel ? 'l' : 'L';
          while (available() >= 2) {
            var lx = next(), ly = next();
            if (rel) {
              lx += x;
              ly += y;
            }
            path.lineTo(lx, ly);
            x = lx;
            y = ly;
          }
        }
      case 'L':
        while (available() >= 2) {
          var nx = next(), ny = next();
          if (rel) {
            nx += x;
            ny += y;
          }
          path.lineTo(nx, ny);
          x = nx;
          y = ny;
        }
      case 'H':
        while (available() >= 1) {
          var nx = next();
          if (rel) nx += x;
          path.lineTo(nx, y);
          x = nx;
        }
      case 'V':
        while (available() >= 1) {
          var ny = next();
          if (rel) ny += y;
          path.lineTo(x, ny);
          y = ny;
        }
      case 'C':
        while (available() >= 6) {
          var x1 = next(), y1 = next(), x2 = next(), y2 = next(), nx = next(), ny = next();
          if (rel) {
            x1 += x;
            y1 += y;
            x2 += x;
            y2 += y;
            nx += x;
            ny += y;
          }
          path.cubicTo(x1, y1, x2, y2, nx, ny);
          x = nx;
          y = ny;
        }
      case 'Q':
        while (available() >= 4) {
          var x1 = next(), y1 = next(), nx = next(), ny = next();
          if (rel) {
            x1 += x;
            y1 += y;
            nx += x;
            ny += y;
          }
          path.quadraticBezierTo(x1, y1, nx, ny);
          x = nx;
          y = ny;
        }
      case 'Z':
        path.close();
        x = startX;
        y = startY;
      default:
        break;
    }
    // Drop numbers no command could use (unsupported commands, stray values).
    while (i < tokens.length && !isCommand(tokens[i])) {
      i++;
    }
  }
  return path;
}
