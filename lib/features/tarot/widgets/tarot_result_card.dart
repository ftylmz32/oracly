import 'package:flutter/material.dart';

import '../copy/tarot_l10n.dart';
import '../models/tarot_card.dart';
import 'tarot_result_card_art.dart';
import 'tarot_tag_chip.dart';
import 'tarot_typography.dart';

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
      return _CompactRow(card: card, positionLabel: positionLabel);
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 680),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => Opacity(opacity: v, child: Transform.scale(scale: 0.97 + v * 0.03, child: child)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TarotCardArt(image: card.image, height: 200, width: 130),
          const SizedBox(width: 16),
          Expanded(child: _CardInfo(card: card, positionLabel: positionLabel)),
        ],
      ),
    );
  }
}

class _CardInfo extends StatelessWidget {
  const _CardInfo({required this.card, this.positionLabel});
  final TarotCard card;
  final String? positionLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (positionLabel != null) ...[
          Text(positionLabel!.toUpperCase(), style: TarotTypography.captionMuted(size: 10)),
          const SizedBox(height: 6),
        ],
        Text(TarotL10n.cardNameOf(card), style: TarotTypography.cardTitleGold(size: 20)),
        const SizedBox(height: 4),
        Text(card.summary.split('.').first, style: TarotTypography.captionMuted(size: 12)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var i = 0; i < card.keywords.take(4).length; i++)
              TarotTagChip(
                label: card.keywords[i],
                color: TarotTagChip.colorAt(i),
                icon: Icons.circle,
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '"${card.summary}"',
          style: TarotTypography.quote(size: 12),
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _CompactRow extends StatelessWidget {
  const _CompactRow({required this.card, this.positionLabel});
  final TarotCard card;
  final String? positionLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TarotCardArt(image: card.image, compact: true),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (positionLabel != null)
                Text(positionLabel!, style: TarotTypography.captionMuted(size: 10)),
              Text(TarotL10n.cardNameOf(card), style: TarotTypography.cardTitleGold(size: 16)),
              const SizedBox(height: 4),
              Text(card.summary, maxLines: 2, overflow: TextOverflow.ellipsis, style: TarotTypography.captionMuted()),
            ],
          ),
        ),
      ],
    );
  }
}
