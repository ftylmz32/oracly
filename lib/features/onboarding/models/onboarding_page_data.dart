/// OR-1120 — Onboarding page content model.
library;

import 'package:flutter/material.dart';

class OnboardingPageData {
  const OnboardingPageData({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.iconAsset,
    this.gradientColors,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String? iconAsset;
  final List<Color>? gradientColors;
}
