/// OR chamber layout — intimate reading room, never a chat dashboard.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/oracly_chrome.dart';

abstract final class CompanionReferenceTokens {
  CompanionReferenceTokens._();

  static const double screenHorizontal = OraclyChrome.screenSide;
  static const double screenTop = OraclyChrome.screenTop;
  static const double headerHeight = OraclyChrome.headerHeight;

  static const double identityMark = 20;
  static const double idleCoreSize = 76;
  static const double orMark = 16;
  static const double messageGap = AppSpacing.s24;
  static const double inputBarTopGap = AppSpacing.s12;
  static const double promptGap = AppSpacing.s12;

  /// User stays intimate; OR uses reading width — not twin chat bubbles.
  static const double userBubbleMaxFactor = 0.68;
  static const double orBubbleMaxFactor = 0.86;
  static const double bubbleMaxFactor = userBubbleMaxFactor;

  static const EdgeInsets userMessagePadding =
      EdgeInsets.fromLTRB(14, 11, 14, 11);
  static const EdgeInsets orMessagePadding =
      EdgeInsets.fromLTRB(0, 4, 4, 8);
  static const EdgeInsets messagePadding = userMessagePadding;

  /// Warm spoken note — soft corners, not a messenger pill.
  static BorderRadius userRadius = const BorderRadius.only(
    topLeft: Radius.circular(16),
    topRight: Radius.circular(16),
    bottomLeft: Radius.circular(16),
    bottomRight: Radius.circular(8),
  );

  /// OR reading plate — calm, editorial, spacious.
  static BorderRadius orRadius = const BorderRadius.only(
    topLeft: Radius.circular(4),
    topRight: Radius.circular(16),
    bottomLeft: Radius.circular(16),
    bottomRight: Radius.circular(16),
  );

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
}
