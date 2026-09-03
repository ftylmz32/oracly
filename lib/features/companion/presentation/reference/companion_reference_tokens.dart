/// OR chamber layout -- intimate reading room, never a chat dashboard.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_layout.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/oracly_chrome.dart';

abstract final class CompanionReferenceTokens {
  CompanionReferenceTokens._();

  static const double screenHorizontal = 11;
  static const double screenTop = OraclyChrome.screenTop;
  static const double headerHeight = OraclyChrome.headerHeight;

  static const double identityMark = 20;
  static const double idleCoreSize = 76;
  static const double orMark = 16;
  static const double messageGap = AppSpacing.s20;
  static const double inputBarTopGap = AppSpacing.s12;
  static const double promptGap = AppSpacing.s12;

  /// Measured from or_luna_chat_target (~426x922 logical @2x).
  static const double heroHeight = 252;
  static const double heroHeightCompact = 184;
  static const double heroPortraitFactor = 0.60;
  static const double heroCardOverlap = 54;
  static const BorderRadius heroPortraitRadius = BorderRadius.all(
    Radius.circular(20),
  );
  static const double avatarSize = 40;
  static const double avatarGap = 6;
  static const double quickPromptCardHeight = 56;
  static const double shortcutWellSize = 44;
  static const double shortcutRowHeight = 76;
  static const double daySeparatorGap = AppSpacing.s8;

  /// Reference border softness.
  static const double goldBorderHair = 0.16;
  static const double goldBorderSoft = 0.30;
  static const double violetBorderSoft = 0.40;
  static const double violetGlow = 0.16;

  /// User stays intimate; Luna uses reading width.
  static const double userBubbleMaxFactor = 0.68;
  static const double orBubbleMaxFactor = 0.80;
  static const double bubbleMaxFactor = userBubbleMaxFactor;

  static const EdgeInsets userMessagePadding = EdgeInsets.fromLTRB(
    14,
    11,
    14,
    11,
  );
  static const EdgeInsets orMessagePadding = EdgeInsets.fromLTRB(
    14,
    12,
    14,
    10,
  );
  static const EdgeInsets messagePadding = userMessagePadding;

  static BorderRadius userRadius = const BorderRadius.only(
    topLeft: Radius.circular(16),
    topRight: Radius.circular(16),
    bottomLeft: Radius.circular(16),
    bottomRight: Radius.circular(6),
  );

  static BorderRadius orRadius = BorderRadius.circular(16);

  static const BorderRadius introRadius = OraclyChrome.cardRadius;
  static const EdgeInsets introPadding = EdgeInsets.all(16);
  static const BorderRadius primaryButtonRadius = OraclyChrome.pillRadius;

  static const double inputBarHeight = OraclyChrome.buttonHeight;
  static const double composerMinHeight = 56;
  static const int composerMaxLines = 5;
  static const BorderRadius inputRadius = BorderRadius.all(Radius.circular(22));
  static const EdgeInsets inputPadding = EdgeInsets.fromLTRB(8, 8, 8, 8);
  static const EdgeInsets fieldPadding = EdgeInsets.fromLTRB(6, 10, 6, 10);

  static const double composerControl = 44;
  static const double nearBottomPx = 140;

  static bool isShortViewport(BuildContext context) =>
      MediaQuery.sizeOf(context).height < 640;

  static bool isVeryShortViewport(BuildContext context) =>
      MediaQuery.sizeOf(context).height < 600;

  static double idleCoreFor(BuildContext context) {
    if (isVeryShortViewport(context)) return 60;
    if (isShortViewport(context)) return 68;
    return idleCoreSize;
  }

  static double premiumEmblemFor(BuildContext context) {
    if (isVeryShortViewport(context)) return 68;
    if (isShortViewport(context)) return 76;
    return 92;
  }

  static double verticalBreathFor(BuildContext context) {
    if (isShortViewport(context)) return AppSpacing.s8;
    return AppSpacing.s12;
  }

  static double sectionGapFor(BuildContext context) {
    if (isShortViewport(context)) return AppSpacing.s16;
    return AppSpacing.s24;
  }

  static Widget fillScrollPane({
    required BoxConstraints constraints,
    required EdgeInsetsGeometry padding,
    required List<Widget> children,
    MainAxisAlignment alignment = MainAxisAlignment.start,
  }) {
    return SingleChildScrollView(
      padding: padding,
      physics: const ClampingScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: constraints.hasBoundedHeight ? constraints.maxHeight : 0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: alignment,
          children: children,
        ),
      ),
    );
  }

  static EdgeInsets shellSafePadding(Size size) {
    final bottom =
        AppLayout.navBarHeight +
        AppLayout.navBarMarginBottom +
        AppLayout.contentBottomBreath +
        (size.height >= 800 ? 34.0 : 24.0);
    return EdgeInsets.only(
      top: size.height >= 800 ? 44.0 : 28.0,
      bottom: bottom,
    );
  }
}
