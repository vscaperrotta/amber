import 'package:flutter/material.dart';
import 'void_colors.dart';

/// Theme-aware semantic color tokens. Resolves to dark or light values
/// based on the active [ThemeData.brightness] — widgets read these instead
/// of hardcoding [VoidColors.dark*] / [VoidColors.light*] directly, so a
/// single screen renders consistently in both light and dark mode.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color bgPrimary;
  final Color bgSurface;
  final Color bgElevated;
  final Color accent;
  final Color accentMuted;
  final Color accentOnPrimary;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color border;
  final Color borderFocus;
  final Color statusError;

  const AppColors({
    required this.bgPrimary,
    required this.bgSurface,
    required this.bgElevated,
    required this.accent,
    required this.accentMuted,
    required this.accentOnPrimary,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.border,
    required this.borderFocus,
    required this.statusError,
  });

  static const dark = AppColors(
    bgPrimary: VoidColors.darkBgPrimary,
    bgSurface: VoidColors.darkBgSurface,
    bgElevated: VoidColors.darkBgElevated,
    accent: VoidColors.darkAccent,
    accentMuted: VoidColors.darkAccentMuted,
    accentOnPrimary: VoidColors.accentOnPrimary,
    textPrimary: VoidColors.darkTextPrimary,
    textSecondary: VoidColors.darkTextSecondary,
    textTertiary: VoidColors.darkTextTertiary,
    border: VoidColors.darkBorder,
    borderFocus: VoidColors.darkBorderFocus,
    statusError: VoidColors.darkStatusError,
  );

  static const light = AppColors(
    bgPrimary: VoidColors.lightBgPrimary,
    bgSurface: VoidColors.lightBgSurface,
    bgElevated: VoidColors.lightBgElevated,
    accent: VoidColors.lightAccent,
    // Muted accent tint derived from the light accent at low alpha.
    accentMuted: Color(0x25E8950F),
    accentOnPrimary: VoidColors.accentOnPrimary,
    textPrimary: VoidColors.lightTextPrimary,
    textSecondary: VoidColors.lightTextSecondary,
    textTertiary: VoidColors.lightTextTertiary,
    border: VoidColors.lightBorder,
    borderFocus: VoidColors.lightBorderFocus,
    statusError: VoidColors.lightStatusError,
  );

  @override
  AppColors copyWith({
    Color? bgPrimary,
    Color? bgSurface,
    Color? bgElevated,
    Color? accent,
    Color? accentMuted,
    Color? accentOnPrimary,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? border,
    Color? borderFocus,
    Color? statusError,
  }) {
    return AppColors(
      bgPrimary: bgPrimary ?? this.bgPrimary,
      bgSurface: bgSurface ?? this.bgSurface,
      bgElevated: bgElevated ?? this.bgElevated,
      accent: accent ?? this.accent,
      accentMuted: accentMuted ?? this.accentMuted,
      accentOnPrimary: accentOnPrimary ?? this.accentOnPrimary,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      border: border ?? this.border,
      borderFocus: borderFocus ?? this.borderFocus,
      statusError: statusError ?? this.statusError,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      bgPrimary: Color.lerp(bgPrimary, other.bgPrimary, t)!,
      bgSurface: Color.lerp(bgSurface, other.bgSurface, t)!,
      bgElevated: Color.lerp(bgElevated, other.bgElevated, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentMuted: Color.lerp(accentMuted, other.accentMuted, t)!,
      accentOnPrimary: Color.lerp(accentOnPrimary, other.accentOnPrimary, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderFocus: Color.lerp(borderFocus, other.borderFocus, t)!,
      statusError: Color.lerp(statusError, other.statusError, t)!,
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
