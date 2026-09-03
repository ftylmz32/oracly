/// Rebuilds a saved tarot result from persisted markdown — no regeneration.
library;

import '../../../../core/copy/session_ending_copy.dart';
import '../../../../core/domain/models/reading.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../content/tarot/data/tarot_content_catalogue.dart';
import '../../copy/tarot_polish_copy.dart';
import '../../domain/models/reading_session.dart';
import '../../interpretation/formatters/interpretation_formatter.dart';
import '../../interpretation/models/interpretation_result.dart';
import '../../reading/reading_question.dart';
import '../widgets/ai_reading/ai_reading_content.dart';
import '../widgets/reading_history/reading_history_data.dart';
import 'saved_reading_drawn_cards.dart';

abstract final class SavedReadingParser {
  SavedReadingParser._();

  static AiReadingContent toContent({
    required ReadingHistoryEntry entry,
    ReadingModel? model,
  }) {
    final raw = (model?.aiSummary ?? entry.aiSummary).trim();
    final parsed = const InterpretationFormatter().parseRawResponse(
      rawText: raw,
      requestId: entry.id,
      sessionId: model?.sessionId ?? entry.id,
    );
    final type = model?.readingType ?? entry.spreadType;
    final intention = ReadingQuestion.real(model?.intention);
    final snapshots = model?.cards ?? const <ReadingCardSnapshot>[];
    final drawn = snapshots.isNotEmpty
        ? SavedReadingDrawnCards.fromSnapshots(snapshots)
        : SavedReadingDrawnCards.fromEntry(entry);
    final cardsBody = _cardsBody(snapshots);

    if (parsed != null) {
      return _fromResult(parsed, entry, type, cardsBody, intention, drawn);
    }

    return AiReadingContent(
      cardName: entry.cardName,
      tagline: type,
      generalMeaning: raw,
      love: '',
      career: '',
      money: '',
      spiritualGuidance: '',
      luckyEnergy: '',
      dailyAdvice: '',
      closingMessage: SessionEndingCopy.closingFallback,
      imageAsset: entry.cardImageAsset,
      rarityColor: AppColors.purpleLight,
      fullInterpretation: raw,
      cardReadings: cardsBody,
      spreadLabel: model?.spreadType ?? entry.spreadType,
      readingTheme: model?.readingType,
      userQuestion: intention,
      promptQuestion: '',
      drawnCards: drawn,
    );
  }

  static AiReadingContent _fromResult(
    InterpretationResult result,
    ReadingHistoryEntry entry,
    String type,
    String cardsBody,
    String? intention,
    List<TarotDrawnCard> drawn,
  ) {
    return AiReadingContent(
      cardName: entry.cardName,
      tagline: type,
      generalMeaning: result.summary,
      love: result.love,
      career: result.career,
      money: result.money,
      spiritualGuidance: result.spiritualGuidance,
      luckyEnergy: result.luckyEnergy,
      dailyAdvice: result.dailyFocus.isNotEmpty
          ? result.dailyFocus
          : result.advice,
      closingMessage: result.closingMessage.isNotEmpty
          ? result.closingMessage
          : SessionEndingCopy.closingFallback,
      imageAsset: entry.cardImageAsset,
      rarityColor: AppColors.purpleLight,
      fullInterpretation: result.rawText,
      cardReadings: result.health.trim().isNotEmpty ? result.health : cardsBody,
      spreadLabel: entry.spreadType,
      readingTheme: type,
      userQuestion: intention,
      promptQuestion: result.warnings,
      interpretationSource: result.source,
      drawnCards: drawn,
    );
  }

  static String _cardsBody(List<ReadingCardSnapshot> cards) {
    if (cards.isEmpty) return '';
    return [for (final card in cards) _snapshotBlock(card)].join('\n\n');
  }

  static String _snapshotBlock(ReadingCardSnapshot card) {
    final orientation = card.isReversed ? 'Ters' : 'Düz';
    final pos = card.positionLabel ?? TarotPolishCopy.cardField;
    if (card.cardId <= 0) {
      return '${TarotPolishCopy.cardField}: ${card.cardName} ($orientation)';
    }
    final content = TarotContentCatalogue.forPersistedCard(
      cardId: card.cardId,
      imageAsset: card.cardImageAsset,
    );
    final meaning =
        card.isReversed ? content.reversedMeaning : content.uprightMeaning;
    return '${TarotPolishCopy.cardField}: ${card.cardName}\n'
        '${TarotPolishCopy.orientationLabel}: $orientation\n'
        '${TarotPolishCopy.coreMeaning}: $meaning\n'
        '${TarotPolishCopy.positionMeaning}: $pos konumunda '
        '${card.cardName} bu basamağı daha net gösterir.';
  }
}