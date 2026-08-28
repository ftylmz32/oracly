/// User-facing tarot insight for the clipboard — never IDs or source flags.
library;

import '../../../../../core/insight_copy/insight_copy_text.dart';
import '../../../copy/tarot_polish_copy.dart';
import 'ai_reading_content.dart';
import 'reading_card_message.dart';

abstract final class TarotInsightCopy {
  TarotInsightCopy._();

  static String fromContent(AiReadingContent content) {
    final narrative = content.luckyEnergy.trim().isNotEmpty
        ? content.luckyEnergy
        : content.generalMeaning;
    final direction = content.closingMessage.trim().isNotEmpty
        ? content.closingMessage
        : content.dailyAdvice;
    final cards = content.drawnCards;
    return InsightCopyText.joinBlocks([
      content.cardName,
      content.tagline,
      if (narrative.trim().isNotEmpty)
        '${TarotPolishCopy.storyTitle}\n$narrative',
      if (cards.isEmpty) content.cardReadings,
      for (var i = 0; i < cards.length; i++) ...[
        [
          cards[i].localizedName,
          cards[i].localizedPosition,
        ].where((p) => p.trim().isNotEmpty).join(' · '),
        ReadingCardMessage.insight(cards[i]),
      ],
      if (direction.trim().isNotEmpty)
        '${TarotPolishCopy.directionTitle}\n$direction',
    ]);
  }
}
