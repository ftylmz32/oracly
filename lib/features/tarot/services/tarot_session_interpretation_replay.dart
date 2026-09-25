/// Rebuild purchased Tarot prose from [ReadingSession] — no provider.
library;

import '../../../core/copy/session_ending_copy.dart';
import '../../../core/theme/app_colors.dart';
import '../copy/tarot_l10n.dart';
import '../domain/models/reading_session.dart';
import '../interpretation/formatters/interpretation_formatter.dart';
import '../interpretation/models/interpretation_result.dart';
import '../presentation/utils/saved_reading_provenance.dart';
import '../presentation/widgets/ai_reading/ai_reading_content.dart';
import '../presentation/widgets/ai_reading/reading_result_mode.dart';
import '../presentation/widgets/card_reveal/card_reveal_spread.dart';
import 'tarot_session_interpretation_replay_parse.dart';

/// Durable interpretation replay (Phase 8.1).
/// Snapshot ≠ payment — [TarotReadingCharge.alreadyCharged] is economic truth.
abstract final class TarotSessionInterpretationReplay {
  TarotSessionInterpretationReplay._();

  static bool hasPersistedBody(ReadingSession session) =>
      (session.interpretation ?? '').trim().isNotEmpty;

  /// Missing mode → conservative legacy (old sessions).
  static ReadingResultMode resultModeOf(ReadingSession session) =>
      ReadingResultModeResolver.parsePersisted(
        session.interpretationResultMode,
      ) ??
      ReadingResultMode.legacy;

  /// Null only when body empty. Purchased text is never re-softened.
  static AiReadingContent? tryBuild(ReadingSession session) {
    final raw = (session.interpretation ?? '').trim();
    if (raw.isEmpty) return null;

    final knownSource =
        SavedReadingProvenance.parseSource(session.interpretationSource);
    final delivery = SavedReadingProvenance.parseDelivery(
          session.interpretationDeliveryKind,
        ) ??
        TarotReadingDeliveryKind.interpretation;
    final sourceKnown = knownSource != null;
    final source = knownSource ?? InterpretationSource.local;

    final parsed = TarotSessionInterpretationReplayParse.parse(
      rawText: raw,
      sessionId: session.id,
      source: source,
    );

    if (parsed != null) {
      final base = const InterpretationFormatter().toUiContent(
        result: parsed,
        session: session,
      );
      return _withProvenance(
        base,
        source: source,
        delivery: delivery,
        sourceKnown: sourceKnown,
        exactBody: raw,
      );
    }

    return _rawFallback(
      session: session,
      raw: raw,
      source: source,
      delivery: delivery,
      sourceKnown: sourceKnown,
    );
  }

  static AiReadingContent _withProvenance(
    AiReadingContent base, {
    required InterpretationSource source,
    required TarotReadingDeliveryKind delivery,
    required bool sourceKnown,
    required String exactBody,
  }) {
    return AiReadingContent(
      cardName: base.cardName,
      tagline: base.tagline,
      generalMeaning: base.generalMeaning,
      love: base.love,
      career: base.career,
      money: base.money,
      spiritualGuidance: base.spiritualGuidance,
      luckyEnergy: base.luckyEnergy,
      dailyAdvice: base.dailyAdvice,
      imageAsset: base.imageAsset,
      rarityColor: base.rarityColor,
      fullInterpretation: exactBody,
      drawnCards: base.drawnCards,
      spreadLabel: base.spreadLabel,
      closingMessage: base.closingMessage,
      cardReadings: base.cardReadings,
      readingTheme: base.readingTheme,
      promptQuestion: base.promptQuestion,
      userQuestion: base.userQuestion,
      interpretationSource: source,
      deliveryKind: delivery,
      sourceAttributionKnown: sourceKnown,
    );
  }

  static AiReadingContent _rawFallback({
    required ReadingSession session,
    required String raw,
    required InterpretationSource source,
    required TarotReadingDeliveryKind delivery,
    required bool sourceKnown,
  }) {
    final drawn = session.drawnCards;
    final primary = drawn.isEmpty ? null : drawn.first;
    final reveal =
        primary == null ? null : RevealCardData.fromDrawnCard(primary);
    return AiReadingContent(
      cardName: drawn.length == 1 && primary != null
          ? primary.localizedName
          : TarotL10n.spreadReadingTitle(session.spread),
      tagline: reveal?.subtitle ?? '',
      generalMeaning: raw,
      love: '',
      career: '',
      money: '',
      spiritualGuidance: '',
      luckyEnergy: '',
      dailyAdvice: '',
      closingMessage: SessionEndingCopy.closingFallback,
      imageAsset: reveal?.imageAsset ?? '',
      rarityColor: reveal?.rarityColor ?? AppColors.purpleLight,
      fullInterpretation: raw,
      drawnCards: drawn,
      spreadLabel: TarotL10n.spread(session.spread),
      readingTheme: TarotL10n.spread(session.spread),
      userQuestion: session.intention.text,
      interpretationSource: source,
      deliveryKind: delivery,
      sourceAttributionKnown: sourceKnown,
    );
  }
}
