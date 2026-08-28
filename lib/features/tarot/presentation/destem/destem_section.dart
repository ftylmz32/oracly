/// One Destem arcana / suit block.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../deck/oracly_tarot_card.dart';
import 'destem_card_tile.dart';

class DestemSection extends StatelessWidget {
  const DestemSection({
    super.key,
    required this.title,
    required this.cards,
    required this.seenIds,
    required this.onOpen,
  });

  final String title;
  final List<OraclyTarotCard> cards;
  final Set<String> seenIds;
  final ValueChanged<OraclyTarotCard> onOpen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: ReadingTypography.sectionLabel(
              color: OraclyChrome.goldLight.withValues(alpha: 0.88),
              fontSize: 12,
            ),
          ),
          SizedBox(height: AppSpacing.s12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cards.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 18,
              crossAxisSpacing: 14,
              childAspectRatio: 0.58,
            ),
            itemBuilder: (context, index) {
              final card = cards[index];
              return DestemCardTile(
                card: card,
                seen: seenIds.contains(card.id),
                onTap: () => onOpen(card),
              );
            },
          ),
        ],
      ),
    );
  }
}
