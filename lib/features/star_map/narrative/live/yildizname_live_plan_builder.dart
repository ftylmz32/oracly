/// Phase 8A — pure live Narrative eligibility resolver (no provider, no UI).
library;

import '../../../../core/l10n/app_locale.dart';
import '../../../birth_chart/models/birth_chart.dart';
import '../../../birth_chart/models/chart_fidelity.dart';
import '../../artifacts/yildizname_artifact.dart';
import '../../artifacts/yildizname_artifact_memory.dart';
import '../request/yildizname_narrative_scope.dart';
import '../request/yildizname_request_factory.dart';
import '../request/yildizname_request_fingerprint.dart';
import 'yildizname_live_evidence_validator.dart';
import 'yildizname_live_plan.dart';

/// Builds a typed [YildiznameLivePlan] from authoritative local inputs only.
///
/// Facts come solely from [BirthChart.natalEvidence] via
/// [YildiznameRequestFactory.fromEvidence]. Presentation mirrors are ignored.
abstract final class YildiznameLivePlanBuilder {
  YildiznameLivePlanBuilder._();

  static YildiznameLivePlan build({
    required bool featureEnabled,
    required String? ownerId,
    required BirthChart? chart,
    required String languageCode,
    Iterable<YildiznameArtifact> artifactHistory = const [],
    List<String> personalDiscoveryLabels = const [],
  }) {
    if (!featureEnabled) return YildiznameLivePlan.legacyLocal();
    if (!_narrativeEvidenceCandidate(chart)) {
      return YildiznameLivePlan.legacyLocal();
    }

    final owner = ownerId?.trim() ?? '';
    if (owner.isEmpty) return YildiznameLivePlan.ownerUnavailable();

    final evidence = chart!.natalEvidence!;
    if (!YildiznameLiveEvidenceValidator.isCoherent(chart, evidence)) {
      return YildiznameLivePlan.invalidEvidence();
    }

    final scope = YildiznameNarrativeScopeMap.fromFidelity(evidence.fidelity);
    if (scope == YildiznameNarrativeScope.legacy) {
      return YildiznameLivePlan.legacyLocal();
    }

    final lang = AppLocale.normalize(languageCode);
    final sameOwner = <YildiznameArtifact>[
      for (final a in artifactHistory)
        if (a.ownerId.trim() == owner) a,
    ];
    final request = YildiznameRequestFactory.fromEvidence(
      evidence: evidence,
      languageCode: lang,
      observedRecurringLabels: List.unmodifiable(personalDiscoveryLabels),
      artifactRecurringThemes:
          YildiznameArtifactMemory.recurringThemes(sameOwner),
    );
    if (request.scope != scope) return YildiznameLivePlan.invalidEvidence();

    final kind = scope == YildiznameNarrativeScope.full
        ? YildiznameLivePlanKind.narrativeFull
        : YildiznameLivePlanKind.narrativeReduced;
    return YildiznameLivePlan.narrative(
      kind: kind,
      languageCode: lang,
      scope: scope,
      request: request,
      requestFingerprint: YildiznameRequestFingerprint.of(request),
      factsOnlyFingerprint: YildiznameRequestFingerprint.factsOnly(request),
      evidenceFingerprint: evidence.metadata.evidenceFingerprint,
    );
  }

  /// Reduced/full only — tropical / missing evidence stays legacyLocal.
  static bool _narrativeEvidenceCandidate(BirthChart? chart) {
    if (chart == null) return false;
    if (chart.natalEvidence == null) return false;
    return chart.fidelity == ChartCalculationFidelity.reducedNatal ||
        chart.fidelity == ChartCalculationFidelity.fullNatalEphemeris;
  }

}

