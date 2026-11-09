import 'package:flutter/material.dart';

import '../../../motion/app_pressable.dart';
import '../../../motion/app_status_button.dart';
import '../../../theme/app_colors.dart';

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.status = ActionStatus.idle,
    this.doneLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final ActionStatus status;
  final String? doneLabel;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return AppStatusButton(
      status: status,
      label: label,
      doneLabel: doneLabel ?? 'انجام شد',
      onPressed: onPressed ?? () {},
      color: c.primary,
      doneColor: c.success,
      foreground: c.onPrimary,
      height: 54,
      radius: 16,
      textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: c.onPrimary,
            fontSize: 16,
          ),
    );
  }
}

class AuthTextLink extends StatelessWidget {
  const AuthTextLink({
    super.key,
    required this.label,
    required this.onTap,
    this.emphasize = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return AppPressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: emphasize ? c.secondary : c.muted,
                fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
              ),
        ),
      ),
    );
  }
}
