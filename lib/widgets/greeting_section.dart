import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/glass_card.dart';
import 'hero_orb.dart';

class GreetingSection extends StatelessWidget {
  const GreetingSection({
    super.key,
    required this.greeting,
    required this.message,
  });

  final String greeting;
  final String message;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 28,
      ),
      child: Column(
        children: [
          const HeroOrb(
            size: 130,
          ),

          const SizedBox(height: 24),

          Text(
            greeting,
            textAlign: TextAlign.center,
            style: AppTextStyles.heading,
          ),

          const SizedBox(height: 12),

          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.body,
          ),
        ],
      ),
    );
  }
}