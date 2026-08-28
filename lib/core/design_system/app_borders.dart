/// Canonical border styles — gold hairlines, glass rims, selected emphasis.
library;

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'oracly_art_direction.dart';
import 'oracly_chrome.dart';
import 'oracly_surface_style.dart';

/// Border width + color recipes used by every premium surface.
abstract final class AppBorders {
  AppBorders._();

  static const double hairline = AppBorderWidth.hairline;
  static const double thin = AppBorderWidth.thin;
  static const double gold = AppBorderWidth.gold;
  static const double emphasis = AppBorderWidth.emphasis;

  /// Default glass card rim.
  static BorderSide glass({double strength = 1.0}) => BorderSide(
        color: AppColors.goldDeep.withValues(
          alpha: OraclyArtDirection.goldBorderDefault * strength,
        ),
        width: hairline,
      );

  /// Premium / elevated card rim.
  static BorderSide premium({double strength = 1.0}) => BorderSide(
        color: AppColors.gold.withValues(alpha: 0.42 * strength),
        width: thin,
      );

  /// Selected / active state.
  static BorderSide selected() => BorderSide(
        color: AppColors.goldLight.withValues(
          alpha: OraclyArtDirection.goldBorderEmphasis,
        ),
        width: gold,
      );

  /// Subtle surface divider rim.
  static BorderSide subtle() => BorderSide(
        color: AppColors.divider,
        width: hairline,
      );

  /// Soft purple accent (crystal capsule, gem chips).
  static BorderSide crystal() => BorderSide(
        color: AppColors.purpleLight.withValues(alpha: 0.38),
        width: hairline,
      );

  /// Antique gold edge — same recipe as live glass cards.
  static BorderSide goldEdge({
    bool selected = false,
    bool premium = false,
    bool elevated = false,
    double strength = 1.0,
  }) =>
      BorderSide(
        color: OraclySurfaceStyle.goldBorder(
          selected: selected,
          premium: premium,
          elevated: elevated,
          glowStrength: strength,
        ),
        width: OraclySurfaceStyle.borderWidth(
          selected: selected,
          premium: premium,
          elevated: elevated,
        ),
      );

  static Border all(BorderSide side) => Border.fromBorderSide(side);

  static BoxBorder glassBox({double strength = 1.0}) => Border.all(
        color: AppColors.goldDeep.withValues(
          alpha: OraclyArtDirection.goldBorderDefault * strength,
        ),
        width: hairline,
      );

  static BoxBorder premiumBox({double strength = 1.0}) => Border.all(
        color: AppColors.gold.withValues(alpha: 0.42 * strength),
        width: thin,
      );

  static BorderRadius get cardRadius => OraclyChrome.cardRadius;
  static BorderRadius get heroRadius => OraclyChrome.heroRadius;
  static BorderRadius get buttonRadius => OraclyChrome.pillRadius;
  static BorderRadius get pillRadius => OraclyChrome.pillRadius;
}
