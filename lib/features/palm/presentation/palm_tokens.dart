/// El Falı layout tokens — same midnight / gold family as Coffee.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/app_spacing.dart';
import '../../../core/design_system/oracly_chrome.dart';

abstract final class PalmTokens {
  PalmTokens._();

  static const double screenHorizontal = OraclyChrome.screenSide;
  static const double screenTop = OraclyChrome.screenTop;
  static const double gap = AppSpacing.s8;
  static const BorderRadius heroRadius = OraclyChrome.heroRadius;
  static const BorderRadius cardRadius = OraclyChrome.cardRadius;
  static const Color cream = OraclyChrome.cream;
  static const Color veilInk = Color(0xFF080512);
  static const Color amberGlow = Color(0xFFC47A2A);

  static List<BoxShadow> frameShadows({bool hero = false}) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: hero ? 0.50 : 0.36),
          blurRadius: hero ? 28 : 16,
          offset: Offset(0, hero ? 14 : 8),
          spreadRadius: hero ? -4 : -2,
        ),
        BoxShadow(
          color: OraclyChrome.gold.withValues(alpha: hero ? 0.10 : 0.08),
          blurRadius: hero ? 20 : 12,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: amberGlow.withValues(alpha: hero ? 0.08 : 0.05),
          blurRadius: hero ? 32 : 18,
          offset: Offset(hero ? -4 : -2, hero ? 8 : 5),
        ),
      ];
}

