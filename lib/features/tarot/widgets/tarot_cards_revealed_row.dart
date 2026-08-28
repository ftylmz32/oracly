import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import 'tarot_tag_chip.dart';
import 'tarot_typography.dart';

class TarotCardsRevealedRow extends StatelessWidget {
  const TarotCardsRevealedRow({super.key, required this.cardCount});

  final int cardCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('🔮 ', style: TarotTypography.body(size: 14)),
        Text(OraclyL10n.t('tarot.revealed_row'), style: TarotTypography.sectionGold(size: 15)),
        const Spacer(),
        TarotSpreadCountPill(count: cardCount),
      ],
    );
  }
}
