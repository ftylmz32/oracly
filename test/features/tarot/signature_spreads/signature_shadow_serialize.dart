/// Phase 5E — canonical shadow fact serialization for corpus lock.
library;

import 'package:oracly_new/features/tarot/narrative/evidence/narrative_request.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_shadow_result.dart';

Map<String, dynamic> serializeShadowResult(SignatureSpreadShadowResult r) {
  if (!r.ok) {
    return {
      'ok': false,
      'failureCode': r.failureCode!.name,
      'phase3EvidenceStatus': r.phase3EvidenceStatus.name,
      'phase4HistoryStatus': r.phase4HistoryStatus.name,
    };
  }
  final def = r.definition!;
  final proj = r.projection!;
  final cards = r.cards!;
  final out = <String, dynamic>{
    'ok': true,
    'spreadId': def.spreadId,
    'runtimeEnum': def.runtimeEnumName,
    'languageNormalized': r.languageCode,
    'questionKind': r.questionKind!.name,
    'cardCanonicalIds': [for (final c in cards) c.canonicalCardId],
    'reversalFlags': [for (final c in cards) c.isReversed],
    'positionKeys': [for (final c in cards) c.positionKey],
    'roles': [for (final c in cards) c.role.name],
    'interpretationOrder': def.interpretationOrder,
    'signatureGeometryHook': def.signatureGeometryHook.name,
    'phase3Geometry': proj.projected.geometryHook.name,
    'edges': [
      for (final e in proj.edges)
        {
          'from': e.fromPositionKey,
          'to': e.toPositionKey,
          'directed': e.directed,
          'kind': e.edgeKind.name,
        },
    ],
    'projectedRelationRowCount': proj.projectedRelationRowCount,
    'structuralFingerprint': r.structuralFingerprint,
    'phase3EvidenceStatus': r.phase3EvidenceStatus.name,
    'phase4HistoryStatus': r.phase4HistoryStatus.name,
    'pickerOffered': def.offeredInLivePicker,
    'structuralEdgeGraphAvailable': r.structuralEdgeGraphAvailable,
    'phase3EdgeAwareScoringAvailable': r.phase3EdgeAwareScoringAvailable,
  };
  final req = r.classicalRequest;
  if (req != null) {
    out.addAll(_evidenceFacts(req));
  } else {
    out['classicalRequestPresent'] = false;
    out['enrichedRequestPresent'] = false;
  }
  out['classicalRequestPresent'] = r.classicalRequest != null;
  out['enrichedRequestPresent'] = r.enrichedRequest != null;
  return out;
}

Map<String, dynamic> _evidenceFacts(TarotNarrativeRequest req) {
  final rels = [...req.relationships]
    ..sort((a, b) => a.evidenceId.compareTo(b.evidenceId));
  return {
    'narrativeTarotVersion': req.narrativeTarotVersion,
    'evidenceCardOrder': [for (final c in req.cards) c.canonicalCardId],
    'relationshipCount': rels.length,
    'relationshipIds': [for (final r in rels) r.evidenceId],
    'relationshipKinds': [for (final r in rels) r.kind.name],
    'relationshipPositionPairs': [
      for (final r in rels) '${r.leftPositionKey}>${r.rightPositionKey}',
    ],
  };
}
