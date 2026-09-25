/// Compact spread selector on the same table.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/oracly_brand_signature.dart';
import '../../domain/models/tarot_spread.dart';
import 'tarot_table_spread_tile.dart';

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
        TarotSpreadType.single => OraclyL10n.t('tarot.spread.single'),
        TarotSpreadType.threeCard =>
          OraclyL10n.t('tarot.spread.threeCard.compact'),
        TarotSpreadType.fiveCard => OraclyL10n.t('tarot.spread.fiveCard'),
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
                    child: TarotTableSpreadTile(
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
