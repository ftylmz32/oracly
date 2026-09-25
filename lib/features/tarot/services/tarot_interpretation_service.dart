/// OR-1180 — Tarot interpretation facade (UI-compatible).
library;

import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';

import '../../../core/copy/resilience_copy.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/reading/ai_output_quality_logger.dart';
import '../../../core/reading/ai_output_quality_tarot.dart';
import '../copy/tarot_l10n.dart';
import '../domain/models/reading_session.dart';
import '../../insights/models/journey_personalization_hints.dart';
import '../interpretation/formatters/interpretation_formatter.dart';
import '../interpretation/models/interpretation_error.dart';
import '../interpretation/models/interpretation_request.dart';
import '../interpretation/models/interpretation_result.dart';
import '../interpretation/models/interpretation_stream_event.dart';
import '../interpretation/models/reading_context.dart';
import '../interpretation/services/interpretation_engine.dart';
import '../interpretation/cache/interpretation_cache.dart';
import '../interpretation/executors/local_interpretation_executor.dart';
import '../../../core/copy/session_ending_copy.dart';
import '../../../core/safety/sensitive_topic_gate.dart';
import '../../content/tarot/data/tarot_card_gloss.dart';
import '../../insights/services/reflective_intelligence.dart';
import '../narrative/live/narrative_tarot_live_gate.dart';
import '../narrative/live/narrative_tarot_live_interpreter.dart';
import '../presentation/widgets/ai_reading/ai_reading_content.dart';
import '../presentation/widgets/card_reveal/card_reveal_spread.dart';
import 'tarot_narrative_quality_budget.dart';

class TarotInterpretationService {
  TarotInterpretationService({
    InterpretationEngine? engine,
    InterpretationCache? cache,
    InterpretationFormatter? formatter,
    bool? allowLocalFallback,
    NarrativeTarotLiveInterpreter? narrativeInterpreter,
  }) : allowLocalFallback = allowLocalFallback ?? engine == null,
       _formatter = formatter ?? const InterpretationFormatter(),
       _narrative = narrativeInterpreter,
       _engine =
           engine ??
           InterpretationEngineFactory.create(
             cache: cache ?? InMemoryInterpretationCache(),
             executor: LocalInterpretationExecutor(),
           );

  /// When false (production / release), exhausted provider or quality failure
  /// throws [InterpretationException] instead of synthesizing local prose.
  ///
  /// Bare construction (no [engine]) defaults to true for local development
  /// and tests. [TarotModuleRoot] always injects an engine and passes
  /// [OraclyAiService.allowsLocalFallback] explicitly.
  final bool allowLocalFallback;

  final InterpretationEngine _engine;
  final InterpretationFormatter _formatter;
  final NarrativeTarotLiveInterpreter? _narrative;

