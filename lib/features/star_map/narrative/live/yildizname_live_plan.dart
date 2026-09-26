/// Phase 8A — typed live Narrative eligibility decision (no provider, no UI).
library;

import 'package:flutter/foundation.dart';

import '../request/yildizname_narrative_request.dart';
import '../request/yildizname_narrative_scope.dart';

enum YildiznameLivePlanKind {
  legacyLocal,
  narrativeReduced,
  narrativeFull,
  ownerUnavailable,
  invalidEvidence,
}

/// Immutable preflight plan. Narrative fields exist only for eligible kinds.
@immutable
final class YildiznameLivePlan {
  const YildiznameLivePlan._({
    required this.kind,
    this.languageCode,
    this.scope,
    this.request,
    this.requestFingerprint,
    this.factsOnlyFingerprint,
    this.evidenceFingerprint,
  });

  factory YildiznameLivePlan.legacyLocal() =>
      const YildiznameLivePlan._(kind: YildiznameLivePlanKind.legacyLocal);

  factory YildiznameLivePlan.ownerUnavailable() =>
      const YildiznameLivePlan._(kind: YildiznameLivePlanKind.ownerUnavailable);

  factory YildiznameLivePlan.invalidEvidence() =>
      const YildiznameLivePlan._(kind: YildiznameLivePlanKind.invalidEvidence);

  factory YildiznameLivePlan.narrative({
    required YildiznameLivePlanKind kind,
    required String languageCode,
    required YildiznameNarrativeScope scope,
    required YildiznameNarrativeRequest request,
    required String requestFingerprint,
    required String factsOnlyFingerprint,
    required String evidenceFingerprint,
  }) {
    assert(
      kind == YildiznameLivePlanKind.narrativeReduced ||
          kind == YildiznameLivePlanKind.narrativeFull,
    );
    return YildiznameLivePlan._(
      kind: kind,
      languageCode: languageCode,
      scope: scope,
      request: request,
      requestFingerprint: requestFingerprint,
      factsOnlyFingerprint: factsOnlyFingerprint,
      evidenceFingerprint: evidenceFingerprint,
    );
  }

  final YildiznameLivePlanKind kind;
  final String? languageCode;
  final YildiznameNarrativeScope? scope;
  final YildiznameNarrativeRequest? request;
  final String? requestFingerprint;
  final String? factsOnlyFingerprint;
  final String? evidenceFingerprint;

  bool get isNarrativeEligible =>
      kind == YildiznameLivePlanKind.narrativeReduced ||
      kind == YildiznameLivePlanKind.narrativeFull;

  /// Value equality uses fingerprints — request instances lack ==.
  @override
  bool operator ==(Object other) =>
      other is YildiznameLivePlan &&
      other.kind == kind &&
      other.languageCode == languageCode &&
      other.scope == scope &&
      other.requestFingerprint == requestFingerprint &&
      other.factsOnlyFingerprint == factsOnlyFingerprint &&
      other.evidenceFingerprint == evidenceFingerprint;

  @override
  int get hashCode => Object.hash(
        kind,
        languageCode,
        scope,
        requestFingerprint,
        factsOnlyFingerprint,
        evidenceFingerprint,
      );
}
