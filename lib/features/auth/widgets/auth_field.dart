import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../theme/app_colors.dart';

class AuthField extends StatelessWidget {
  const AuthField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.iconPath,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.onToggleObscure,
    this.validator,
    this.autofillHints,
    this.textDirection,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final String? iconPath;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final VoidCallback? onToggleObscure;
  final String? Function(String?)? validator;
  final Iterable<String>? autofillHints;
  final TextDirection? textDirection;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final theme = Theme.of(context);

    Widget? prefix;
    if (iconPath != null) {
      prefix = Padding(
        padding: const EdgeInsetsDirectional.only(start: 14, end: 10),
        child: SvgPicture.asset(
          iconPath!,
          width: 20,
          height: 20,
          colorFilter: ColorFilter.mode(c.muted, BlendMode.srcIn),
        ),
      );
    }

    Widget? suffix;
    if (onToggleObscure != null) {
      suffix = IconButton(
        onPressed: onToggleObscure,
        icon: SvgPicture.asset(
          obscureText ? 'assets/icons/eye.svg' : 'assets/icons/eye_off.svg',
          width: 20,
          height: 20,
          colorFilter: ColorFilter.mode(c.muted, BlendMode.srcIn),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(color: c.muted),
          textAlign: TextAlign.start,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          textDirection: textDirection,
          style: theme.textTheme.bodyLarge,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefix,
            prefixIconConstraints: const BoxConstraints(
              minWidth: 44,
              minHeight: 44,
            ),
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}

String? validateEmail(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return 'ایمیل را وارد کنید';
  if (!v.contains('@') || !v.contains('.')) return 'ایمیل معتبر نیست';
  return null;
}

String? validatePassword(String? value) {
  final v = value ?? '';
  if (v.isEmpty) return 'رمز عبور را وارد کنید';
  if (v.length < 6) return 'رمز باید حداقل ۶ کاراکتر باشد';
  return null;
}

String? validateName(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return 'نام را وارد کنید';
  if (v.length < 2) return 'نام کوتاه است';
  return null;
}
