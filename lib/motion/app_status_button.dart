import 'package:flutter/material.dart';

import 'app_draw_check.dart';
import 'app_motion.dart';

enum ActionStatus { idle, loading, done }

/// Primary action that shows its own result: idle → spinner → done.
///
/// Keeps its height, swaps its label with a short slide, and on success
/// shrinks to a pill in [doneColor] with a check that draws itself.
/// Booking, paying, saving, sending, joining.
///
/// ```dart
/// AppStatusButton(
///   status: status, label: 'Confirm · \$45', doneLabel: 'Booked',
///   onPressed: () async { setState(() => status = ActionStatus.loading); ... },
/// )
/// ```
class AppStatusButton extends StatelessWidget {
  const AppStatusButton({
    super.key,
    required this.status,
    required this.label,
    required this.onPressed,
    this.doneLabel = 'Done',
    this.color,
    this.doneColor,
    this.foreground,
    this.height = 48,
    this.radius,
    this.doneWidthFactor = 0.66,
    this.textStyle,
  });

  final ActionStatus status;
  final String label;
  final String doneLabel;
  final VoidCallback? onPressed;

  /// Idle / loading fill; defaults to the theme's `colorScheme.primary`.
  final Color? color;

  /// Done pill; defaults to the resolved [color] (theme primary).
  final Color? doneColor;

  /// Label, spinner and check; defaults to `colorScheme.onPrimary`.
  final Color? foreground;
  final double height;

  /// Corner radius; defaults to a full pill.
  final double? radius;

  /// Width of the done pill relative to the idle width.
  final double doneWidthFactor;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = color ?? scheme.primary;
    final doneColor = this.doneColor ?? bg;
    final foreground = this.foreground ?? scheme.onPrimary;
    final style = (textStyle ?? Theme.of(context).textTheme.labelLarge ?? const TextStyle())
        .copyWith(color: foreground, fontWeight: FontWeight.w600);
    final r = BorderRadius.circular(radius ?? height / 2);
    final done = status == ActionStatus.done;

    // Labels stay on one line and ellipsize: a long label (or 200% text) never
    // overflows the fixed-height button or the narrower done pill.
    Text oneLine(String text, {Key? key}) => Text(
          text,
          key: key,
          style: style,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        );
    final Widget content = switch (status) {
      ActionStatus.idle => oneLine(label, key: const ValueKey('idle')),
      ActionStatus.loading => SizedBox.square(
          key: const ValueKey('loading'),
          dimension: 20,
          child: CircularProgressIndicator(strokeWidth: 2.4, color: foreground),
        ),
      ActionStatus.done => Row(
          key: const ValueKey('done'),
          mainAxisSize: MainAxisSize.min,
          children: [
            AppDrawCheck(size: 20, color: foreground, delay: AppMotion.sm),
            const SizedBox(width: 8),
            Flexible(child: oneLine(doneLabel)),
          ],
        ),
    };

    return LayoutBuilder(
      builder: (context, box) {
        final full = box.hasBoundedWidth ? box.maxWidth : 240.0;
        // heightFactor 1: only as tall as the button. A plain Center takes all
        // the height it is offered — inside a bottom bar placed with Align it
        // grew to the whole screen and hid the page behind it (live, 2026-10-10:
        // a product detail screen showed nothing but "Price $36 · Add to cart").
        return Center(
          heightFactor: 1,
          child: Semantics(
            button: true,
            liveRegion: true,
            label: switch (status) {
              ActionStatus.idle => label,
              ActionStatus.loading => '$label, in progress',
              ActionStatus.done => doneLabel,
            },
            child: AnimatedContainer(
              duration: AppMotion.resolve(context, AppMotion.xl, essential: true),
              // Width animates: never an overshoot curve here (a back/elastic pop can
              // drive the width negative).
              curve: AppMotion.sizeCurve,
              width: done ? full * doneWidthFactor : full,
              height: height,
              decoration: BoxDecoration(color: done ? doneColor : bg, borderRadius: r),
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  borderRadius: r,
                  onTap: status == ActionStatus.idle ? onPressed : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: AppMotion.resolve(context, AppMotion.md, essential: true),
                        switchInCurve: AppMotion.enter,
                        switchOutCurve: AppMotion.exitCurve,
                        transitionBuilder: (child, a) => FadeTransition(
                          opacity: a,
                          child: SlideTransition(
                            position: Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
                                .animate(a),
                            child: child,
                          ),
                        ),
                        child: content,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
