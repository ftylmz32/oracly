/// OR-1080 — Symbolism timeline with illustrated cards.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../../core/l10n/l10n.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import 'card_detail_locale.dart';
import 'card_detail_models.dart';

class CardDetailSymbolism extends StatelessWidget {
  const CardDetailSymbolism({
    super.key,
    required this.cardId,
    required this.symbols,
    required this.entrance,
    required this.accent,
  });

  final int cardId;
  final List<CardSymbolEntry> symbols;
  final double entrance;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final slide = (1 - entrance) * 18;
    final localized = CardDetailLocale.symbols(cardId: cardId, base: symbols);
    return Opacity(
      opacity: entrance.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, slide),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                OraclyL10n.t('tarot.card.symbolism'),
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.goldLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: AppSpacing.md),
              ...localized.asMap().entries.map((entry) {
                final index = entry.key;
                final symbol = entry.value;
                final isLast = index == localized.length - 1;
                return _SymbolTimelineTile(
                  symbol: symbol,
                  accent: accent,
                  showLine: !isLast,
                  index: index,
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _SymbolTimelineTile extends StatelessWidget {
  const _SymbolTimelineTile({
    required this.symbol,
    required this.accent,
    required this.showLine,
    required this.index,
  });

  final CardSymbolEntry symbol;
  final Color accent;
  final bool showLine;
  final int index;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        accent.withValues(alpha: 0.55),
                        AppColors.purpleDark,
                      ],
                    ),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.42),
                      width: AppBorderWidth.hairline,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.28),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Icon(
                    symbol.icon,
                    size: 14,
                    color: AppColors.goldLight,
                  ),
                ),
                if (showLine)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      margin: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            accent.withValues(alpha: 0.45),
                            AppColors.gold.withValues(alpha: 0.12),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.md),
              child: ClipRRect(
                borderRadius: AppRadius.lg,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.surfaceElevated.withValues(alpha: 0.9),
                          AppColors.surface.withValues(alpha: 0.82),
                        ],
                      ),
                      borderRadius: AppRadius.lg,
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.22),
                        width: AppBorderWidth.hairline,
                      ),
                    ),
                    child: Padding(
                      padding: AppSpacing.card,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            symbol.name,
                            style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.goldLight,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: AppSpacing.sm),
                          Text(
                            symbol.description,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.52,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
