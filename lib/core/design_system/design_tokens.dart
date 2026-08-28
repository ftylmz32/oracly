/// ORACLY Reference Design System — single import for every screen.
///
/// ```dart
/// import 'package:oracly_new/core/design_system/design_tokens.dart';
/// ```
///
/// Tokens: colors · typography · spacing (8/12/16/20/24/32) · radius ·
/// borders · gradients · shadows · glows · icons · motion · layout
///
/// Components: cosmic background · star field · glass card · premium button ·
/// gold button · app bar · bottom bar · section label · premium icons
library;

// ── Tokens ─────────────────────────────────────────────────────────────────
export 'app_blur.dart';
export 'app_borders.dart';
export 'app_colors.dart';
export 'app_glows.dart';
export 'app_gradients.dart';
export 'app_icons.dart';
export 'app_layout.dart';
export 'app_motion.dart';
export 'app_radius.dart';
export 'app_shadows.dart';
export 'app_spacing.dart';
export 'app_typography.dart';

// ── Atmosphere ─────────────────────────────────────────────────────────────
export 'oracly_cosmic_background.dart';
export 'oracly_star_field.dart';
export 'premium_background.dart';

// ── Surfaces & chrome ──────────────────────────────────────────────────────
export 'oracly_glass_card.dart';
export 'oracly_surface_style.dart';
export 'oracly_app_bar.dart';
export 'oracly_crystal_capsule.dart';
export 'oracly_header_action.dart';
export 'oracly_premium_icon.dart';
export 'oracly_section_label.dart';
export 'oracly_design_system.dart';
export 'premium_button.dart';
export 'premium_header.dart';
export 'premium_section.dart';
export 'premium_cards/premium_cards.dart';

// ── Shared chrome (navigation / primary CTA) ───────────────────────────────
export '../../shared/widgets/oracly_bottom_bar.dart';
export '../../shared/widgets/oracly_gold_button.dart';
export '../../shared/widgets/oracly_section_title.dart';

/// Quick index of approved reference tokens.
abstract final class DesignTokens {
  DesignTokens._();

  // Spacing rhythm
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;

  // Card
  static const double cardRadius = 24;
  static const double heroRadius = 28;
  static const double buttonRadius = 20;

  // Gold
  static const int gold = 0xFFE7C56D;
  static const int goldLight = 0xFFF5D98A;
  static const int goldDeep = 0xFFC9A84E;
}
