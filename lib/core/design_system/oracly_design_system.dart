/// Oracly Design System — component measurements + barrel for screens.
library;

import 'package:flutter/material.dart';

import 'app_layout.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'oracly_chrome.dart';

export 'app_borders.dart';
export 'app_colors.dart';
export 'app_glows.dart';
export 'app_gradients.dart';
export 'app_icons.dart';
export 'app_layout.dart';
export 'app_radius.dart';
export 'app_shadows.dart';
export 'app_spacing.dart';
export 'app_typography.dart';
export 'oracly_app_bar.dart';
export 'oracly_art_frame.dart';
export 'oracly_chrome.dart';
export 'oracly_cosmic_background.dart';
export 'oracly_crystal_capsule.dart';
export 'oracly_glass_card.dart';
export 'oracly_surface_style.dart';
export 'oracly_header_action.dart';
export 'oracly_premium_icon.dart';
export 'oracly_ritual_steps.dart';
export 'oracly_section_label.dart';
export 'oracly_star_field.dart';
export 'premium_button.dart';
export 'premium_header.dart';

/// Canonical component measurements shared by every reference screen.
abstract final class OraclyComponentTokens {
  OraclyComponentTokens._();

  static const BorderRadius cardRadius = OraclyChrome.cardRadius;
  static const BorderRadius heroRadius = OraclyChrome.heroRadius;
  static const BorderRadius buttonRadius = AppRadius.s20;

  static const EdgeInsets cardPadding = EdgeInsets.all(AppSpacing.s16);
  static const EdgeInsets cardPaddingCompact = OraclyChrome.cardPadding;

  static const double cardMinHeight = 88;
  static const double listRowMinHeight = 56;
  static const double sectionGap = OraclyChrome.sectionGap;
  static const double sectionGapCompact = AppSpacing.s8;
  static const double sectionLabelGap = AppSpacing.s8;

  static const double iconWell = OraclyChrome.iconWell;
  static const double iconSize = OraclyChrome.iconGlyph;

  static const EdgeInsets primaryButtonPadding =
      AppLayout.referencePrimaryButtonPadding;
  static const EdgeInsets outlineButtonPadding =
      AppLayout.referenceOutlineButtonPadding;

  static double blockGap(BuildContext context) =>
      AppLayout.isCompactPhone(context) ? sectionGapCompact : sectionGap;

  static EdgeInsets screenPadding(BuildContext context) =>
      AppLayout.responsiveScreenPadding(context);
}

/// Theme extension — access via `Theme.of(context).extension<OraclyDesignTokens>()`.
@immutable
class OraclyDesignTokens extends ThemeExtension<OraclyDesignTokens> {
  const OraclyDesignTokens({
    required this.cardRadius,
    required this.cardPadding,
    required this.sectionGap,
    required this.sectionLabelGap,
    required this.cardMinHeight,
  });

  final BorderRadius cardRadius;
  final EdgeInsets cardPadding;
  final double sectionGap;
  final double sectionLabelGap;
  final double cardMinHeight;

  static const standard = OraclyDesignTokens(
    cardRadius: OraclyComponentTokens.cardRadius,
    cardPadding: OraclyComponentTokens.cardPadding,
    sectionGap: OraclyComponentTokens.sectionGap,
    sectionLabelGap: OraclyComponentTokens.sectionLabelGap,
    cardMinHeight: OraclyComponentTokens.cardMinHeight,
  );

  @override
  OraclyDesignTokens copyWith({
    BorderRadius? cardRadius,
    EdgeInsets? cardPadding,
    double? sectionGap,
    double? sectionLabelGap,
    double? cardMinHeight,
  }) {
    return OraclyDesignTokens(
      cardRadius: cardRadius ?? this.cardRadius,
      cardPadding: cardPadding ?? this.cardPadding,
      sectionGap: sectionGap ?? this.sectionGap,
      sectionLabelGap: sectionLabelGap ?? this.sectionLabelGap,
      cardMinHeight: cardMinHeight ?? this.cardMinHeight,
    );
  }

  @override
  OraclyDesignTokens lerp(OraclyDesignTokens? other, double t) {
    if (other == null) return this;
    return t < 0.5 ? this : other;
  }
}

/// Convenience accessor for design tokens from [BuildContext].
extension OraclyDesignContext on BuildContext {
  OraclyDesignTokens get oraclyDesign =>
      Theme.of(this).extension<OraclyDesignTokens>() ??
      OraclyDesignTokens.standard;

  double get oraclyBlockGap => OraclyComponentTokens.blockGap(this);

  EdgeInsets get oraclyScreenPadding =>
      OraclyComponentTokens.screenPadding(this);
}
