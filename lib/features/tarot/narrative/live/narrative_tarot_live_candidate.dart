/// Phase 6F.1 — post-formatter Narrative candidate (cache not yet committed).
library;

import '../../interpretation/models/interpretation_result.dart';

/// Fresh or cached candidate awaiting Reflective + AiOutputQuality.
class NarrativeTarotLiveCandidate {
  const NarrativeTarotLiveCandidate({
    required this.result,
    required this.cacheKey,
    required this.fromCache,
  });

  final InterpretationResult result;
  final String cacheKey;
  final bool fromCache;
}
