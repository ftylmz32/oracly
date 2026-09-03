/// Premium tactile spread choice with mini layout preview.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/oracly_brand_signature.dart';
import '../../domain/models/tarot_spread.dart';

class RitualSpreadChoiceCard extends StatelessWidget {
  const RitualSpreadChoiceCard({
    super.key,
    required this.spread,
    required this.selected,
    required this.onTap,
  });

  final TarotSpreadType spread;
  final bool selected;
  final VoidCallback onTap;

  String get _title => switch (spread) {
        TarotSpreadType.single => OraclyL10n.t('tarot.spread.single.banner'),
        TarotSpreadType.threeCard =>
          OraclyL10n.t('tarot.spread.threeCard.banner_short'),
        TarotSpreadType.fiveCard => OraclyL10n.t('tarot.spread.fiveCard.banner'),
        TarotSpreadType.sevenCard =>
          OraclyL10n.t('tarot.spread.sevenCard.banner'),
        TarotSpreadType.celticCross =>
          OraclyL10n.t('tarot.spread.celticCross.banner'),
      };

  String get _cardCountLabel => OraclyL10n
      .t('tarot.spread.card_count')
      .replaceAll('{count}', '${spread.cardCount}');

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: OraclySignatureMotion.press,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: AppRadius.lg,
          color: const Color(0xFF0C0916),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: selected ? 0.72 : 0.28),
            width: selected ? 1.4 : 0.9,
          ),
        ),
        child: Row(
          children: [
            _LayoutPreview(count: spread.cardCount.clamp(1, 5)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.gold,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _cardCountLabel,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LayoutPreview extends StatelessWidget {
  const _LayoutPreview({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 48,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(width: 3),
            Container(
              width: count > 3 ? 10 : 14,
              height: count > 3 ? 16 : 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.55),
                ),
                color: const Color(0xFF1A1028),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
