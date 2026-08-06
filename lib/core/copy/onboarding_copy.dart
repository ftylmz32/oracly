/// RC-012 — Calm onboarding copy: what ORACLY is, is not, and why it differs.
library;

import 'package:flutter/material.dart';

import '../../features/onboarding/models/onboarding_page_data.dart';
import '../constants/app_assets.dart';

abstract final class OnboardingCopy {
  OnboardingCopy._();

  static const skip = 'Atla';
  static const continueLabel = 'Devam';
  static const startFirstReading = 'İlk kartını çek';

  static const pages = <OnboardingPageData>[
    OnboardingPageData(
      title: 'ORACLY',
      subtitle:
          'Acele etmeden durabileceğin sakin bir alan. '
          'Düşünmek, yansımak ve kendini dinlemek için.',
      icon: Icons.auto_awesome_outlined,
    ),
    OnboardingPageData(
      title: 'Nasıl çalışır?',
      subtitle:
          'Bir kart seç. Bir an dur. Metni oku — '
          'cevap aramak zorunda değilsin, sadece dinle.',
      icon: Icons.style_outlined,
      iconAsset: AppAssets.featureTarot,
    ),
    OnboardingPageData(
      title: 'Ne değildir?',
      subtitle:
          'Kehanet değil. Aciliyet yok. '
          'Yorumlar bir davet — karar senin.',
      icon: Icons.favorite_border_rounded,
      gradientColors: [
        Color(0x44D4AF37),
        Color(0x224A148C),
      ],
    ),
  ];
}
