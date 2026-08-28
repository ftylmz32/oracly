/// EPIC-028 — Canonical layout rhythm for every Oracly screen.
///
/// Spacing values only — no visual effects. All screens align to this grid.
library;

import 'package:flutter/material.dart';

import 'app_spacing.dart';

/// Single source of truth for screen composition, grid, and hierarchy spacing.
abstract final class AppLayout {
  AppLayout._();

  // ── Content width ────────────────────────────────────────────────────────

  /// Soft readability cap for tablets / very wide canvases — not phone gutters.
  static const double maxContentWidth = 560;

  // ── Screen edges (inside [SafeArea]) ─────────────────────────────────────

  static const double screenHorizontal = AppSpacing.s20;
  static const double screenTop = AppSpacing.s12;
  static const double screenBottom = AppSpacing.s64;

  static EdgeInsets get screenPadding => EdgeInsets.fromLTRB(
        screenHorizontal,
        screenTop,
        screenHorizontal,
        screenBottom,
      );

  static EdgeInsets get screenPaddingHorizontal =>
      EdgeInsets.symmetric(horizontal: screenHorizontal);

  // ── Vertical section rhythm ──────────────────────────────────────────────

  static const double sectionGap = AppSpacing.s32;
  static const double sectionGapMedium = AppSpacing.s24;
  static const double sectionGapLarge = AppSpacing.s48;
  static const double labelToContent = AppSpacing.s16;
  static const double titleToSubtitle = AppSpacing.s12;
  static const double subtitleToBody = AppSpacing.s16;

  // ── Grid ─────────────────────────────────────────────────────────────────

  static const double gridGap = AppSpacing.s16;
  static const double gridGapLarge = AppSpacing.s24;

  // ── Status header ─────────────────────────────────────────────────────────

  static const double statusHeaderHeight = 48;
  /// Circular header actions meet the a11y touch floor (≥44).
  static const double headerActionSize = 44;
  static const double headerIconSize = AppSpacing.s20;
  static const double headerSideMinWidth = 96;

  // ── Bottom navigation (layout only) ──────────────────────────────────────

  static const double navBarHeight = 60;
  static const double navBarMarginH = AppSpacing.s16;
  static const double navBarMarginBottom = 8;
  static const double navItemInset = 6;
  static const double navIconSize = 22;
  static const double navLabelSize = 11;
  /// Minimum interactive size for nav chips and chrome controls.
  static const double minTouchTarget = 44;

  /// Breathing room above the cleared nav / keyboard — not a magic screen hack.
  static const double contentBottomBreath = AppSpacing.s16;

  /// Fixed clearance for the floating shell bar (no keyboard branch).
  /// Use for [OraclyBottomBar.totalHeight] and layout math that must stay stable.
  static double floatingNavClearance(BuildContext context) {
    final safe = MediaQuery.paddingOf(context).bottom;
    return navBarHeight + navBarMarginBottom + safe + contentBottomBreath;
  }

  /// ONE clearance for content under the shell floating bottom bar.
  ///
  /// Includes: nav bar height + bar margin + system home-indicator padding +
  /// [contentBottomBreath].
  ///
  /// Keyboard: when [MediaQuery] viewInsets are non-zero and the ambient
  /// [Scaffold] already resizes (`resizeToAvoidBottomInset: true`, the
  /// OraclyScaffold default), keyboard lift is already applied — but with
  /// [Scaffold.extendBody] the floating bar still overlays the body, so nav
  /// height + margin + breath stay. When the scaffold does not resize, pass
  /// [scaffoldResizesForKeyboard]: false so the inset also lifts with the
  /// keyboard.
  ///
  /// Modal sheets that cover the nav: use [sheetBottomInset] instead.
  ///
  /// Do not invent per-screen 100/120/150 paddings — call this.
  static double scrollBottomInset(
    BuildContext context, {
    bool scaffoldResizesForKeyboard = true,
  }) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    if (keyboard <= 0) return floatingNavClearance(context);
    // Floating bar remains above the keyboard and still overlays body.
    final overlayClearance =
        navBarHeight + navBarMarginBottom + contentBottomBreath;
    if (scaffoldResizesForKeyboard) return overlayClearance;
    return keyboard + overlayClearance;
  }

  /// Bottom clearance for modal sheets that already cover the floating nav.
  /// Keyboard + home indicator + breath — never invent per-sheet magic numbers.
  static double sheetBottomInset(BuildContext context) {
    final safe = MediaQuery.paddingOf(context).bottom;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return keyboard + safe + contentBottomBreath;
  }

  /// Alias — prefer [scrollBottomInset] at call sites.
  static double contentBottomInset(
    BuildContext context, {
    bool scaffoldResizesForKeyboard = true,
  }) =>
      scrollBottomInset(
        context,
        scaffoldResizesForKeyboard: scaffoldResizesForKeyboard,
      );

  /// Convenience padding for scroll views / chambers.
  static EdgeInsets scrollContentPadding(
    BuildContext context, {
    double? horizontal,
    double top = 0,
    bool scaffoldResizesForKeyboard = true,
  }) {
    final h = horizontal ?? screenHorizontal;
    return EdgeInsets.fromLTRB(
      h,
      top,
      h,
      scrollBottomInset(
        context,
        scaffoldResizesForKeyboard: scaffoldResizesForKeyboard,
      ),
    );
  }

  // ── Responsive breakpoints ───────────────────────────────────────────────

  static const double tabletBreakpoint = 600;

  /// Art-direction phone canvases — no overflow at these widths.
  static const List<double> phoneWidths = [360, 375, 390, 411, 430, 600];

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletBreakpoint;

  static bool isCompactPhone(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 380;

  /// Horizontal inset that preserves edge rhythm without starving wide phones.
  static double horizontalInset(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= tabletBreakpoint) return AppSpacing.s32;
    if (width < 360) return AppSpacing.s16;
    return screenHorizontal;
  }

  /// Max width for a content column inside the viewport.
  ///
  /// Phones use the full width (padding supplies gutters). Tablets soft-cap
  /// for readable line length — never a phone-sized 430 island.
  static double contentMaxWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (isTablet(context)) {
      return width.clamp(0, maxContentWidth).toDouble();
    }
    return width;
  }

  /// Alias used across screens — prefer [contentMaxWidth] for new code.
  static double contentWidth(BuildContext context) => contentMaxWidth(context);

  static EdgeInsets responsiveScreenPadding(BuildContext context) {
    final horizontal = horizontalInset(context);
    return EdgeInsets.fromLTRB(
      horizontal,
      referenceScreenTop,
      horizontal,
      scrollBottomInset(context),
    );
  }

  // ── Card proportions ─────────────────────────────────────────────────────

  static const double quickActionCardHeight = 168;
  static const double exploreRowHeight = 132;
  static const double exploreCardWidth = 148;
  static const double exploreCardWidthWide = 156;
  static const double heroViewportFraction = 0.40;

  // ── Reference polish ─────────────────────────────────────────────────────

  static const double referenceScreenTop = AppSpacing.s12;
  static const double referenceSectionGap = AppSpacing.s12;
  static const double referenceSectionGapLarge = AppSpacing.s20;
  static const double referenceSectionLabelToContent = AppSpacing.s8;
  static const double referenceIconWell = 36;
  static const double referenceIconSize = 18;
  static const double referencePrimaryButtonHeight = 44;
  static const EdgeInsets referencePrimaryButtonPadding =
      EdgeInsets.symmetric(horizontal: 18, vertical: 10);
  static const EdgeInsets referenceOutlineButtonPadding =
      EdgeInsets.symmetric(horizontal: 14, vertical: 7);
}
