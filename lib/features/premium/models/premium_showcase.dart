/// Above-fold Premium pillars — DEPTH / CONTINUITY / PERSONALIZATION.
library;

import 'package:flutter/material.dart';

import '../../../core/copy/premium_copy.dart';
import 'premium_models.dart';

abstract final class PremiumShowcase {
  PremiumShowcase._();

  static List<PremiumBenefit> get benefits => [
        PremiumBenefit(
          title: PremiumCopy.benefitDepthTitle,
          description: PremiumCopy.benefitDepthBody,
          icon: Icons.layers_outlined,
          action: PremiumBenefitAction.depth,
          requiresPremium: true,
        ),
        PremiumBenefit(
          title: PremiumCopy.benefitContinuityTitle,
          description: PremiumCopy.benefitContinuityBody,
          icon: Icons.timeline_outlined,
          action: PremiumBenefitAction.continuity,
          requiresPremium: true,
        ),
        PremiumBenefit(
          title: PremiumCopy.benefitPersonalizationTitle,
          description: PremiumCopy.benefitPersonalizationBody,
          icon: Icons.auto_awesome_outlined,
          action: PremiumBenefitAction.personalization,
          requiresPremium: true,
        ),
      ];
}