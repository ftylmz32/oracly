/// OR-1180 — Tarot interpretation facade (UI-compatible).
library;

import 'package:flutter/foundation.dart';

import '../../../core/copy/resilience_copy.dart';
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
import '../../insights/services/reflective_intelligence.dart';
import '../presentation/widgets/ai_reading/ai_reading_content.dart';
import '../presentation/widgets/card_reveal/card_reveal_spread.dart';

class TarotInterpretationService {
  TarotInterpretationService({
    InterpretationEngine? engine,
    InterpretationCache? cache,
    InterpretationFormatter? formatter,
  })  : _formatter = formatter ?? const InterpretationFormatter(),
        _engine = engine ??
            InterpretationEngineFactory.create(
              cache: cache ?? _InMemoryCacheFallback(),
              executor: LocalInterpretationExecutor(),
            );

  final InterpretationEngine _engine;
  final InterpretationFormatter _formatter;

  Future<AiReadingContent> generateContent(
    ReadingSession session, {
    String language = 'tr',
    bool forceRefresh = false,
    JourneyPersonalizationHints? journeyHints,
  }) async {
    var context = ReadingContext.fromSession(session, language: language);
    if (journeyHints != null && !journeyHints.isEmpty) {
      context = context.withJourneyHints(journeyHints);
    }

    if (context.cards.isEmpty) {
      debugPrint(
        '[TarotInterpretation] Session ${session.id} has no drawn cards.',
      );
      return emergencyFallback(
        session,
        reason:
            'Kart verisi bulunamadı. Açılım kart anlamlarıyla gösteriliyor.',
      );
    }

    try {
      final result = await _engine.interpret(
        context: context,
        forceRefresh: forceRefresh,
      );
      final guarded = ReflectiveIntelligence.guard(result);
      return _formatter.toUiContent(result: guarded, session: session);
    } on InterpretationException catch (error, stackTrace) {
      debugPrint(
        '[TarotInterpretation] Primary interpret failed: $error\n$stackTrace',
      );
      return _retryOrFallback(session, context, error);
    } catch (error, stackTrace) {
      debugPrint(
        '[TarotInterpretation] Unexpected interpret error: $error\n$stackTrace',
      );
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
    } catch (retryError, retryStack) {
      debugPrint(
        '[TarotInterpretation] Force-refresh retry failed: $retryError\n$retryStack',
      );
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
      debugPrint(
        '[TarotInterpretation] Using local synthesis fallback after: $cause',
      );
      return _formatter.toUiContent(result: result, session: session);
    } catch (fallbackError, fallbackStack) {
      debugPrint(
        '[TarotInterpretation] Local synthesis fallback failed: '
        '$fallbackError\n$fallbackStack',
      );
      return emergencyFallback(
        session,
        reason: ResilienceCopy.interpretationFailed,
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
        cardName: session.spread.label,
        tagline: reason,
        generalMeaning: reason,
        love: reason,
        career: reason,
        money: reason,
        spiritualGuidance: reason,
        luckyEnergy: reason,
        dailyAdvice: reason,
        closingMessage: SessionEndingCopy.closingFallback,
        imageAsset: CardRevealSpread.forIndex(0).imageAsset,
        rarityColor: CardRevealSpread.forIndex(0).rarityColor,
        fullInterpretation: reason,
        spreadLabel: session.spread.label,
      );
    }

    final drawn = session.drawnCards.first;
    final reveal = RevealCardData.fromDrawnCard(drawn);
    final meaning = drawn.effectiveMeaning.trim();
    final body = meaning.isNotEmpty ? meaning : reason;

    return AiReadingContent(
      cardName: session.drawnCards.length == 1
          ? drawn.card.name
          : '${session.spread.label} Açılımı',
      tagline: reveal.subtitle,
      generalMeaning: body,
      love: body,
      career: body,
      money: body,
      spiritualGuidance: body,
      luckyEnergy: drawn.card.keywords.take(3).join(' · '),
      dailyAdvice: reason,
      closingMessage: SessionEndingCopy.closingFallback,
      imageAsset: reveal.imageAsset,
      rarityColor: reveal.rarityColor,
      fullInterpretation: body,
      drawnCards: session.drawnCards,
      spreadLabel: session.spread.label,
    );
  }

  Future<InterpretationResult> generateResult(
    ReadingSession session, {
    String language = 'tr',
    bool forceRefresh = false,
    JourneyPersonalizationHints? journeyHints,
  }) {
    var context = ReadingContext.fromSession(session, language: language);
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
    String language = 'tr',
    bool forceRefresh = false,
  }) {
    final context = ReadingContext.fromSession(session, language: language);
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
