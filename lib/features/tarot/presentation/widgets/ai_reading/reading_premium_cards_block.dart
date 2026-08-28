/// Card tiles inside the premium reading stack.
library;

import 'package:flutter/material.dart';

import '../../../copy/tarot_polish_copy.dart';
import '../../../domain/models/reading_session.dart';
import '../../../reading/reading_card_beat.dart';
import '../../../reading/reading_words.dart';
import 'ai_reading_content.dart';
import 'reading_arrive.dart';
import 'reading_card_message.dart';
import 'reading_story_card_tile.dart';

class ReadingPremiumCardsBlock extends StatelessWidget {
  const ReadingPremiumCardsBlock({
    super.key,
    required this.content,
    required this.sectionMaster,
  });

  final AiReadingContent content;
  final double sectionMaster;

  @override
  Widget build(BuildContext context) {
    final cards = content.drawnCards;
    if (cards.isEmpty) {
      return ReadingTileArrive(
        index: 0,
        master: sectionMaster,
        child: _fallbackTile(),
      );
    }
    return Column(
      children: [
        for (var i = 0; i < cards.length; i++)
          ReadingTileArrive(
            index: i,
            master: sectionMaster,
            child: _tile(cards[i]),
          ),
      ],
    );
  }

  Widget _tile(TarotDrawnCard card) {
    return ReadingStoryCardTile(
      name: card.localizedName,
      position: card.localizedPosition,
      insight: ReadingCardMessage.insight(card),
      detail: ReadingCardMessage.detailSolo(
        card,
        question: content.userQuestion,
      ),
    );
  }

  Widget _fallbackTile() {
    final body = content.cardReadings.trim();
    if (body.isEmpty) return const SizedBox.shrink();
    return ReadingStoryCardTile(
      name: content.cardName,
      position: content.spreadLabel ?? TarotPolishCopy.cardField,
      insight: ReadingWords.clause(body),
      detail: ReadingCardBeat.clip(body),
    );
  }
}
