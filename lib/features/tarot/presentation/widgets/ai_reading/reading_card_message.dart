/// TAROT V2 — per-card result: meaning in slot, neighbors, asked question.
library;

import '../../../../../core/l10n/l10n.dart';
import '../../../deck/oracly_tarot_bridge.dart';
import '../../../domain/models/reading_session.dart';
import '../../../interpretation/models/reading_context.dart';
import '../../../reading/reading_card_beat.dart';
import '../../../../insights/services/reflective_card_copy.dart';

abstract final class ReadingCardMessage {
  ReadingCardMessage._();

  static String fromDrawn(
    TarotDrawnCard card, {
    String? question,
    TarotDrawnCard? previous,
    TarotDrawnCard? next,
  }) {
    return ReflectiveCardCopy.block(
      _ctx(card),
      question: question,
      previous: previous == null ? null : _ctx(previous),
      next: next == null ? null : _ctx(next),
    );
  }

  static String insight(TarotDrawnCard card) =>
      ReadingCardBeat.insight(_ctx(card));

  static String detail(
    TarotDrawnCard card, {
    String? question,
    TarotDrawnCard? previous,
    TarotDrawnCard? next,
  }) {
    return ReadingCardBeat.detail(
      _ctx(card),
      question: question,
      previous: previous == null ? null : _ctx(previous),
      next: next == null ? null : _ctx(next),
    );
  }

  /// Slot meaning only — neighbor relations live in [ReadingStoryRelations].
  static String detailSolo(TarotDrawnCard card, {String? question}) {
    return ReadingCardBeat.detail(_ctx(card), question: question);
  }

  static ReadingCardContext asContext(TarotDrawnCard card) => _ctx(card);

  static ReadingCardContext _ctx(TarotDrawnCard card) {
    final code = OraclyL10n.code;
    final upright = OraclyTarotBridge.meaning(
      card.card.id,
      reversed: false,
      language: code,
    );
    final reversed = OraclyTarotBridge.meaning(
      card.card.id,
      reversed: true,
      language: code,
    );
    final keys = OraclyTarotBridge.keywords(card.card.id, language: code);
    return ReadingCardContext(
      cardId: card.card.id,
      cardName: card.localizedName,
      positionIndex: card.positionIndex,
      positionLabel: card.localizedPosition,
      positionKey: card.positionKey ?? 'pos_${card.positionIndex}',
      isReversed: card.isReversed,
      uprightMeaning: upright.trim().isEmpty ? card.card.meaning : upright,
      reversedMeaning:
          reversed.trim().isEmpty ? card.card.reversedMeaning : reversed,
      keywords: keys.isEmpty ? card.card.keywords : keys,
      element: card.card.element,
      imageAsset: card.card.image,
    );
  }
}
