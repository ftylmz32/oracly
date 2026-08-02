import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/tarot_card.dart';
import 'tarot_result_card_art.dart';
import 'tarot_result_card_compact.dart';

class TarotResultCard extends StatelessWidget {
  const TarotResultCard({
    super.key,
    required this.card,
    this.compact = false,
    this.positionLabel,
  });

  final TarotCard card;
  final bool compact;
  final String? positionLabel;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return TarotResultCardCompact(
        card: card,
        positionLabel: positionLabel,
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: 0.985 + (0.015 * value),
            child: child,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 26),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: AppGradients.glass,
          color: AppColors.glass.withValues(alpha: .55),
          border: Border.all(
            color: AppColors.glassBorder,
          ),
          boxShadow: AppShadows.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: TarotCardArt(
                image: card.image,
              ),
            ),
            const SizedBox(height: 28),
            if (positionLabel != null) ...[
              Text(
                positionLabel!,
                style: AppTextStyles.small.copyWith(
                  color: AppColors.textHint,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            Text(
              card.name,
              style: AppTextStyles.hero.copyWith(
                color: AppColors.gold.withValues(alpha: .92),
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                height: 1.2,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              card.summary,
              style: AppTextStyles.subtitle.copyWith(
                height: 1.65,
                color: AppColors.textSecondary,
              ),
            ),
            if (card.keywords.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: card.keywords
                    .take(3)
                    .map((k) => _KeywordChip(text: k))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _KeywordChip extends StatelessWidget {
  const _KeywordChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .04),
        borderRadius: AppRadius.round,
        border: Border.all(
          color: AppColors.gold.withValues(alpha: .14),
        ),
      ),
      child: Text(
        text,
        style: AppTextStyles.small.copyWith(
          color: AppColors.textSecondary,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
