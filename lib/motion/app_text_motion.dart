import 'dart:async';

import 'package:flutter/material.dart';

import 'app_motion.dart';

/// Types [text] one character at a time with a blinking caret.
/// Use only to *demonstrate* input (onboarding, empty-state examples,
/// assistant replies) — never for text the user is waiting to read.
class AppTypewriter extends StatefulWidget {
  const AppTypewriter({
    super.key,
    required this.text,
    this.style,
    this.delay = Duration.zero,
    this.perChar = const Duration(milliseconds: 45),
    this.showCaret = true,
    this.onDone,
  });

  final String text;
  final TextStyle? style;
  final Duration delay;
  final Duration perChar;
  final bool showCaret;
  final VoidCallback? onDone;

  @override
  State<AppTypewriter> createState() => _AppTypewriterState();
}

class _AppTypewriterState extends State<AppTypewriter> {
  int _count = 0;
  bool _caret = true;
  Timer? _type;
  Timer? _blink;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (AppMotion.reduced(context)) {
      _count = widget.text.length;
      _caret = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onDone?.call());
      return;
    }
    _type = Timer(widget.delay, () {
      _type = Timer.periodic(widget.perChar, (t) {
        if (!mounted) {
          t.cancel();
          return;
        }
        setState(() => _count++);
        if (_count >= widget.text.length) {
          t.cancel();
          _blink?.cancel();
          setState(() => _caret = false);
          widget.onDone?.call();
        }
      });
    });
    if (widget.showCaret) {
      _blink = Timer.periodic(const Duration(milliseconds: 530), (_) {
        if (mounted) setState(() => _caret = !_caret);
      });
    }
  }

  @override
  void dispose() {
    _type?.cancel();
    _blink?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shown = widget.text.substring(0, _count.clamp(0, widget.text.length));
    final caret = widget.showCaret && _caret;
    return Semantics(
      label: widget.text,
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: shown),
            if (widget.showCaret)
              TextSpan(
                text: '|',
                style: TextStyle(color: caret ? null : const Color(0x00000000)),
              ),
          ],
        ),
        style: widget.style,
      ),
    );
  }
}

/// A chat bubble that pops in from its own corner (user = bottom-right,
/// other = bottom-left). Pair with [AppTypewriter] for assistant replies.
///
/// Theme defaults: mine = `primary` fill with `onPrimary` text, theirs =
/// `surfaceContainerHigh` with `onSurface`; corners follow the theme's card
/// shape (18 when the theme sets none) with a tighter tail corner.
class AppChatBubble extends StatefulWidget {
  const AppChatBubble({
    super.key,
    required this.child,
    this.fromMe = false,
    this.delay = Duration.zero,
    this.color,
    this.maxWidth = 240,
    this.foregroundColor,
    this.borderRadius,
    this.padding = const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
  });

  final Widget child;
  final bool fromMe;
  final Duration delay;

  /// Bubble fill; defaults to `colorScheme.primary` for [fromMe], otherwise
  /// `colorScheme.surfaceContainerHigh`.
  final Color? color;
  final double maxWidth;

  /// Default text / icon colour inside the bubble. Defaults to the matching
  /// "on" role (`onPrimary` / `onSurface`) when [color] is not set; with a
  /// custom [color] and no foreground, the child's own style is left alone.
  final Color? foregroundColor;

  /// Bubble corners; defaults to the theme card radius with a small tail
  /// corner on the sender's side.
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry padding;

  @override
  State<AppChatBubble> createState() => _AppChatBubbleState();
}

class _AppChatBubbleState extends State<AppChatBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  // Driven by the controller: no rebuild and no `Opacity` widget per frame.
  late final Animation<double> _fade = CurvedAnimation(parent: _c, curve: const Interval(0, 0.3));
  late final Animation<double> _scale = _c.drive(Tween<double>(begin: 0.6, end: 1).chain(CurveTween(curve: AppMotion.pop)));
  Timer? _t;
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
    _c.duration = AppMotion.xl;
    _t = Timer(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fill = widget.color ?? (widget.fromMe ? scheme.primary : scheme.surfaceContainerHigh);
    final ink = widget.foregroundColor ??
        (widget.color != null ? null : (widget.fromMe ? scheme.onPrimary : scheme.onSurface));
    final r = widget.borderRadius ?? _bubbleRadius(theme, widget.fromMe);
    Widget body = Padding(padding: widget.padding, child: widget.child);
    if (ink != null) {
      body = IconTheme.merge(
        data: IconThemeData(color: ink),
        child: DefaultTextStyle.merge(style: TextStyle(color: ink), child: body),
      );
    }
    return Align(
      alignment: widget.fromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: FadeTransition(
        opacity: _fade,
        child: ScaleTransition(
          alignment: widget.fromMe ? Alignment.bottomRight : Alignment.bottomLeft,
          scale: _scale,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: widget.maxWidth),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: fill,
                borderRadius: r,
                // Soft, theme-tinted lift (the scheme's shadow role, low alpha).
                boxShadow: [
                  BoxShadow(color: scheme.shadow.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 3)),
                ],
              ),
              child: body,
            ),
          ),
        ),
      ),
    );
  }
}

/// Theme card radius (18 when the theme sets no card shape), with a tighter
/// tail corner on the sender's side.
BorderRadius _bubbleRadius(ThemeData theme, bool fromMe) {
  final shape = theme.cardTheme.shape;
  var radius = 18.0;
  if (shape is RoundedRectangleBorder) {
    final br = shape.borderRadius;
    if (br is BorderRadius) radius = br.topLeft.x;
    if (br is BorderRadiusDirectional) radius = br.topStart.x;
  }
  final big = Radius.circular(radius);
  final tail = Radius.circular(radius / 3);
  return fromMe
      ? BorderRadius.only(topLeft: big, topRight: big, bottomLeft: big, bottomRight: tail)
      : BorderRadius.only(topLeft: big, topRight: big, bottomLeft: tail, bottomRight: big);
}
