/// Reference-accurate layout tokens for the Settings screen.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/app_layout.dart';
import '../../../core/design_system/app_radius.dart';
import '../../../core/design_system/app_spacing.dart';

abstract final class SettingsReferenceTokens {
  SettingsReferenceTokens._();

  static const double screenHorizontal = AppLayout.screenHorizontal;
  static const double screenTop = AppLayout.referenceScreenTop;
  static const double headerHeight = AppLayout.statusHeaderHeight;

  static const double headerToProfile = AppSpacing.s12;
  static const double profileToFirstSection = AppLayout.referenceSectionGap;
  static const double sectionGap = AppLayout.referenceSectionGap;
  static const double sectionLabelToCard =
      AppLayout.referenceSectionLabelToContent;

  static const BorderRadius groupRadius = AppRadius.s20;
  static const BorderRadius profileRadius = AppRadius.s20;
  static const EdgeInsets profilePadding = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 12,
  );

  static const double profileAvatarSize = 48;
  static const double rowHeight = 62;
  static const EdgeInsets rowPadding = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 10,
  );
  static const double rowIconWell = AppLayout.referenceIconWell;
  static const BorderRadius rowIconRadius = AppRadius.s16;

  static const double switchWidth = 46;
  static const double switchHeight = 26;
  static const double switchThumbSize = 20;
}
