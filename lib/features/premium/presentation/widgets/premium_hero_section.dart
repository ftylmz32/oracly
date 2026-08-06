/// OR-1090 — Animated premium crystal hero.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../tarot/components/tarot_crystal_orb.dart';
import '../../models/premium_models.dart';

class PremiumHeroSection extends StatelessWidget {
  const PremiumHeroSection({
    super.key,
    required this.entrance,
  });

  final double entrance;

  @override
  Widget build(BuildContext context) {
    final slide = (1 - entrance) * 24;
    return Opacity(
      opacity: entrance.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, slide),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: Center(
                child: TarotCrystalOrb(size: AppSpacing.xxl * 3 + AppSpacing.lg),
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFF0D77A), Color(0xFFD4AF37), Color(0xFFB8941F)],
              ).createShader(bounds),
              child: Text(
                PremiumCatalogue.title,
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              PremiumCatalogue.subtitle,
              textAlign: TextAlign.center,
              style: ReadingTypography.body(),
            ),
          ],
        ),
      ),
    );
  }
}
