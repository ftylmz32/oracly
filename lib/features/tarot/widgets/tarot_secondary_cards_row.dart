import 'package:flutter/material.dart';

import '../models/tarot_card.dart';
import 'tarot_result_card_art.dart';
import 'tarot_typography.dart';

/// Compact row of additional drawn cards beneath the hero presentation.
class TarotSecondaryCardsRow extends StatelessWidget {
  const TarotSecondaryCardsRow({
    super.key,
    required this.cards,
    this.positionLabels = const [],
  });

  final List<TarotCard> cards;
  final List<String?> positionLabels;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Diğer Kartlar',
          textAlign: TextAlign.center,
          style: TarotTypography.sectionGold(size: 13),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 14,
          children: [
            for (var i = 0; i < cards.length; i++)
              _SecondaryCardTile(
                card: cards[i],
                positionLabel: i < positionLabels.length ? positionLabels[i] : null,
              ),
          ],
        ),
      ],
    );
  }
}

class _SecondaryCardTile extends StatelessWidget {
  const _SecondaryCardTile({
    required this.card,
    this.positionLabel,
  });

  final TarotCard card;
  final String? positionLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      child: Column(
        children: [
          TarotCardArt(image: card.image, compact: true),
          const SizedBox(height: 8),
          if (positionLabel != null)
            Text(
              positionLabel!,
              textAlign: TextAlign.center,
              style: TarotTypography.captionMuted(size: 9),
            ),
          Text(
            card.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TarotTypography.cardTitleGold(size: 11),
          ),
        ],
      ),
    );
  }
}
