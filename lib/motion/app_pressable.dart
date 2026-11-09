import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'app_motion.dart';

/// Press feedback for any custom tappable (cards, tiles, chips, custom buttons).
///
/// Follows this app's catalogue press (`AppMotion.preset.press`): shrink,
/// deep press, lift, dim or tilt — opacity 0.7 under reduced motion — and
/// reacts within 100 ms. Material buttons already have feedback; use this
/// for everything else.
class AppPressable extends StatefulWidget {
  const AppPressable({
    super.key,
    required this.child,
    required this.onTap,
    this.scale,
    this.haptic,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  /// Overrides the preset's pressed scale.
  final double? scale;

  /// Overrides the preset's haptics (`selectionClick` on tap).
  final bool? haptic;
  final String? semanticLabel;

  @override
  State<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends State<AppPressable> {
  bool _pressed = false;

  void _set(bool v) {
    if (widget.onTap == null || _pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final reduce = AppMotion.reduced(context);
    final enabled = widget.onTap != null;
    final Widget body = reduce
        ? AnimatedOpacity(
            opacity: _pressed ? 0.7 : 1,
            duration: AppMotion.xs,
            curve: AppMotion.standard,
            child: widget.child,
          )
        : _pressedBody();
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: enabled
            ? () {
                final haptics = AppMotion.preset.haptics;
                if (widget.haptic ?? haptics != MotionHaptics.none) {
                  if (haptics == MotionHaptics.rich && widget.haptic == null) {
                    HapticFeedback.lightImpact();
                  } else {
                    HapticFeedback.selectionClick();
                  }
                }
                widget.onTap!();
              }
            : null,
        child: body,
      ),
    );
  }

  Widget _pressedBody() {
    final press = AppMotion.preset.press;
    final scale = widget.scale ?? AppMotion.pressScaleFor;
    Widget body = AnimatedScale(
      scale: _pressed ? scale : 1,
      duration: AppMotion.xs,
      curve: press == MotionPress.lift ? Curves.easeOutBack : AppMotion.standard,
      child: widget.child,
    );
    if (press == MotionPress.dim && widget.scale == null) {
      body = AnimatedOpacity(
        opacity: _pressed ? 0.6 : 1,
        duration: AppMotion.xs,
        curve: AppMotion.standard,
        child: widget.child,
      );
    } else if (press == MotionPress.tilt && widget.scale == null) {
      body = AnimatedRotation(
        turns: _pressed ? -0.004 : 0,
        duration: AppMotion.xs,
        curve: AppMotion.standard,
        child: body,
      );
    }
    return body;
  }
}
