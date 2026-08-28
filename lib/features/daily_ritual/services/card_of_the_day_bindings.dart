/// Builds OR context and favorite drafts from today's card.
library;

import '../../../core/l10n/l10n.dart';
import '../../ai/oracle_conversation/models/oracle_reading_context.dart';
import '../../favorite_moments/models/favorite_moment.dart';
import '../../favorite_moments/services/favorite_moment_text.dart';
import '../../tarot/deck/oracly_tarot_bridge.dart';
import '../copy/card_of_the_day_copy.dart';
import '../models/card_of_the_day.dart';

abstract final class CardOfTheDayBindings {
  CardOfTheDayBindings._();

  static String nameOf(CardOfTheDay card) {
    final data = OraclyTarotBridge.byRitualId(card.ritualId);
    return data?.name.of(OraclyL10n.code) ?? CardOfTheDayCopy.title;
  }

  static String meaningOf(CardOfTheDay card) {
    return OraclyTarotBridge.meaning(
      card.ritualId,
      reversed: card.reversed,
      language: OraclyL10n.code,
    );
  }

  static String? assetOf(CardOfTheDay card) =>
      OraclyTarotBridge.byRitualId(card.ritualId)?.visualAsset;

  static OracleReadingContext oracleContext(CardOfTheDay card) {
    final name = nameOf(card);
    final meaning = meaningOf(card);
    return OracleReadingContext(
      sessionId: 'daily_card_${card.dateKey}',
      spreadLabel: CardOfTheDayCopy.title,
      deckId: 'rider-waite',
      deckName: 'Rider-Waite',
      readingTitle: name,
      cardsSummary: name,
      interpretationSummary: meaning,
      fullInterpretation: meaning,
      cardNames: [name],
      cardIds: [card.ritualId],
      sourceLabel: CardOfTheDayCopy.title,
    );
  }

  static FavoriteMoment favoriteDraft(CardOfTheDay card) {
    final name = nameOf(card);
    final meaning = meaningOf(card);
    return FavoriteMoment(
      id: 'tarot:daily_${card.dateKey}',
      source: FavoriteMomentSource.tarot,
      sourceRef: 'daily_${card.dateKey}',
      savedAt: DateTime.now(),
      occurredAt: card.day,
      quote: FavoriteMomentText.clip(meaning),
      visualAsset: assetOf(card),
      visualLabel: name,
    );
  }
}
