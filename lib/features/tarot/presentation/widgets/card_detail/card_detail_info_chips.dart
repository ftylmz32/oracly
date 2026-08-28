/// OR-1080 — Premium metadata chips for card encyclopedia.
library;

import 'package:flutter/material.dart';

import '../../../../../core/l10n/oracly_format.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import 'card_detail_models.dart';

class CardDetailInfoChips extends StatelessWidget {
  const CardDetailInfoChips({
    super.key,
    required this.content,
    required this.entrance,
  });

  final CardDetailContent content;
  final double entrance;

  @override
  Widget build(BuildContext context) {
    final slide = (1 - entrance) * 20;
    return Opacity(
      opacity: entrance.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, slide),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _MetaChip(
                    label: 'Arkan',
                    value: content.arcanaType,
                    icon: Icons.auto_awesome_rounded,
                    accent: content.accentColor,
                  ),
                  _MetaChip(
                    label: 'Element',
                    value: content.element,
                    icon: Icons.water_drop_outlined,
                    accent: content.accentColor,
                  ),
                  _MetaChip(
                    label: 'Gezegen',
                    value: content.planet,
                    icon: Icons.public_rounded,
                    accent: content.accentColor,
                  ),
                  _MetaChip(
                    label: 'Burç',
                    value: content.zodiac,
                    icon: Icons.star_outline_rounded,
                    accent: content.accentColor,
                  ),
                  _MetaChip(
                    label: 'Numara',
                    value: OraclyFormat.cardNumber(content.number),
                    icon: Icons.tag_rounded,
                    accent: content.accentColor,
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.md),
              Text(
                'Anahtar Kelimeler',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textHint,
                ),
              ),
              SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: content.keywords
                    .map(
                      (k) => _KeywordChip(
                        label: k,
                        accent: content.accentColor,
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        borderRadius: AppRadius.md,
        color: AppColors.surface.withValues(alpha: 0.72),
        border: Border.all(
          color: accent.withValues(alpha: 0.35),
          width: AppBorderWidth.hairline,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accent),
          SizedBox(width: AppSpacing.xs),
          Text(
            '$label: ',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textHint,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.goldLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _KeywordChip extends StatelessWidget {
  const _KeywordChip({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm - 2,
      ),
      decoration: BoxDecoration(
        borderRadius: AppRadius.round,
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.28),
            AppColors.purple.withValues(alpha: 0.22),
          ],
        ),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.24),
          width: AppBorderWidth.hairline,
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelMedium.copyWith(
          color: AppColors.goldLight,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
