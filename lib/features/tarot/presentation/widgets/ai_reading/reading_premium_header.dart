/// OR-301 — Premium reading header with living card and staggered text.
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/reading_typography.dart';
import 'ai_reading_content.dart';
import 'reading_breathing_card.dart';
import 'reading_element_theme.dart';
import 'reading_premium_animations.dart';
import 'reading_premium_utils.dart';
import 'reading_sacred_rhythm.dart';

class ReadingPremiumHeader extends StatelessWidget {
  const ReadingPremiumHeader({
    super.key,
    required this.content,
    required this.progress,
    this.exitProgress = 0,
    this.cardActive = true,
  });

  final AiReadingContent content;
  final double progress;
  final double exitProgress;
  final bool cardActive;

  @override
  Widget build(BuildContext context) {
    final card = ReadingPremiumUtils.primaryCard(content);
    final elementTheme = ReadingElementTheme.fromCard(card);
    final cardReveal = readingPremiumHeaderCardProgress(progress);
    final titleReveal = readingPremiumHeaderTitleProgress(progress);
    final keywordsReveal = readingPremiumHeaderBadgesProgress(progress);
    final subtitleReveal = readingPremiumHeaderSubtitleProgress(progress);
    final cardVisible = (1 - exitProgress).clamp(0.0, 1.0);

    return Column(
      children: [
        Opacity(
          opacity: (cardReveal * cardVisible).clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - cardReveal) * 14),
            child: ReadingBreathingCard(
              imageAsset: content.imageAsset,
              elementTheme: elementTheme,
              rarityColor: content.rarityColor,
              width: ReadingSacredRhythm.companionCardWidth,
              active: cardActive,
            ),
          ),
        ),
        SizedBox(height: ReadingSacredRhythm.afterCard),
        Opacity(
          opacity: (readingPremiumHeaderProgress(progress) * (1 - exitProgress))
              .clamp(0.0, 1.0),
          child: Column(
            children: [
              _StaggerReveal(
                progress: titleReveal,
                exitProgress: exitProgress,
                slide: 16,
                child: Text(
                  content.cardName,
                  textAlign: TextAlign.center,
                  style: ReadingTypography.cardTitle(),
                ),
              ),
              SizedBox(height: ReadingSacredRhythm.afterTitle),
              _StaggerReveal(
                progress: keywordsReveal,
                exitProgress: exitProgress,
                slide: 12,
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _KeywordChip(
                      label: ReadingPremiumUtils.elementLabel(card),
                      icon: Icons.water_drop_outlined,
                      color: elementTheme.glowColor,
                    ),
                    _KeywordChip(
                      label: ReadingPremiumUtils.arcanaLabel(card),
                      icon: Icons.auto_awesome_rounded,
                      color: AppColors.gold,
                    ),
                    _KeywordChip(
                      label: ReadingPremiumUtils.rarityLabel(
                        card,
                        content.rarityColor,
                      ),
                      icon: Icons.diamond_outlined,
                      color: content.rarityColor,
                    ),
                  ],
                ),
              ),
              SizedBox(height: ReadingSacredRhythm.afterKeywords),
              _StaggerReveal(
                progress: subtitleReveal,
                exitProgress: exitProgress,
                slide: 10,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: Text(
                    content.tagline,
                    textAlign: TextAlign.center,
                    style: ReadingTypography.opening(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StaggerReveal extends StatelessWidget {
  const _StaggerReveal({
    required this.progress,
    required this.exitProgress,
    required this.slide,
    required this.child,
  });

  final double progress;
  final double exitProgress;
  final double slide;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: (progress * (1 - exitProgress)).clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, (1 - progress) * slide + exitProgress * 12),
        child: child,
      ),
    );
  }
}

class _KeywordChip extends StatelessWidget {
  const _KeywordChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 1,
      ),
      decoration: BoxDecoration(
        borderRadius: AppRadius.round,
        color: AppColors.surface.withValues(alpha: 0.32),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.22),
          width: AppBorderWidth.hairline,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color.withValues(alpha: 0.75)),
          SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
