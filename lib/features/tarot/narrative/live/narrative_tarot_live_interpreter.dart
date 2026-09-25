/// Phase 6F — live Narrative V2 interpreter (cache commit after final quality).
library;

import '../../../ai/production/oracly_narrative_tarot_ai_service.dart';
import '../../domain/models/reading_session.dart';
import '../../interpretation/cache/interpretation_cache.dart';
import '../../interpretation/formatters/interpretation_formatter.dart';
import '../../interpretation/models/interpretation_error.dart';
import '../../interpretation/models/interpretation_result.dart';
import '../history/tarot_historical_snapshot_loader.dart';
import '../prompt/narrative_tarot_cache_identity.dart';
import '../result/narrative_tarot_quality_validator.dart';
import '../result/narrative_tarot_result_bridge.dart';
import '../result/narrative_tarot_result_error.dart';
import '../result/narrative_tarot_result_parser.dart';
import 'narrative_tarot_attempt.dart';
import 'narrative_tarot_live_candidate.dart';
import 'narrative_tarot_live_request_factory.dart';

/// Returns candidates only — [commitValidated] owns the cache write.
class NarrativeTarotLiveInterpreter {
  NarrativeTarotLiveInterpreter({
    required OraclyNarrativeTarotAiService ai,
    required TarotHistoricalSnapshotLoader historyLoader,
    required InterpretationCache cache,
    InterpretationFormatter? formatter,
    DateTime Function()? clock,
  })  : _ai = ai,
        _historyLoader = historyLoader,
        _cache = cache,
        _formatter = formatter ?? const InterpretationFormatter(),
        _clock = clock ?? DateTime.now;

  final OraclyNarrativeTarotAiService _ai;
  final TarotHistoricalSnapshotLoader _historyLoader;
  final InterpretationCache _cache;
  final InterpretationFormatter _formatter;
  final DateTime Function() _clock;

  Future<NarrativeTarotLiveCandidate> interpret({
    required ReadingSession session,
    required String languageCode,
    bool forceRefresh = false,
    int attempt = 1,
  }) async {
    NarrativeTarotAttempt.assertValid(attempt);
    final historyLoad = await _historyLoader.load(
      currentOwnerId: session.userId,
    );
    final built = NarrativeTarotLiveRequestFactory.build(
      session: session,
      languageCode: languageCode,
      historyLoad: historyLoad,
      now: _clock().toUtc(),
    );
    final cacheKey = NarrativeTarotCacheIdentity.keyFor(built.request);
    if (!forceRefresh) {
      final cached = await _cache.get(cacheKey);
      if (cached != null) {
        return NarrativeTarotLiveCandidate(
          result: cached,
          cacheKey: cacheKey,
          fromCache: true,
        );
      }
    }

    final outcome = await _ai.generateNarrativeTarotReading(
      payload: Map<String, dynamic>.from(built.wirePayload),
      fingerprint: cacheKey,
      attempt: attempt,
    );
    if (outcome.isFailure) {
      throw InterpretationException(
        type: InterpretationFailureType.retry,
        message: outcome.failure!.userMessage,
        retryable: true,
      );
    }
    try {
      final structured = NarrativeTarotResultParser.parse(outcome.value!);
      NarrativeTarotQualityValidator.validate(
        request: built.request,
        result: structured,
      );
      final bridged = NarrativeTarotResultBridge.toInterpretationResult(
        request: built.request,
        result: structured,
        requestId: 'narrative_${_clock().millisecondsSinceEpoch}',
        sessionId: session.id,
        generatedAt: _clock().toUtc(),
      );
      if (!_formatter.validate(bridged)) {
        throw const InterpretationException(
          type: InterpretationFailureType.invalidResponse,
          message: 'Narrative result failed formatter validation.',
          retryable: true,
        );
      }
      return NarrativeTarotLiveCandidate(
        result: bridged,
        cacheKey: cacheKey,
        fromCache: false,
      );
    } on NarrativeTarotResultException catch (e) {
      throw InterpretationException(
        type: InterpretationFailureType.invalidResponse,
        message: 'Narrative quality rejected: ${e.kind.name}',
        cause: e,
        retryable: true,
      );
    }
  }

  /// Cache only the final Reflective + AiOutputQuality-approved result.
  Future<void> commitValidated(
    NarrativeTarotLiveCandidate candidate,
    InterpretationResult finalResult,
  ) async {
    if (candidate.fromCache) return;
    await _cache.set(candidate.cacheKey, finalResult);
  }

  Future<void> invalidateKey(String cacheKey) => _cache.invalidate(cacheKey);

  Future<void> invalidate({
    required ReadingSession session,
    required String languageCode,
  }) async {
    final historyLoad = await _historyLoader.load(
      currentOwnerId: session.userId,
    );
    final built = NarrativeTarotLiveRequestFactory.build(
      session: session,
      languageCode: languageCode,
      historyLoad: historyLoad,
      now: _clock().toUtc(),
    );
    await _cache.invalidate(
      NarrativeTarotCacheIdentity.keyFor(built.request),
    );
  }
}
