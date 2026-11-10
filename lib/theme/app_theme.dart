import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../motion/app_motion.dart';
import 'app_colors.dart';

class AppTheme {
  static const defaultMode = ThemeMode.dark;

  static final SystemUiOverlayStyle systemUi = SystemUiOverlayStyle(
    statusBarColor: AppColors.dark.background,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: AppColors.dark.background,
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarDividerColor: const Color(0x00000000),
  );

  static Widget withSystemUi(BuildContext context, Widget child) =>
      AnnotatedRegion<SystemUiOverlayStyle>(value: systemUi, child: child);

  static TextTheme _text(Color ink, Color muted) {
    final base = const TextTheme().apply(fontFamily: 'Estedad');
    return base
        .apply(bodyColor: ink, displayColor: ink)
        .copyWith(
          displaySmall: base.displaySmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: ink,
          ),
          headlineMedium: base.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: ink,
          ),
          titleLarge: base.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: ink,
          ),
          titleMedium: base.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: ink,
          ),
          bodyLarge: base.bodyLarge?.copyWith(
            fontSize: 16,
            height: 1.55,
            color: ink,
          ),
          bodyMedium: base.bodyMedium?.copyWith(
            fontSize: 14,
            height: 1.5,
            color: ink,
          ),
          bodySmall: base.bodySmall?.copyWith(
            fontSize: 12,
            height: 1.4,
            color: muted,
          ),
          labelLarge: base.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
            color: ink,
          ),
        );
  }

  static ThemeData _from(AppColors c, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.primary,
      onPrimary: c.onPrimary,
      secondary: c.secondary,
      onSecondary: c.onSecondary,
      tertiary: c.tertiary,
      onTertiary: c.onPrimary,
      error: c.danger,
      onError: c.onPrimary,
      surface: c.surface,
      onSurface: c.ink,
      surfaceContainerLowest: c.surfaceContainerLow,
      surfaceContainerLow: c.surfaceContainerLow,
      surfaceContainer: c.surfaceContainer,
      surfaceContainerHigh: c.surfaceContainerHigh,
      surfaceContainerHighest: c.surfaceContainerHigh,
      outline: c.outline,
      outlineVariant: c.line,
    );

    final text = _text(c.ink, c.muted);

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Estedad',
      brightness: brightness,
      pageTransitionsTheme: AppMotion.pageTransitions,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.background,
      textTheme: text,
      primaryTextTheme: text,
      dividerColor: c.line,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: c.background,
        foregroundColor: c.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: systemUi,
        titleTextStyle: text.titleMedium,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceContainer.withValues(alpha: 0.72),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.secondary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.danger, width: 1.4),
        ),
        hintStyle: text.bodyMedium?.copyWith(color: c.muted),
        labelStyle: text.bodyMedium?.copyWith(color: c.muted),
        errorStyle: text.bodySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          minimumSize: const Size(0, 46),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.secondary,
          minimumSize: const Size(0, 46),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          side: BorderSide(color: c.secondary.withValues(alpha: .45)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: c.secondary),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF263449),
        contentTextStyle: text.bodyMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static ThemeData light() => _from(AppColors.light, Brightness.light);

  static ThemeData dark() => _from(AppColors.dark, Brightness.dark);
}
