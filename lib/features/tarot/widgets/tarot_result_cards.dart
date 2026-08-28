import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../copy/tarot_l10n.dart';
import '../models/tarot_card.dart';
import 'tarot_result_card.dart';

class TarotResultCards extends StatelessWidget {
  const TarotResultCards({
    super.key,
    required this.cards,
  });

  final List<TarotCard> cards;

  String? _positionLabel(int index) {
    if (cards.length != 3 || index > 2) {
      return null;
    }
    return [
      TarotL10n.position('past'),
      TarotL10n.position('present'),
      TarotL10n.position('direction'),
    ][index];
  }

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TarotResultCard(
          card: cards.first,
          positionLabel: _positionLabel(0),
        ),
        if (cards.length > 1) ...[
          const SizedBox(height: 20),
          for (var i = 1; i < cards.length; i++) ...[
            TarotResultCard(
              card: cards[i],
              compact: true,
              positionLabel: _positionLabel(i),
            ),
            if (i < cards.length - 1)
              const SizedBox(height: AppSpacing.md),
          ],
        ],
      ],
    );
  }
}
