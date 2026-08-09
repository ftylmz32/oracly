/// OR-1090 — Premium membership plan models.
library;

import 'package:flutter/material.dart';

import '../../../core/copy/premium_copy.dart';

enum PremiumPlanType {
  monthly('Aylık', '₺149,99/ay', PremiumCopy.planMonthlySubtitle),
  yearly('Yıllık', '₺899,99/yıl', PremiumCopy.planYearlySubtitle),
  lifetime('Ömür Boyu', '₺2.499,99', PremiumCopy.planLifetimeSubtitle);

  const PremiumPlanType(this.label, this.price, this.subtitle);
  final String label;
  final String price;
  final String subtitle;
}

/// One premium membership benefit.
class PremiumBenefit {
  const PremiumBenefit({
    required this.emoji,
    required this.title,
    required this.description,
    required this.icon,
  });

  final String emoji;
  final String title;
  final String description;
  final IconData icon;
}

abstract final class PremiumCatalogue {
  PremiumCatalogue._();

  static const title = PremiumCopy.heroTitle;
  static const subtitle = PremiumCopy.heroSubtitle;
  static const benefitsSectionTitle = PremiumCopy.benefitsSectionTitle;

  /// Planned-only catalogue — not presented as currently gated/available.
  static const benefits = [
    PremiumBenefit(
      emoji: '✦',
      title: 'Daha derin OR yansımaları',
      description: PremiumCopy.plannedBenefitLabel,
      icon: Icons.psychology_alt_rounded,
    ),
    PremiumBenefit(
      emoji: '⭐',
      title: 'Ek sanat desteleri',
      description: PremiumCopy.plannedBenefitLabel,
      icon: Icons.style_rounded,
    ),
    PremiumBenefit(
      emoji: '🌙',
      title: 'Kişisel günlük enerji notları',
      description: PremiumCopy.plannedBenefitLabel,
      icon: Icons.nightlight_round,
    ),
  ];

  /// Kept for legacy widgets; live PremiumScreen no longer shows this table.
  static const comparisonRows = <(String, bool, bool)>[];
}
