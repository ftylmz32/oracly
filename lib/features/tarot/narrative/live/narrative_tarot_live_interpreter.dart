/// Phase 6F — live Narrative V2 interpreter (isolated from legacy free-form).
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
import 'narrative_tarot_live_request_factory.dart';

/// Single-attempt Narrative provider path. Service layer owns quality retry.
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

  Future<InterpretationResult> interpret({
    required ReadingSession session,
    required String languageCode,
    bool forceRefresh = false,
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
    final cacheKey = NarrativeTarotCacheIdentity.keyFor(built.request);
    if (!forceRefresh) {
      final cached = await _cache.get(cacheKey);
      if (cached != null) return cached;
    }

    final outcome = await _ai.generateNarrativeTarotReading(
      payload: Map<String, dynamic>.from(built.wirePayload),
      fingerprint: cacheKey,
    );
    if (outcome.isFailure) {
      throw InterpretationException(
        type: InterpretationFailureType.retry,
        message: outcome.failure!.userMessage,
        retryable: true,
      );
    }
    final raw = outcome.value!;
    try {
      final structured = NarrativeTarotResultParser.parse(raw);
      NarrativeTarotQualityValidator.validate(
        request: built.request,
        result: structured,
      );
      final requestId = 'narrative_${_clock().millisecondsSinceEpoch}';
      final bridged = NarrativeTarotResultBridge.toInterpretationResult(
        request: built.request,
        result: structured,
        requestId: requestId,
        sessionId: session.id,
        generatedAt: _clock().toUtc(),
      );
      if (!_formatter.validate(bridged)) {
        throw const InterpretationException(
          type: InterpretationFailureType.invalidResponse,
          message: 'Narrative result failed formatter validation.',
        );
      }
      await _cache.set(cacheKey, bridged);
      return bridged;
    } on NarrativeTarotResultException catch (e) {
      throw InterpretationException(
        type: InterpretationFailureType.invalidResponse,
        message: 'Narrative quality rejected: ${e.kind.name}',
        cause: e,
        retryable: false,
      );
    }
  }

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
