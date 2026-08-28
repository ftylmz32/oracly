/// Compact spread selector on the same table.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/oracly_brand_signature.dart';
import '../../domain/models/tarot_spread.dart';

class TarotTableSpreadOverlay extends StatelessWidget {
  const TarotTableSpreadOverlay({
    super.key,
    required this.selected,
    required this.onSelected,
    this.receded = false,
  });

  final TarotSpreadType? selected;
  final ValueChanged<TarotSpreadType> onSelected;
  final bool receded;

  static const options = [
    TarotSpreadType.single,
    TarotSpreadType.threeCard,
    TarotSpreadType.fiveCard,
  ];

  String _title(TarotSpreadType s) => switch (s) {
        TarotSpreadType.single => 'Tek Kart',
        TarotSpreadType.threeCard => '3 Kart',
        TarotSpreadType.fiveCard => 'Derin Açılım',
        _ => s.label,
      };

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: OraclySignatureMotion.pressRelease,
      opacity: receded ? 0 : 1,
      child: AnimatedSlide(
        duration: OraclySignatureMotion.pressRelease,
        offset: receded ? const Offset(0, 0.12) : Offset.zero,
        child: IgnorePointer(
          ignoring: receded,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                for (var i = 0; i < options.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _SpreadTile(
                      title: _title(options[i]),
                      count: options[i].cardCount.clamp(1, 5),
                      selected: selected == options[i],
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onSelected(options[i]);
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SpreadTile extends StatelessWidget {
  const _SpreadTile({
    required this.title,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: OraclySignatureMotion.press,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFF0C0916).withValues(alpha: 0.8),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: selected ? 0.75 : 0.25),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < count; i++) ...[
                  if (i > 0) const SizedBox(width: 2),
                  Container(
                    width: count > 3 ? 7 : 9,
                    height: count > 3 ? 11 : 14,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.55),
                      ),
                      color: const Color(0xFF1A1028),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.gold,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
