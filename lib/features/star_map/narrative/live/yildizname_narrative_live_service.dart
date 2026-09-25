/// Live Narrative V1 service — two attempts, cache approved only.
library;

import '../../../ai/production/oracly_narrative_yildizname_ai_service.dart';
import '../quality/yildizname_quality_validator.dart';
import '../request/yildizname_narrative_request.dart';
import '../request/yildizname_request_fingerprint.dart';
import '../request/yildizname_wire_contract.dart';
import '../result/yildizname_narrative_structured_result.dart';
import '../result/yildizname_result_error.dart';
import '../result/yildizname_result_parser.dart';
import 'yildizname_narrative_attempt.dart';
import 'yildizname_narrative_cache.dart';
import 'yildizname_narrative_live_failure.dart';
import 'yildizname_narrative_live_gate.dart';

final class YildiznameNarrativeLiveService {
  YildiznameNarrativeLiveService({
    required this._ai,
    YildiznameNarrativeCache? cache,
    this._enforceFlag = true,
  }) : _cache = cache ?? YildiznameNarrativeCache();

  final OraclyNarrativeYildiznameAiService _ai;
  final YildiznameNarrativeCache _cache;
  final bool _enforceFlag;

  YildiznameNarrativeCache get cache => _cache;

  Future<YildiznameNarrativeStructuredResult> generate({
    required YildiznameNarrativeRequest request,
    bool forceRefresh = false,
  }) async {
    if (_enforceFlag && !YildiznameNarrativeLiveGate.isEnabled) {
      throw YildiznameLiveFailure(YildiznameLiveFailureKind.flagDisabled);
    }
    final fingerprint = YildiznameRequestFingerprint.of(request);
    if (!forceRefresh) {
      final hit = _cache.getRevalidated(
        fingerprint: fingerprint,
        request: request,
      );
      if (hit != null) return hit;
    }

    Object? lastError;
    for (var attempt = 1; attempt <= kMaxYildiznameProviderAttempts; attempt++) {
      try {
        final result = await _attempt(
          request: request,
          fingerprint: fingerprint,
          attempt: attempt,
        );
        _cache.putApproved(
          fingerprint: fingerprint,
          request: request,
          result: result,
        );
        return result;
      } on YildiznameLiveFailure catch (e) {
        lastError = e;
        if (!e.retryable || attempt == kMaxYildiznameProviderAttempts) {
          rethrow;
        }
      }
    }
    throw YildiznameLiveFailure(
      YildiznameLiveFailureKind.exhausted,
      message: '$lastError',
      cause: lastError,
    );
  }

  Future<YildiznameNarrativeStructuredResult> _attempt({
    required YildiznameNarrativeRequest request,
    required String fingerprint,
    required int attempt,
  }) async {
    final outcome = await _ai.generateNarrativeYildiznameReading(
      payload: YildiznameWireContract.payload(request),
      fingerprint: fingerprint,
      attempt: attempt,
    );
    if (outcome.isFailure) {
      throw YildiznameLiveFailure(
        YildiznameLiveFailureKind.provider,
        message: outcome.failure?.userMessage ?? 'provider',
        retryable: true,
      );
    }
    try {
      final structured = YildiznameResultParser.parse(outcome.value!);
      YildiznameQualityValidator.validate(
        request: request,
        result: structured,
      );
      return structured;
    } on YildiznameResultException catch (e) {
      throw YildiznameLiveFailure.fromResult(e);
    }
  }
}
