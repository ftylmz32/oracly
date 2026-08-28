/// Table phase actions — gems/session start + OR context builder.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/app_providers.dart';
import '../../../ai/oracle_conversation/models/oracle_reading_context.dart';
import '../../domain/models/reading_session.dart';
import '../../domain/models/tarot_spread.dart';
import '../../presentation/screens/deck_selection_start.dart';
import '../../presentation/widgets/card_reveal/card_reveal_spread.dart';
import '../../presentation/widgets/deck_selection/deck_selection_data.dart';
import '../../reading/reading_question.dart';
import '../../shared/tarot_scope.dart';

abstract final class TarotTableFlow {
  TarotTableFlow._();

  static Future<bool> startSession({
    required BuildContext context,
    required WidgetRef ref,
    required TarotSpreadType spread,
  }) async {
    TarotScope.of(context).flow.selectSpread(spread);
    ref.read(selectedSpreadProvider.notifier).state = spread.label;
    return DeckSelectionStart.confirm(
      context: context,
      ref: ref,
      deckId: TarotDeckCatalogue.activeId,
      openShuffleRoute: false,
    );
  }

  static void captureTopicIntention(BuildContext context, String topicId) {
    TarotScope.of(context).flow.captureIntention(
          TarotIntention(text: '', topic: topicId),
        );
  }

  static void captureCustomIntention(BuildContext context, String text) {
    TarotScope.of(context).flow.captureIntention(
          TarotIntention(
            text: ReadingQuestion.sanitize(text),
            topic: 'custom',
          ),
        );
  }

  static OracleReadingContext buildOrContext({
    required ReadingSession session,
    required RevealCardData focus,
  }) {
    final question = session.intention.text.trim();
    final short = focus.card.summary.trim().isNotEmpty
        ? focus.card.summary
        : (focus.isReversed ? focus.card.reversedMeaning : focus.card.meaning);
    return OracleReadingContext(
      sessionId: session.id,
      spreadLabel: session.spread.label,
      deckId: session.deckId,
      deckName: 'Rider-Waite',
      readingTitle: focus.displayName,
      cardsSummary: session.drawnCards.map((d) => d.localizedName).join(' · '),
      interpretationSummary: short,
      userQuestion: question.isEmpty ? null : question,
      cardNames: session.drawnCards.map((d) => d.localizedName).toList(),
      cardIds: session.drawnCards.map((d) => d.card.id).toList(),
    );
  }
}
