/// In-memory cache for quality-approved Narrative V1 results only.
library;

import '../quality/yildizname_quality_validator.dart';
import '../request/yildizname_narrative_request.dart';
import '../result/yildizname_narrative_structured_result.dart';
import '../result/yildizname_result_error.dart';

class YildiznameNarrativeCache {
  final Map<String, YildiznameNarrativeStructuredResult> _store = {};

  YildiznameNarrativeStructuredResult? get(String fingerprint) =>
      _store[fingerprint];

  /// Cache only FINAL quality-approved results.
  void putApproved({
    required String fingerprint,
    required YildiznameNarrativeRequest request,
    required YildiznameNarrativeStructuredResult result,
  }) {
    YildiznameQualityValidator.validate(request: request, result: result);
    _store[fingerprint] = result;
  }

  void invalidate(String fingerprint) => _store.remove(fingerprint);

  /// Revalidate cached entry; invalidate on failure.
  YildiznameNarrativeStructuredResult? getRevalidated({
    required String fingerprint,
    required YildiznameNarrativeRequest request,
  }) {
    final cached = _store[fingerprint];
    if (cached == null) return null;
    try {
      YildiznameQualityValidator.validate(request: request, result: cached);
      return cached;
    } on YildiznameResultException {
      _store.remove(fingerprint);
      return null;
    }
  }

  void clear() => _store.clear();

  int get length => _store.length;
}
