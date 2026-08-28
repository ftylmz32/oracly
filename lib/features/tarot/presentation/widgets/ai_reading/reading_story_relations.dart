/// Adjacent-card relationships — separate from per-card expandable detail.
library;

import '../../../reading/reading_relations.dart';
import 'ai_reading_content.dart';
import 'reading_card_message.dart';

abstract final class ReadingStoryRelations {
  ReadingStoryRelations._();

  static String of(AiReadingContent content) {
    final cards = content.drawnCards;
    if (cards.length < 2) return '';
    final parts = <String>[];
    for (var i = 1; i < cards.length; i++) {
      final prev = ReadingCardMessage.asContext(cards[i - 1]);
      final next = ReadingCardMessage.asContext(cards[i]);
      parts.add(
        '${ReadingRelations.after(prev, next)} '
        '${ReadingRelations.shift(prev, next)}',
      );
    }
    return parts.join('\n\n').trim();
  }
}
