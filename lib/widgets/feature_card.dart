import 'package:flutter/material.dart';

import '../core/design_system/premium_cards/premium_horizontal_card.dart';

/// Legacy feature row — delegates to [PremiumHorizontalCard].
class FeatureCard extends StatelessWidget {
  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumHorizontalCard(
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: onTap,
    );
  }
}