  Future<AiReadingContent> generateContent(
    ReadingSession session, {
    String? language,
    bool forceRefresh = false,
    JourneyPersonalizationHints? journeyHints,
  }) async {
    var context = ReadingContext.fromSession(
      session,
      language: language ?? OraclyL10n.code,
    );
    if (journeyHints != null && !journeyHints.isEmpty) {
      context = context.withJourneyHints(journeyHints);
    }

    final safetyContent = safetyResponseIfNeeded(session);
    if (safetyContent != null) return safetyContent;

    if (context.cards.isEmpty) {
      throw InterpretationException(
        type: InterpretationFailureType.emptyResponse,
        message: TarotL10n.fallbackCards,
        retryable: false,
      );
    }

    if (NarrativeTarotLiveGate.shouldUseNarrative(session.spread)) {
      try {
        return await _generateNarrativeContent(
          session: session,
          context: context,
          forceRefresh: forceRefresh,
        );
      } on InterpretationException catch (error) {
        return _fallbackOrFail(session, context, cause: error);
      } catch (error) {
        return _fallbackOrFail(session, context, cause: error);
      }
    }

    try {
      final result = await _engine.interpret(
        context: context,
        forceRefresh: forceRefresh,
      );
      var guarded = ReflectiveIntelligence.guard(result);
      if (!AiOutputQualityTarot.passes(guarded) && !forceRefresh) {
        final category = AiOutputQualityTarot.firstFailure(guarded);
        if (category != null) {
          AiOutputQualityLogger.logFailure(
            operationId: 'tarot.interpret',
            category: category,
            attempt: 1,
          );
        }
        final retry = await _engine.interpret(
          context: context,
          forceRefresh: true,
        );
        guarded = ReflectiveIntelligence.guard(retry);
      }
      if (!AiOutputQualityTarot.passes(guarded)) {
        return _fallbackOrFail(session, context, cause: 'quality');
      }
      return _formatter.toUiContent(result: guarded, session: session);
    } on InterpretationException catch (error) {
      assert(() {
        debugPrint('[TarotInterpretation] Primary interpret failed');
        return true;
      }());
      return _retryOrFallback(session, context, error);
    } catch (error) {
      assert(() {
        debugPrint('[TarotInterpretation] Unexpected interpret error');
        return true;
      }());
      return _retryOrFallback(session, context, error);
    }
  }

  Future<AiReadingContent> _generateNarrativeContent({
    required ReadingSession session,
    required ReadingContext context,
    bool forceRefresh = false,
  }) {
    final narrative = _requireNarrative();
    return TarotNarrativeQualityBudget.generateContent(
      narrative: narrative,
      session: session,
      context: context,
      formatter: _formatter,
      forceRefresh: forceRefresh,
      fallbackOrFail: ({required Object cause}) =>
          _fallbackOrFail(session, context, cause: cause),
    );
  }

  NarrativeTarotLiveInterpreter _requireNarrative() {
    final narrative = _narrative;
    if (narrative == null) {
      throw const InterpretationException(
        type: InterpretationFailureType.retry,
        message: 'Narrative V2 is enabled but not configured.',
        retryable: false,
      );
    }
    return narrative;
  }

  /// Legacy engine load — Narrative never enters [_retryOrFallback].
  Future<InterpretationResult> _loadInterpretation({
    required ReadingSession session,
    required ReadingContext context,
    bool forceRefresh = false,
  }) {
    return _engine.interpret(
      context: context,
      forceRefresh: forceRefresh,
    );
  }

  Future<AiReadingContent> _retryOrFallback(
    ReadingSession session,
    ReadingContext context,
    Object error,
  ) async {
    try {
      final result = await _loadInterpretation(
        session: session,
        context: context,
        forceRefresh: true,
      );
      final guarded = ReflectiveIntelligence.guard(result);
      return _qualityGatedContent(guarded, session, context);
    } catch (_) {
      assert(() {
        debugPrint('[TarotInterpretation] Force-refresh retry failed');
        return true;
      }());
      return _fallbackOrFail(session, context, cause: error);
    }
  }

  /// Every AI result that can become a successful Tarot result must pass
  /// [AiOutputQualityTarot] first — no route back to the UI skips this gate.
  Future<AiReadingContent> _qualityGatedContent(
    InterpretationResult guarded,
    ReadingSession session,
    ReadingContext context,
  ) async {
    if (AiOutputQualityTarot.passes(guarded)) {
      return _formatter.toUiContent(result: guarded, session: session);
    }
    final category = AiOutputQualityTarot.firstFailure(guarded);
    if (category != null) {
      AiOutputQualityLogger.logFailure(
        operationId: 'tarot.interpret',
        category: category,
        attempt: 1,
      );
    }
    return _fallbackOrFail(session, context, cause: 'quality');
  }

