/// EPIC-021 — Canonical ORACLY color tokens.
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

/// Central color registry — every screen reads from here.
///
/// Global DNA: deep near-black · midnight navy · rich violet · luminous
/// antique gold · warm ivory · restrained amber. Screens consume these
/// tokens — they do not invent competing hex.
abstract final class AppColors {
  AppColors._();

  // ── Foundation (vivid premium sanctuary) ────────────────────────────────

  /// Deep near-black — calm void behind every chamber.
  static const Color nearBlack = Color(0xFF02030A);

  /// Midnight navy — secondary depth, nav, scaffolds.
  static const Color midnightNavy = Color(0xFF0A1224);

  /// Chamber violet atmosphere (gradients / cosmic mid-tones).
  static const Color chamberViolet = Color(0xFF12081E);
  static const Color royalViolet = Color(0xFF1A0E2C);
  static const Color crystalVeil = Color(0xFF261840);

  static const Color background = nearBlack;
  static const Color backgroundSecondary = midnightNavy;
  static const Color surface = Color(0xFF16122A);
  static const Color surfaceElevated = Color(0xFF211B3A);

  /// Luminous antique gold — titles, CTAs, engraved accents (one gold).
  static const Color gold = Color(0xFFE8C872);
  static const Color goldLight = Color(0xFFF4DB94);
  static const Color goldDeep = Color(0xFFC49A3F);
  /// Deep antique edge / card thickness shadow (not a fill).
  static const Color goldShadow = Color(0xFF9A7848);

  /// Restrained amber — warm ritual accents (coffee / premium haze).
  static const Color amber = Color(0xFFC99542);
  static const Color amberSoft = Color(0xFFD4A86A);

  /// Rich violet — mystical material, never neon wash.
  static const Color primaryPurple = Color(0xFF5A3FD6);
  static const Color secondaryPurple = Color(0xFF8B70E8);
  static const Color violetLuminous = Color(0xFF9B6DFF);
  static const Color accentPink = Color(0xFFCF7AE8);

  /// Warm ivory — reading body / cream chrome (never stark white).
  static const Color ivory = Color(0xFFF3EADF);
  static const Color cream = ivory;

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xB3FFFFFF);
  static const Color divider = Color(0x12FFFFFF);

  static const Color glowGold = Color(0x58E8C872);
  static const Color glowPurple = Color(0x3D5A3FD6);
  static const Color glowAmber = Color(0x40C99542);

  // ── Semantic extensions ──────────────────────────────────────────────────

  static const Color primary = backgroundSecondary;
  static const Color secondary = backgroundSecondary;
  static const Color card = surface;
  static const Color purple = primaryPurple;
  static const Color purpleLight = secondaryPurple;
  static const Color purpleDark = Color(0xFF3B2896);

  static const Color success = Color(0xFF5EE6A8);
  static const Color warning = amberSoft;
  static const Color error = Color(0xFFFF6B81);

  static const Color border = Color(0x52E8C872);
  static const Color borderSubtle = divider;
  static const Color matteBorder = Color(0x32E8C872);
  static const Color glassBorder = matteBorder;

  static const Color textHint = Color(0xFFC2B6A6);
  static const Color textMuted = Color(0xFF9A8F82);
  static const Color icon = goldLight;

  static const Color white = textPrimary;
  static const Color offWhite = ivory;
  static const Color transparent = Colors.transparent;
  static const Color black = Colors.black;

  static const Color goldGlow = glowGold;
  static const Color purpleGlow = glowPurple;

  static const Color grey100 = Color(0xFFEDE6DC);
  static const Color grey300 = textSecondary;
  static const Color grey500 = textHint;
  static const Color grey700 = textMuted;

  // ── Legacy aliases ───────────────────────────────────────────────────────

  static const Color primaryLight = secondaryPurple;
  static const Color primaryDark = purpleDark;
  static const Color accent = gold;
  static const Color surfaceLight = surfaceElevated;
  static const Color surfaceDark = background;
  static const Color danger = error;
  static const Color orbCore = goldLight;
  static const Color orbGlow = glowPurple;
  static const Color cyan = secondaryPurple;
  static const Color info = secondaryPurple;

  // ── Palettes ─────────────────────────────────────────────────────────────

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

  /// Warm ivory sanctuary — deep violet type, antique gold accents.
  static const AppColorPalette light = AppColorPalette(
    background: Color(0xFFF6F0E6),
    primary: Color(0xFF14102A),
    secondary: Color(0xFFEDE4D6),
    surface: Color(0xFFF3EBE0),
    card: Color(0xFFF3EBE0),
    gold: Color(0xFFB89428),
    goldLight: goldDeep,
    purple: purpleDark,
    success: Color(0xFF059669),
    warning: Color(0xFFB87A28),
    error: Color(0xFFDC2626),
    divider: Color(0x1A14102A),
    border: Color(0x40B89428),
    textPrimary: Color(0xFF14102A),
    textSecondary: Color(0xFF5C5470),
    icon: Color(0xFFB89428),
  );

  /// Resolves palette from the active [ThemeData] brightness.
  static AppColorPalette of(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.light ? light : dark;
  }

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
}
