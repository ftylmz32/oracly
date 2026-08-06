/// OR-001 — Theme Foundation: centralized brand colors and [ColorScheme].
library;

import 'package:flutter/material.dart';

/// Immutable semantic colors for one brightness mode.
@immutable
class AppColorPalette {
  const AppColorPalette({
    required this.background,
    required this.primary,
    required this.secondary,
    required this.surface,
    required this.card,
    required this.gold,
    required this.goldLight,
    required this.purple,
    required this.success,
    required this.warning,
    required this.error,
    required this.divider,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.icon,
  });

  final Color background;
  final Color primary;
  final Color secondary;
  final Color surface;
  final Color card;
  final Color gold;
  final Color goldLight;
  final Color purple;
  final Color success;
  final Color warning;
  final Color error;
  final Color divider;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color icon;
}

/// Central color registry. Dark palette is the production default.
final class AppColors {
  AppColors._();

  // ── Raw brand constants ────────────────────────────────────────────
  static const Color background = Color(0xFF0B0615);
  static const Color primary = Color(0xFF12071F);
  static const Color secondary = Color(0xFF1A0B2E);
  static const Color surface = Color(0xFF23153C);
  static const Color card = surface;
  static const Color gold = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFF0D77A);
  static const Color purple = Color(0xFF9B6DFF);
  static const Color purpleLight = Color(0xFFB794FF);
  static const Color purpleDark = Color(0xFF6B4BC4);
  static const Color success = Color(0xFF5EE6A8);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFFF6B81);
  static const Color divider = Color(0x1FFFFFFF);
  static const Color border = Color(0x40D4AF37);
  static const Color borderSubtle = divider;
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB8B0C8);
  static const Color textHint = Color(0xFF90889F);
  static const Color textMuted = Color(0xFF686076);
  static const Color icon = goldLight;
  static const Color white = textPrimary;
  static const Color offWhite = Color(0xFFF5F2FA);
  static const Color transparent = Colors.transparent;
  static const Color black = Colors.black;

  // ── Derived / elevation tokens ─────────────────────────────────────
  static const Color surfaceElevated = Color(0xFF2A1545);
  static const Color goldGlow = Color(0x33D4AF37);
  static const Color purpleGlow = Color(0x339B6DFF);
  static const Color matteBorder = Color(0x24D4AF37);

  // ── Palettes ───────────────────────────────────────────────────────
  static const AppColorPalette dark = AppColorPalette(
    background: background,
    primary: primary,
    secondary: secondary,
    surface: surface,
    card: card,
    gold: gold,
    goldLight: goldLight,
    purple: purple,
    success: success,
    warning: warning,
    error: error,
    divider: divider,
    border: border,
    textPrimary: textPrimary,
    textSecondary: textSecondary,
    icon: icon,
  );

  static const AppColorPalette light = AppColorPalette(
    background: Color(0xFFFAF8FC),
    primary: primary,
    secondary: Color(0xFFF0ECF8),
    surface: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    gold: Color(0xFFB8941F),
    goldLight: Color(0xFFD4AF37),
    purple: purpleDark,
    success: Color(0xFF059669),
    warning: Color(0xFFD97706),
    error: Color(0xFFDC2626),
    divider: Color(0x1A12071F),
    border: Color(0x40B8941F),
    textPrimary: primary,
    textSecondary: Color(0xFF857D9A),
    icon: Color(0xFFB8941F),
  );

  /// Fully customized Material 3 [ColorScheme] for the given [palette].
  static ColorScheme colorScheme(AppColorPalette palette) {
    final isLight = palette == light;
    return ColorScheme(
      brightness: isLight ? Brightness.light : Brightness.dark,
      primary: palette.gold,
      onPrimary: palette.background,
      primaryContainer: palette.primary,
      onPrimaryContainer: palette.textPrimary,
      secondary: palette.secondary,
      onSecondary: palette.textPrimary,
      secondaryContainer: palette.surface,
      onSecondaryContainer: palette.textPrimary,
      tertiary: palette.purple,
      onTertiary: palette.textPrimary,
      tertiaryContainer: purpleDark,
      onTertiaryContainer: palette.textPrimary,
      error: palette.error,
      onError: palette.textPrimary,
      errorContainer: Color.alphaBlend(
        palette.error.withValues(alpha: 0.24),
        palette.surface,
      ),
      onErrorContainer: palette.textPrimary,
      surface: palette.surface,
      onSurface: palette.textPrimary,
      onSurfaceVariant: palette.textSecondary,
      outline: palette.border,
      outlineVariant: palette.divider,
      shadow: Colors.black,
      scrim: Colors.black.withValues(alpha: 0.55),
      inverseSurface: palette.textPrimary,
      onInverseSurface: palette.background,
      inversePrimary: palette.gold,
      surfaceTint: palette.gold.withValues(alpha: 0.08),
      surfaceContainerHighest: surfaceElevated,
      surfaceContainerHigh: palette.surface,
      surfaceContainer: palette.secondary,
      surfaceContainerLow: palette.primary,
      surfaceContainerLowest: palette.background,
      surfaceBright: surfaceElevated,
      surfaceDim: palette.background,
    );
  }

  static AppColorPalette paletteFor(Brightness brightness) {
    return brightness == Brightness.light ? light : dark;
  }

  // ── Additional semantic aliases ───────────────────────────────

  static const Color glowPurple = purpleGlow;
  static const Color glassBorder = matteBorder;

  static const Color grey100 = Color(0xFFE8E4EF);
  static const Color grey300 = textSecondary;
  static const Color grey500 = textHint;
  static const Color grey700 = textMuted;

  // ── Legacy compatibility aliases ──────────────────────────────
  // Maps pre–theme-foundation names to current tokens without new values.

  static const Color primaryLight = purpleLight;
  static const Color primaryDark = purpleDark;
  static const Color accent = gold;
  static const Color surfaceLight = surfaceElevated;
  static const Color surfaceDark = background;
  static const Color backgroundSecondary = secondary;
  static const Color danger = error;
  static const Color orbCore = goldLight;
  static const Color orbGlow = purpleGlow;
  static const Color cyan = purpleLight;
  static const Color info = purpleLight;
}