  Future<AiReadingContent> _fallbackOrFail(
    ReadingSession session,
    ReadingContext context, {
    required Object cause,
  }) async {
    if (allowLocalFallback) {
      return _synthesizeLocalFallback(session, context, cause: cause);
    }
    if (cause is InterpretationException) {
      throw InterpretationException(
        type: cause.type,
        message: cause.message,
        cause: cause.cause ?? cause,
        retryable: cause.retryable,
      );
    }
    throw InterpretationException(
      type: InterpretationFailureType.retry,
      message: ResilienceCopy.interpretationFailed,
      cause: cause,
    );
  }

  Future<AiReadingContent> _synthesizeLocalFallback(
    ReadingSession session,
    ReadingContext context, {
    required Object cause,
  }) async {
    try {
      final executor = LocalInterpretationExecutor(formatter: _formatter);
      final result = await executor.execute(
        InterpretationRequest(
          context: context,
          requestId: 'fallback_${DateTime.now().millisecondsSinceEpoch}',
          createdAt: DateTime.now(),
          forceRefresh: true,
        ),
      );
      assert(() {
        debugPrint('[TarotInterpretation] Using local synthesis fallback');
        return true;
      }());
      return _formatter.toUiContent(result: result, session: session);
    } catch (_) {
      assert(() {
        debugPrint('[TarotInterpretation] Local synthesis fallback failed');
        return true;
      }());
      throw InterpretationException(
        type: InterpretationFailureType.retry,
        message: ResilienceCopy.interpretationFailed,
        cause: cause,
      );
    }
  }

  /// Pure SensitiveTopicGate preflight — no engine, provider, or cache.
  AiReadingContent? safetyResponseIfNeeded(ReadingSession session) {
    final reason = SensitiveTopicGate.maybeRespond(session.intention.text);
    if (reason == null) return null;
    return safetyResponse(session, reason: reason);
  }

  /// Pure SensitiveTopicGate copy — never card meaning, never billable.
  AiReadingContent safetyResponse(
    ReadingSession session, {
    required String reason,
  }) {
    final title = TarotL10n.spread(session.spread);
    return AiReadingContent(
      cardName: title,
      tagline: '',
      generalMeaning: reason,
      love: '',
      career: '',
      money: '',
      spiritualGuidance: '',
      luckyEnergy: '',
      dailyAdvice: '',
      closingMessage: '',
      imageAsset: '',
      rarityColor: const Color(0x00000000),
      fullInterpretation: reason,
      drawnCards: const [],
      spreadLabel: title,
      cardReadings: '',
      deliveryKind: TarotReadingDeliveryKind.safety,
    );
  }

  /// Already-paid recovery content built from drawn card metadata.
  AiReadingContent emergencyFallback(
    ReadingSession session, {
    required String reason,
  }) {
    if (session.drawnCards.isEmpty) {
      return AiReadingContent(
        cardName: TarotL10n.spread(session.spread),
        tagline: reason,
        generalMeaning: reason,
        love: reason,
        career: reason,
        money: reason,
        spiritualGuidance: reason,
        luckyEnergy: reason,
        dailyAdvice: reason,
        closingMessage: SessionEndingCopy.closingFallback,
        imageAsset: '',
        rarityColor: const Color(0x00000000),
        fullInterpretation: reason,
        spreadLabel: TarotL10n.spread(session.spread),
        deliveryKind: TarotReadingDeliveryKind.recovery,
      );
    }

    final drawn = session.drawnCards.first;
    final reveal = RevealCardData.fromDrawnCard(drawn);
    final meaning = drawn.effectiveMeaning.trim();
    final body = meaning.isNotEmpty ? meaning : reason;
    final cardReadings = session.drawnCards
        .map((d) {
          final named = TarotCardGloss.named(d.localizedName, d.card.id);
          final ori = TarotL10n.orientation(reversed: d.isReversed);
          final pos = d.localizedPosition;
          final text = d.effectiveMeaning.trim().isEmpty
              ? reason
              : d.effectiveMeaning.trim();
          return '$pos · $named · $ori\n$text';
        })
        .join('\n\n');

    return AiReadingContent(
      cardName: session.drawnCards.length == 1
          ? drawn.localizedName
          : TarotL10n.spreadReadingTitle(session.spread),
      tagline: reveal.subtitle,
      generalMeaning: body,
      love: body,
      career: body,
      money: body,
      spiritualGuidance: body,
      luckyEnergy: drawn.localizedName,
      dailyAdvice: reason,
      closingMessage: SessionEndingCopy.closingFallback,
      imageAsset: reveal.imageAsset,
      rarityColor: reveal.rarityColor,
      fullInterpretation: body,
      drawnCards: session.drawnCards,
      spreadLabel: TarotL10n.spread(session.spread),
      cardReadings: cardReadings,
      readingTheme: session.intention.topic,
      userQuestion: session.intention.text.trim().isEmpty
          ? null
          : session.intention.text.trim(),
      deliveryKind: TarotReadingDeliveryKind.recovery,
    );
  }

