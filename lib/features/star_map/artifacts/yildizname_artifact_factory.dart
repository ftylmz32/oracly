/// Builds immutable Yıldızname artifacts with integrity hashes.
library;

import '../narrative/request/yildizname_narrative_request.dart';
import '../narrative/result/yildizname_narrative_structured_result.dart';
import '../narrative/versions.dart';
import '../models/star_map_reading.dart';
import '../presentation/reference/star_map_result_section.dart';
import 'yildizname_artifact.dart';
import 'yildizname_artifact_id.dart';
import 'yildizname_artifact_integrity.dart';
import 'yildizname_artifact_source.dart';
import 'yildizname_legacy_payload.dart';
import 'yildizname_legacy_section_kind.dart';
import 'yildizname_narrative_payload.dart';

abstract final class YildiznameArtifactFactory {
  YildiznameArtifactFactory._();

  static YildiznameArtifact createLegacy({
    required String ownerId,
    required String title,
    required List<StarMapResultSection> sections,
    required YildiznameLegacySectionKind sectionKind,
    required String locale,
    List<StarMapPlanetInfluence> planets = const [],
    String? sunSignId,
    String? dayKey,
    DateTime? createdAtUtc,
    String? id,
  }) {
    final payload = YildiznameLegacyPayload.build(
      title: title,
      sections: sections,
      sectionKind: sectionKind,
      planets: planets,
      sunSignId: sunSignId,
      dayKey: dayKey,
    );
    final digest = YildiznameLegacyPayload.contentDigest(payload);
    final dedupe =
        '${YildiznameArtifactSource.legacyLocal.wireName}|'
        '${dayKey ?? ''}|${sectionKind.wireName}|'
        '${sunSignId ?? ''}|$digest';
    return _seal(
      YildiznameArtifact(
        id: id ?? YildiznameArtifactId.generate(),
        ownerId: ownerId,
        createdAtUtc: (createdAtUtc ?? DateTime.now().toUtc()),
        source: YildiznameArtifactSource.legacyLocal,
        resultLocale: locale,
        contentHash: '',
        semanticDedupeKey: dedupe,
        payload: payload,
      ),
    );
  }

  static YildiznameArtifact createNarrative({
    required String ownerId,
    required YildiznameNarrativeRequest request,
    required YildiznameNarrativeStructuredResult result,
    String? evidenceFingerprint,
    String? semanticFingerprint,
    String? policyVersion,
    DateTime? createdAtUtc,
    String? id,
  }) {
    final payload = YildiznameNarrativePayload.build(
      request: request,
      result: result,
    );
    final digest = YildiznameNarrativePayload.resultContentDigest(payload);
    final semantic = semanticFingerprint ?? '';
    final dedupe =
        '${YildiznameArtifactSource.narrativeV1.wireName}|$semantic|$digest';
    return _seal(
      YildiznameArtifact(
        id: id ?? YildiznameArtifactId.generate(),
        ownerId: ownerId,
        createdAtUtc: (createdAtUtc ?? DateTime.now().toUtc()),
        source: YildiznameArtifactSource.narrativeV1,
        resultLocale: result.languageCode,
        scope: request.scope.name,
        fidelity: request.fidelity,
        calculationVersion: request.calculationVersion,
        interpretationVersion: 'yildizname-narrative-v1',
        resultContractVersion: '${result.contractVersion}',
        serializerVersion: '${request.serializerVersion}',
        policyVersion: policyVersion ?? kYildiznamePolicyVersion,
        evidenceFingerprint: evidenceFingerprint,
        semanticFingerprint: semanticFingerprint,
        contentHash: '',
        semanticDedupeKey: dedupe,
        payload: payload,
      ),
    );
  }

  static YildiznameArtifact _seal(YildiznameArtifact draft) {
    final hash = YildiznameArtifactIntegrity.compute(draft);
    return YildiznameArtifact(
      artifactSchemaVersion: draft.artifactSchemaVersion,
      id: draft.id,
      ownerId: draft.ownerId,
      createdAtUtc: draft.createdAtUtc,
      source: draft.source,
      resultLocale: draft.resultLocale,
      scope: draft.scope,
      fidelity: draft.fidelity,
      calculationVersion: draft.calculationVersion,
      interpretationVersion: draft.interpretationVersion,
      resultContractVersion: draft.resultContractVersion,
      serializerVersion: draft.serializerVersion,
      policyVersion: draft.policyVersion,
      evidenceFingerprint: draft.evidenceFingerprint,
      semanticFingerprint: draft.semanticFingerprint,
      contentHash: hash,
      semanticDedupeKey: draft.semanticDedupeKey,
      payload: draft.payload,
    );
  }
}
