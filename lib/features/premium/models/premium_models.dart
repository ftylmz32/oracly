/// Premium catalogue — only working features. No invented prices.
library;

import 'package:flutter/material.dart';

import '../../../core/copy/premium_copy.dart';
import '../../../core/domain/models/premium_plan.dart';

enum PremiumPlanType {
  monthly('Aylık'),
  yearly('Yıllık'),
  lifetime('Ömür Boyu');

  const PremiumPlanType(this.label);
  final String label;
  String get subtitle => switch (this) {
        monthly => PremiumCopy.planMonthlySubtitle,
        yearly => PremiumCopy.planYearlySubtitle,
        lifetime => PremiumCopy.planLifetimeSubtitle,
      };
  String get price => PremiumCopy.planPricePending;
}

enum PremiumBenefitAction {
  soulMate,
  coffee,
  palm,
  discovery,
  companion,
  daily,
  journey,
  depth,
  continuity,
  personalization,
  none,
}

class PremiumBenefit {
  const PremiumBenefit({
    required this.title,
    required this.description,
    required this.icon,
    required this.action,
    this.requiresPremium = false,
  });

  final String title;
  final String description;
  final IconData icon;
  final PremiumBenefitAction action;
  final bool requiresPremium;
}

abstract final class PremiumCatalogue {
  PremiumCatalogue._();

  static String get title => PremiumCopy.heroTitle;
  static String get subtitle => PremiumCopy.heroSubtitle;
  static String get benefitsSectionTitle => PremiumCopy.benefitsSectionTitle;

  static List<PremiumBenefit> get premiumExperiences => [
        for (final benefit in benefits)
          if (benefit.requiresPremium) benefit,
      ];

  static List<PremiumBenefit> get concretePremiumExperiences => [
        benefits.firstWhere((b) => b.action == PremiumBenefitAction.soulMate),
        benefits.firstWhere((b) => b.action == PremiumBenefitAction.companion),
        benefits.firstWhere((b) => b.action == PremiumBenefitAction.journey),
      ];

  static List<PremiumBenefit> get includedCapabilities => [
        for (final benefit in benefits)
          if (!benefit.requiresPremium) benefit,
      ];

  static List<PremiumBenefit> get benefits => [
        PremiumBenefit(
          title: PremiumCopy.benefitSoulmateTitle,
          description: PremiumCopy.benefitSoulmateBody,
          icon: Icons.favorite_border_rounded,
          action: PremiumBenefitAction.soulMate,
          requiresPremium: true,
        ),
        PremiumBenefit(
          title: PremiumCopy.benefitCoffeeTitle,
          description: PremiumCopy.benefitCoffeeBody,
          icon: Icons.local_cafe_outlined,
          action: PremiumBenefitAction.coffee,
        ),
        PremiumBenefit(
          title: PremiumCopy.benefitPalmTitle,
          description: PremiumCopy.benefitPalmBody,
          icon: Icons.back_hand_outlined,
          action: PremiumBenefitAction.palm,
        ),
        PremiumBenefit(
          title: PremiumCopy.benefitDiscoveryTitle,
          description: PremiumCopy.benefitDiscoveryBody,
          icon: Icons.insights_outlined,
          action: PremiumBenefitAction.discovery,
        ),
        PremiumBenefit(
          title: PremiumCopy.benefitOrTitle,
          description: PremiumCopy.benefitOrBody,
          icon: Icons.forum_outlined,
          action: PremiumBenefitAction.companion,
          requiresPremium: true,
        ),
        PremiumBenefit(
          title: PremiumCopy.benefitJourneyTitle,
          description: PremiumCopy.benefitJourneyBody,
          icon: Icons.auto_stories_outlined,
          action: PremiumBenefitAction.journey,
          requiresPremium: true,
        ),
        PremiumBenefit(
          title: PremiumCopy.benefitAtmosphereTitle,
          description: PremiumCopy.benefitAtmosphereBody,
          icon: Icons.wb_twilight_outlined,
          action: PremiumBenefitAction.daily,
        ),
      ];

  static List<PremiumBenefit> get showcaseBenefits => concretePremiumExperiences;

  static List<(String, bool, bool)> get comparisonRows => [
        for (final benefit in benefits)
          (benefit.title, !benefit.requiresPremium, true),
      ];

  static List<PremiumPlanModel> fallbackPlans() => [
        for (final type in PremiumPlanType.values)
          PremiumPlanModel(
            kind: PremiumPlanKind.values[type.index],
            label: type.label,
            price: PremiumCopy.planPricePending,
            subtitle: type.subtitle,
            isActive: false,
          ),
      ];
}