  Future<InterpretationResult> generateResult(
    ReadingSession session, {
    String? language,
    bool forceRefresh = false,
    JourneyPersonalizationHints? journeyHints,
  }) async {
    var context = ReadingContext.fromSession(
      session,
      language: language ?? OraclyL10n.code,
    );
    if (journeyHints != null && !journeyHints.isEmpty) {
      context = context.withJourneyHints(journeyHints);
    }
    if (NarrativeTarotLiveGate.shouldUseNarrative(session.spread)) {
      return TarotNarrativeQualityBudget.generateResult(
        narrative: _requireNarrative(),
        session: session,
        context: context,
        forceRefresh: forceRefresh,
      );
    }
    final result = await _loadInterpretation(
      session: session,
      context: context,
      forceRefresh: forceRefresh,
    );
    return ReflectiveIntelligence.guard(result);
  }

  Future<InterpretationResult> regenerate(ReadingSession session) async {
    final context = ReadingContext.fromSession(session);
    if (NarrativeTarotLiveGate.shouldUseNarrative(session.spread)) {
      return TarotNarrativeQualityBudget.generateResult(
        narrative: _requireNarrative(),
        session: session,
        context: context,
        forceRefresh: true,
      );
    }
    return _loadInterpretation(
      session: session,
      context: context,
      forceRefresh: true,
    );
  }

  /// Not on the live Narrative surface — no production callers.
  /// Narrative-eligible sessions fail closed rather than silent legacy stream.
  Stream<InterpretationStreamEvent> generateStream(
    ReadingSession session, {
    String? language,
    bool forceRefresh = false,
  }) {
    if (NarrativeTarotLiveGate.shouldUseNarrative(session.spread)) {
      return Stream.error(
        const InterpretationException(
          type: InterpretationFailureType.retry,
          message: 'Narrative V2 does not support streaming.',
          retryable: false,
        ),
      );
    }
    final context = ReadingContext.fromSession(
      session,
      language: language ?? OraclyL10n.code,
    );
    return _engine.interpretStream(
      context: context,
      forceRefresh: forceRefresh,
    );
  }

  Future<void> invalidateCache(ReadingSession session) async {
    final context = ReadingContext.fromSession(session);
    await _engine.invalidateCache(context);
    final narrative = _narrative;
    if (narrative != null &&
        NarrativeTarotLiveGate.isLaunchSpread(session.spread)) {
      await narrative.invalidate(
        session: session,
        languageCode: context.language,
      );
    }
  }
}

/// Used when service is constructed without DI — replaced at bootstrap.
class InMemoryInterpretationCache implements InterpretationCache {
  final _store = <String, InterpretationResult>{};

  @override
  Future<void> invalidate(String cacheKey) async => _store.remove(cacheKey);

  @override
  Future<void> invalidateSession(String sessionId) async {
    _store.removeWhere((k, _) => k.contains(sessionId));
  }

  @override
  Future<InterpretationResult?> get(String cacheKey) async => _store[cacheKey];

  @override
  Future<void> set(String cacheKey, InterpretationResult result) async {
    _store[cacheKey] = result;
  }
}
