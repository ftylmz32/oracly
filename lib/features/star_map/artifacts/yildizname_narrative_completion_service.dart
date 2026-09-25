/// Persists accepted Narrative V1 results as immutable artifacts.
library;

import '../narrative/request/yildizname_narrative_request.dart';
import '../narrative/result/yildizname_narrative_structured_result.dart';
import 'yildizname_artifact.dart';
import 'yildizname_artifact_factory.dart';
import 'yildizname_artifact_repository.dart';
import 'yildizname_artifact_source.dart';
import 'yildizname_narrative_payload.dart';

/// Call only AFTER Phase 5 quality validation has accepted the result.
class YildiznameNarrativeCompletionService {
  YildiznameNarrativeCompletionService(this._repo);

  final YildiznameArtifactRepository _repo;

  Future<YildiznameArtifact> complete({
    required String ownerId,
    required YildiznameNarrativeRequest request,
    required YildiznameNarrativeStructuredResult result,
    String? evidenceFingerprint,
    String? semanticFingerprint,
    String? policyVersion,
    DateTime? createdAtUtc,
  }) async {
    final draft = YildiznameArtifactFactory.createNarrative(
      ownerId: ownerId,
      request: request,
      result: result,
      evidenceFingerprint: evidenceFingerprint,
      semanticFingerprint: semanticFingerprint,
      policyVersion: policyVersion,
      createdAtUtc: createdAtUtc,
    );
    final existing = await _findSemanticDuplicate(draft);
    if (existing != null) return existing;
    return _repo.saveNew(draft);
  }

  Future<YildiznameArtifact?> _findSemanticDuplicate(
    YildiznameArtifact draft,
  ) async {
    final semantic = draft.semanticFingerprint;
    if (semantic == null || semantic.isEmpty) return null;
    final digest =
        YildiznameNarrativePayload.resultContentDigest(draft.payload);
    for (final a in await _repo.getAll()) {
      if (a.source != YildiznameArtifactSource.narrativeV1) continue;
      if (a.semanticFingerprint != semantic) continue;
      if (YildiznameNarrativePayload.resultContentDigest(a.payload) ==
          digest) {
        return a;
      }
      if (a.contentHash == draft.contentHash) return a;
    }
    return null;
  }
}
