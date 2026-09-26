/// Phase 8B — accepted Narrative result awaiting durable artifact persistence.
library;

import 'package:flutter/foundation.dart';

import '../request/yildizname_narrative_request.dart';
import '../result/yildizname_narrative_structured_result.dart';

/// In-memory only — never provider-facing. Retry saves without re-calling AI.
@immutable
final class YildiznamePendingNarrativeCompletion {
  const YildiznamePendingNarrativeCompletion({
    required this.ownerId,
    required this.ownerEpoch,
    required this.request,
    required this.result,
    required this.evidenceFingerprint,
    required this.semanticFingerprint,
    required this.createdAtUtc,
    required this.languageCode,
    this.providerCallCount = 0,
  });

  final String ownerId;
  final int ownerEpoch;
  final YildiznameNarrativeRequest request;
  final YildiznameNarrativeStructuredResult result;
  final String evidenceFingerprint;
  final String semanticFingerprint;
  final DateTime createdAtUtc;
  final String languageCode;
  final int providerCallCount;
}
