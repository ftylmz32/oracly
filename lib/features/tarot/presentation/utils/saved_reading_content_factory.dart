/// Builds [AiReadingContent] from a parsed saved InterpretationResult.
library;

import '../../../../core/copy/session_ending_copy.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/reading_session.dart';
import '../../interpretation/models/interpretation_result.dart';
import '../widgets/ai_reading/ai_reading_content.dart';
import '../widgets/reading_history/reading_history_data.dart';

abstract final class SavedReadingContentFactory {
  SavedReadingContentFactory._();

  static AiReadingContent fromResult({
    required InterpretationResult result,
    required ReadingHistoryEntry entry,
    required String displayType,
    required String spreadLabel,
    required String? readingType,
    required String cardsBody,
    required String? intention,
    required List<TarotDrawnCard> drawn,
    required InterpretationSource? knownSource,
    required TarotReadingDeliveryKind? deliveryKind,
  }) {
    return AiReadingContent(
      cardName: entry.cardName,
      tagline: displayType,
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
      spreadLabel: spreadLabel,
      readingTheme: readingType ?? spreadLabel,
      userQuestion: intention,
      promptQuestion: result.warnings,
      interpretationSource: knownSource ?? InterpretationSource.local,
      deliveryKind: deliveryKind ?? TarotReadingDeliveryKind.interpretation,
      drawnCards: drawn,
      sourceAttributionKnown: knownSource != null,
    );
  }
}
