/// Phase 5B — pure signature → SpreadSemanticDefinition projector.
library;

import '../narrative/evidence/narrative_classical_spread_catalog.dart';
import '../narrative/evidence/narrative_position_edges.dart';
import '../narrative/evidence/narrative_spread_semantics.dart';
import 'signature_spread_crossroads.dart';
import 'signature_spread_crossroads_edges.dart';
import 'signature_spread_definition.dart';
import 'signature_spread_edge.dart';
import 'signature_spread_semantic_projection.dart';

abstract final class SignatureSpreadProjector {
  SignatureSpreadProjector._();

  static SignatureSpreadSemanticProjection project(
    SignatureSpreadDefinition definition,
  ) {
    if (definition.spreadId.startsWith('classical.')) {
      return _projectClassical(definition);
    }
    if (definition.spreadId == kSignatureCrossroads.spreadId) {
      return _projectCrossroads(definition);
    }
    throw ArgumentError.value(
      definition.spreadId,
      'spreadId',
      'unsupported signature projection',
    );
  }

  static SignatureSpreadSemanticProjection _projectClassical(
    SignatureSpreadDefinition definition,
  ) {
    final frozen = ClassicalSpreadSemantics.bySpreadId(definition.spreadId);
    final edges = <SignatureSpreadEdge>[
      for (final e in kAuthoritativePositionEdges)
        if (e.legacyTypeName == frozen.legacyTypeName)
          SignatureSpreadEdge(
            fromPositionKey: e.fromPositionKey,
            toPositionKey: e.toPositionKey,
            directed: e.directed,
            edgeKind: e.edgeKind,
          ),
    ];
    return SignatureSpreadSemanticProjection(
      source: definition,
      projected: frozen,
      edges: edges,
    );
  }

  static const _crossroadsTemporal = <String, TemporalOrientation>{
    'option_a': TemporalOrientation.atemporal,
    'option_b': TemporalOrientation.atemporal,
    'tension': TemporalOrientation.atemporal,
    'counsel': TemporalOrientation.atemporal,
    'direction': TemporalOrientation.future,
  };

  static SignatureSpreadSemanticProjection _projectCrossroads(
    SignatureSpreadDefinition definition,
  ) {
    final edges = kSignatureCrossroadsEdges;
    final positions = <SpreadPositionSemantic>[
      for (final p in definition.positions)
        SpreadPositionSemantic(
          positionKey: p.positionKey,
          index: p.index,
          role: p.role,
          guidingQuestionKey: p.guidingQuestionKey,
          temporal: _crossroadsTemporal[p.positionKey]!,
          relationToOtherSlots: signatureProjectedRelationsFor(
            edges: edges,
            positionKey: p.positionKey,
          ),
          weight: 1.0,
          displayLabelKey: p.displayLabelKey,
        ),
    ];
    final projected = SpreadSemanticDefinition(
      spreadId: 'signature.crossroads',
      legacyTypeName: 'crossroads',
      cardCount: 5,
      purposeKey: definition.purposeKey,
      positions: List<SpreadPositionSemantic>.unmodifiable(positions),
      interpretationOrder: List<int>.unmodifiable(
        definition.interpretationOrder,
      ),
      geometryHook: NarrativeGeometryHook.linearRow,
      lengthBand: NarrativeLengthBand.full,
    );
    return SignatureSpreadSemanticProjection(
      source: definition,
      projected: projected,
      edges: edges,
    );
  }
}
