/// Rebuilds a saved tarot result from persisted markdown — no regeneration.
library;

import '../../../../core/copy/session_ending_copy.dart';
import '../../../../core/domain/models/reading.dart';
import '../../../../core/theme/app_colors.dart';
import '../../copy/tarot_l10n.dart';
import '../../interpretation/formatters/interpretation_formatter.dart';
import '../../interpretation/models/interpretation_result.dart';
import '../../reading/reading_question.dart';
import '../widgets/ai_reading/ai_reading_content.dart';
import '../widgets/reading_history/reading_history_data.dart';
import 'saved_reading_card_blocks.dart';
import 'saved_reading_content_factory.dart';
import 'saved_reading_drawn_cards.dart';
import 'saved_reading_provenance.dart';

abstract final class SavedReadingParser {
  SavedReadingParser._();

  static AiReadingContent toContent({
    required ReadingHistoryEntry entry,
    ReadingModel? model,
  }) {
    final raw = (model?.aiSummary ?? entry.aiSummary).trim();
    final knownSource = SavedReadingProvenance.parseSource(
      model?.interpretationSource,
    );
    final parsed = const InterpretationFormatter().parseRawResponse(
      rawText: raw,
      requestId: entry.id,
      sessionId: model?.sessionId ?? entry.id,
      source: knownSource ?? InterpretationSource.local,
    );
    final persistedSpread = model?.spreadType ?? entry.spreadType;
    final spreadLabel = TarotL10n.spreadFromStorage(persistedSpread);
    final rawReadingType = (model?.readingType ?? entry.readingType)?.trim();
    final readingType =
        rawReadingType == null || rawReadingType.isEmpty ? null : rawReadingType;
    final displayType = readingType ?? spreadLabel;
    final intention = ReadingQuestion.real(model?.intention);
    final snapshots = model?.cards ?? const <ReadingCardSnapshot>[];
    final drawn = snapshots.isNotEmpty
        ? SavedReadingDrawnCards.fromSnapshots(snapshots)
        : SavedReadingDrawnCards.fromEntry(entry);
    final cardsBody = SavedReadingCardBlocks.cardsBody(snapshots);
    final delivery = SavedReadingProvenance.parseDelivery(model?.deliveryKind);

    if (parsed != null) {
      return SavedReadingContentFactory.fromResult(
        result: parsed,
        entry: entry,
        displayType: displayType,
        spreadLabel: spreadLabel,
        readingType: readingType,
        cardsBody: cardsBody,
        intention: intention,
        drawn: drawn,
        knownSource: knownSource,
        deliveryKind: delivery,
      );
    }

    return AiReadingContent(
      cardName: entry.cardName,
      tagline: displayType,
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
      spreadLabel: spreadLabel,
      readingTheme: readingType ?? spreadLabel,
      userQuestion: intention,
      promptQuestion: '',
      drawnCards: drawn,
      interpretationSource: knownSource ?? InterpretationSource.local,
      deliveryKind: delivery ?? TarotReadingDeliveryKind.interpretation,
      sourceAttributionKnown: knownSource != null,
    );
  }
}
