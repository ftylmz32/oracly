/// OR-1180 — Tarot interpretation facade (UI-compatible).
library;

import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';

import '../../../core/copy/resilience_copy.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/reading/ai_output_quality_logger.dart';
import '../../../core/reading/ai_output_quality_tarot.dart';
import '../../ai/production/oracly_ai_service.dart';
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
import '../interpretation/executors/ai_interpretation_executor.dart';
import '../interpretation/executors/local_interpretation_executor.dart';
import '../../../core/copy/session_ending_copy.dart';
import '../../../core/safety/sensitive_topic_gate.dart';
import '../../content/tarot/data/tarot_card_gloss.dart';
import '../../insights/services/reflective_intelligence.dart';
import '../presentation/widgets/ai_reading/ai_reading_content.dart';
import '../presentation/widgets/card_reveal/card_reveal_spread.dart';

class TarotInterpretationService {
  TarotInterpretationService({
    InterpretationEngine? engine,
    InterpretationCache? cache,
    InterpretationFormatter? formatter,
    OraclyAiService? ai,
  })  : _formatter = formatter ?? const InterpretationFormatter(),
        _engine = engine ??
            InterpretationEngineFactory.create(
              cache: cache ?? _InMemoryCacheFallback(),
              executor: ai == null
                  ? LocalInterpretationExecutor()
                  : AiInterpretationExecutor(ai: ai),
            );

  factory TarotInterpretationService.production(OraclyAiService ai) =>
      TarotInterpretationService(ai: ai);

  final InterpretationEngine _engine;
  final InterpretationFormatter _formatter;

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

    if (context.cards.isEmpty) {
      throw InterpretationException(
        type: InterpretationFailureType.emptyResponse,
        message: TarotL10n.fallbackCards,
        retryable: false,
      );
    }

    final safety = SensitiveTopicGate.maybeRespond(session.intention.text);
    if (safety != null) {
      return emergencyFallback(session, reason: safety);
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
        return _synthesizeLocalFallback(session, context, cause: 'quality');
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

  Future<AiReadingContent> _retryOrFallback(
    ReadingSession session,
    ReadingContext context,
    Object error,
  ) async {
    try {
      final result = await _engine.interpret(
        context: context,
        forceRefresh: true,
      );
      return _formatter.toUiContent(
        result: ReflectiveIntelligence.guard(result),
        session: session,
      );
    } catch (_) {
      assert(() {
        debugPrint('[TarotInterpretation] Force-refresh retry failed');
        return true;
      }());
      return _synthesizeLocalFallback(session, context, cause: error);
    }
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

  /// Last-resort content built directly from drawn card metadata.
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
      );
    }

    final drawn = session.drawnCards.first;
    final reveal = RevealCardData.fromDrawnCard(drawn);
    final meaning = drawn.effectiveMeaning.trim();
    final body = meaning.isNotEmpty ? meaning : reason;
    final cardReadings = session.drawnCards.map((d) {
      final named = TarotCardGloss.named(d.localizedName, d.card.id);
      final ori = TarotL10n.orientation(reversed: d.isReversed);
      final pos = d.localizedPosition;
      final text = d.effectiveMeaning.trim().isEmpty
          ? reason
          : d.effectiveMeaning.trim();
      return '$pos · $named · $ori\n$text';
    }).join('\n\n');

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
    );
  }

  Future<InterpretationResult> generateResult(
    ReadingSession session, {
    String? language,
    bool forceRefresh = false,
    JourneyPersonalizationHints? journeyHints,
  }) {
    var context = ReadingContext.fromSession(
      session,
      language: language ?? OraclyL10n.code,
    );
    if (journeyHints != null && !journeyHints.isEmpty) {
      context = context.withJourneyHints(journeyHints);
    }
    return _engine
        .interpret(context: context, forceRefresh: forceRefresh)
        .then(ReflectiveIntelligence.guard);
  }

  Future<InterpretationResult> regenerate(ReadingSession session) {
    final context = ReadingContext.fromSession(session);
    return _engine.regenerate(context);
  }

  Stream<InterpretationStreamEvent> generateStream(
    ReadingSession session, {
    String? language,
    bool forceRefresh = false,
  }) {
    final context = ReadingContext.fromSession(
      session,
      language: language ?? OraclyL10n.code,
    );
    return _engine.interpretStream(
      context: context,
      forceRefresh: forceRefresh,
    );
  }

  Future<void> invalidateCache(ReadingSession session) {
    return _engine.invalidateCache(ReadingContext.fromSession(session));
  }
}

/// Used when service is constructed without DI — replaced at bootstrap.
class _InMemoryCacheFallback implements InterpretationCache {
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
