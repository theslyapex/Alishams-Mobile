import 'package:flutter/material.dart';

/// ALISHAMS luxury dark-glass palette.
class AppColors {
  const AppColors({
    required this.background,
    required this.surface,
    required this.primary,
    required this.onPrimary,
    required this.primaryText,
    required this.secondary,
    required this.onSecondary,
    required this.tertiary,
    required this.primaryContainer,
    required this.secondaryContainer,
    required this.tertiaryContainer,
    required this.ink,
    required this.muted,
    required this.line,
    required this.outline,
    required this.surfaceContainerLow,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.success,
    required this.warning,
    required this.danger,
  });

  final Color background;
  final Color surface;
  final Color primary;
  final Color onPrimary;
  final Color primaryText;
  final Color secondary;
  final Color onSecondary;
  final Color tertiary;
  final Color primaryContainer;
  final Color secondaryContainer;
  final Color tertiaryContainer;
  final Color ink;
  final Color muted;
  final Color line;
  final Color outline;
  final Color surfaceContainerLow;
  final Color surfaceContainer;
  final Color surfaceContainerHigh;
  final Color success;
  final Color warning;
  final Color danger;

  /// Deep navy studio night — primary product look.
  static const dark = AppColors(
    background: Color(0xFF070B18),
    surface: Color(0xFF121A2B),
    primary: Color(0xFF7C3AED),
    onPrimary: Color(0xFFF8FAFC),
    primaryText: Color(0xFFF1F5F9),
    secondary: Color(0xFF22D3EE),
    onSecondary: Color(0xFF0A1020),
    tertiary: Color(0xFFA78BFA),
    primaryContainer: Color(0xFF2E1A5C),
    secondaryContainer: Color(0xFF0E3A45),
    tertiaryContainer: Color(0xFF3B2A6B),
    ink: Color(0xFFF1F5F9),
    muted: Color(0xFF94A3B8),
    line: Color(0x33FFFFFF),
    outline: Color(0x40FFFFFF),
    surfaceContainerLow: Color(0xFF101828),
    surfaceContainer: Color(0xFF182033),
    surfaceContainerHigh: Color(0xFF1E2940),
    success: Color(0xFF34D399),
    warning: Color(0xFFFBBF24),
    danger: Color(0xFFF87171),
  );

  /// Soft day variant kept for system brightness; still navy-led.
  static const light = AppColors(
    background: Color(0xFF070B18),
    surface: Color(0xFF121A2B),
    primary: Color(0xFF8B5CF6),
    onPrimary: Color(0xFFF8FAFC),
    primaryText: Color(0xFFF8FAFC),
    secondary: Color(0xFF67E8F9),
    onSecondary: Color(0xFF0A1020),
    tertiary: Color(0xFFC4B5FD),
    primaryContainer: Color(0xFF3B2470),
    secondaryContainer: Color(0xFF124A56),
    tertiaryContainer: Color(0xFF4C3A7A),
    ink: Color(0xFFF8FAFC),
    muted: Color(0xFFA8B4C8),
    line: Color(0x40FFFFFF),
    outline: Color(0x55FFFFFF),
    surfaceContainerLow: Color(0xFF121A2C),
    surfaceContainer: Color(0xFF1C2740),
    surfaceContainerHigh: Color(0xFF24304A),
    success: Color(0xFF34D399),
    warning: Color(0xFFFBBF24),
    danger: Color(0xFFF87171),
  );

  static AppColors of(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.light ? light : dark;
  }
}
