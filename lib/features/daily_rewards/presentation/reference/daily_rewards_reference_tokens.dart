/// Layout tokens for Günlük Ödüller.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_layout.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';

abstract final class DailyRewardsReferenceTokens {
  DailyRewardsReferenceTokens._();

  static const double screenHorizontal = AppLayout.screenHorizontal;
  static const double screenTop = AppLayout.referenceScreenTop;
  static const double headerHeight = AppLayout.statusHeaderHeight;
  static const double headerToContent = AppSpacing.s12;
  static const double sectionGap = AppSpacing.s12;

  static const BorderRadius cardRadius = AppRadius.s20;
}
