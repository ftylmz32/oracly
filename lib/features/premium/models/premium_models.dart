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

  static const benefits = [
    PremiumBenefit(
      emoji: '∞',
      title: 'Sınırsız Tarot Açılımı',
      description: 'Günlük limit olmadan istediğin kadar açılım yapabilirsin.',
      icon: Icons.all_inclusive_rounded,
    ),
    PremiumBenefit(
      emoji: '🤖',
      title: 'Daha Derin OR Yorumları',
      description: 'Kişisel bağlamına göre genişletilmiş yansımalar.',
      icon: Icons.psychology_alt_rounded,
    ),
    PremiumBenefit(
      emoji: '📅',
      title: 'Geçmiş Açılımlar',
      description: 'Tüm açılımlarını kişisel günlüğünde sakla.',
      icon: Icons.auto_stories_rounded,
    ),
    PremiumBenefit(
      emoji: '🌙',
      title: 'Günlük Kozmik Rehber',
      description: 'Her sabah sakin bir enerji özeti.',
      icon: Icons.nightlight_round,
    ),
    PremiumBenefit(
      emoji: '⭐',
      title: 'Premium Desteler',
      description: 'Ek sanat desteleri ve kart koleksiyonları.',
      icon: Icons.style_rounded,
    ),
    PremiumBenefit(
      emoji: '🎴',
      title: 'Akıcı Kart Animasyonları',
      description: 'Açılım ve kart geçişlerinde daha akıcı hareket.',
      icon: Icons.animation_rounded,
    ),
    PremiumBenefit(
      emoji: '🔮',
      title: 'Kişisel Enerji Özeti',
      description: 'Günlük enerji ve odak notları.',
      icon: Icons.bubble_chart_rounded,
    ),
    PremiumBenefit(
      emoji: '📈',
      title: 'Okuma Ritmi',
      description: 'Açılımlarını zaman içinde gör — baskı yok.',
      icon: Icons.trending_up_rounded,
    ),
  ];

  static const comparisonRows = [
    ('Sınırsız Tarot Açılımı', false, true),
    ('Daha Derin OR Yorumları', false, true),
    ('Geçmiş Açılımlar', false, true),
    ('Günlük Kozmik Rehber', false, true),
    ('Premium Desteler', false, true),
    ('Akıcı Kart Animasyonları', false, true),
    ('Enerji Özeti', false, true),
    ('Okuma Ritmi', false, true),
    ('Temel AI Yorumu', true, true),
    ('Günlük 1 Açılım', true, false),
  ];
}
