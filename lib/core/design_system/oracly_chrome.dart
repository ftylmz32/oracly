/// Shared premium mystical chrome — one product, one visual language.
///
/// Prefer these over ad-hoc alphas / magic numbers on feature screens.
library;

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_typography.dart';
import '../theme/craftsmanship_rhythm.dart';

/// Canonical chrome metrics + text recipes for headers, nav, cards, CTAs.
abstract final class OraclyChrome {
  OraclyChrome._();

  // ── Atmosphere ───────────────────────────────────────────────────────────

  static const Color midnight = AppColors.background;
  static const Color deepNavy = AppColors.backgroundSecondary;
  static const Color cardSurface = AppColors.surface;
  static const Color elevatedSurface = AppColors.surfaceElevated;
  static const Color gold = AppColors.gold;
  static const Color goldLight = AppColors.goldLight;
  static const Color violet = AppColors.primaryPurple;
  static const Color violetSoft = AppColors.secondaryPurple;
  static const Color amber = AppColors.amber;
  static const Color amberSoft = AppColors.amberSoft;

  /// Gold system — titles / CTAs / accents.
  static const Color goldPrimary = AppColors.gold;
  static const Color goldMuted = AppColors.goldDeep;
  static const Color goldHighlight = AppColors.goldLight;

  /// Warm ivory for reading body — never stark white on midnight glass.
  static const Color cream = AppColors.ivory;
  static const Color ivory = AppColors.ivory;

  static const double borderHairline = 0.22;
  static const double borderDefault = 0.34;
  static const double borderEmphasis = 0.50;
  static const double borderSelected = 0.54;

  static const double glowSoft = 0.09;
  static const double glowMedium = 0.16;
  static const double glowStrong = 0.24;

  // ── Layout rhythm ────────────────────────────────────────────────────────

  static const double screenSide = AppSpacing.s20;
  static const double screenTop = AppSpacing.s12;
  static const double sectionGap = AppSpacing.s12;
  static const double cardPadH = AppSpacing.s12;
  static const double cardPadV = AppSpacing.s12;
  static const double iconWell = 36;
  static const double iconGlyph = 18;
  static const double titleMarkSize = 10;
  static const double buttonHeight = 44;
  static const double chipHeight = 32;
  static const double headerHeight = 48;
  static const double navHeight = 60;
  static const double navMarginH = AppSpacing.s16;
  static const double navMarginBottom = 8;
  static const double navIcon = 22;
  static const double navLabel = 11;

  static const BorderRadius cardRadius = AppRadius.s20;
  static const BorderRadius heroRadius = AppRadius.s24;
  static const BorderRadius navRadius = AppRadius.s28;
  static const BorderRadius chipRadius = AppRadius.s28;
  static const BorderRadius pillRadius = AppRadius.s28;

  static const EdgeInsets cardPadding =
      EdgeInsets.fromLTRB(cardPadH, cardPadV, cardPadH, cardPadV);

  static const EdgeInsets screenPaddingH =
      EdgeInsets.symmetric(horizontal: screenSide);

  // ── Typography recipes ───────────────────────────────────────────────────

  static TextStyle engravedTitle({double size = 14}) =>
      AppTypography.headingM.copyWith(
        color: goldPrimary.withValues(alpha: 0.94),
        fontWeight: FontWeight.w600,
        letterSpacing: CraftsmanshipRhythm.sectionLabelTracking,
        height: 1.15,
        fontSize: size,
      );

  static TextStyle sectionLabel({double size = 12}) =>
      AppTypography.caption.copyWith(
        color: goldMuted.withValues(alpha: 0.90),
        fontWeight: FontWeight.w600,
        letterSpacing: CraftsmanshipRhythm.eyebrowTracking,
        height: CraftsmanshipRhythm.sectionLabelHeight,
        fontSize: size,
      );

  static TextStyle bodySecondary({double size = 14}) =>
      AppTypography.body.copyWith(
        color: cream.withValues(alpha: CraftsmanshipRhythm.secondaryInk),
        height: CraftsmanshipRhythm.bodyLineHeight,
        letterSpacing: CraftsmanshipRhythm.bodyLetterSpacing,
        fontSize: size,
        fontWeight: FontWeight.w400,
      );

  static TextStyle ctaLabel({double size = 15}) =>
      AppTypography.button.copyWith(
        color: AppColors.nearBlack,
        fontWeight: FontWeight.w600,
        letterSpacing: CraftsmanshipRhythm.ctaTracking,
        height: 1.15,
        fontSize: size,
      );

  static Color border({
    bool selected = false,
    bool premium = false,
  }) {
    final a = selected
        ? borderSelected
        : premium
            ? borderEmphasis
            : borderDefault;
    return (selected ? goldHighlight : goldMuted).withValues(alpha: a);
  }

  /// Shared dark-glass fill for app-bar actions / gem capsule / chrome chips.
  static LinearGradient get chromeGlass => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          elevatedSurface.withValues(alpha: 0.88),
          cardSurface.withValues(alpha: 0.72),
          midnight.withValues(alpha: 0.82),
        ],
        stops: const [0.0, 0.55, 1.0],
      );
}
