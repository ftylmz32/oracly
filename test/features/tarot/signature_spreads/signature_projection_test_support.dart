/// Shared Phase 5B projection test helpers.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_spread_semantics.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_edge.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_semantic_projection.dart';

void expectSemanticsEqual(
  SpreadSemanticDefinition a,
  SpreadSemanticDefinition b,
) {
  expect(a.spreadId, b.spreadId);
  expect(a.legacyTypeName, b.legacyTypeName);
  expect(a.cardCount, b.cardCount);
  expect(a.purposeKey, b.purposeKey);
  expect(a.interpretationOrder, b.interpretationOrder);
  expect(a.geometryHook, b.geometryHook);
  expect(a.lengthBand, b.lengthBand);
  expect(a.positions.length, b.positions.length);
  for (var i = 0; i < a.positions.length; i++) {
    final x = a.positions[i];
    final y = b.positions[i];
    expect(x.positionKey, y.positionKey);
    expect(x.index, y.index);
    expect(x.role, y.role);
    expect(x.guidingQuestionKey, y.guidingQuestionKey);
    expect(x.temporal, y.temporal);
    expect(x.weight, y.weight);
    expect(x.displayLabelKey, y.displayLabelKey);
    expect(x.relationToOtherSlots.length, y.relationToOtherSlots.length);
    for (var j = 0; j < x.relationToOtherSlots.length; j++) {
      final rx = x.relationToOtherSlots[j];
      final ry = y.relationToOtherSlots[j];
      expect(rx.otherPositionKey, ry.otherPositionKey);
      expect(rx.edgeKind, ry.edgeKind);
      expect(rx.directed, ry.directed);
    }
  }
}

Map<String, Object?> serializeProjection(
  SignatureSpreadSemanticProjection p,
) {
  return {
    'spreadId': p.source.spreadId,
    'runtimeEnumName': p.source.runtimeEnumName,
    'projectedSpreadId': p.projected.spreadId,
    'legacyTypeName': p.projected.legacyTypeName,
    'cardCount': p.projected.cardCount,
    'positionKeys': [
      for (final x in p.projected.positions) x.positionKey,
    ],
    'indices': [for (final x in p.projected.positions) x.index],
    'roles': [for (final x in p.projected.positions) x.role.name],
    'temporals': [for (final x in p.projected.positions) x.temporal.name],
    'interpretationOrder': p.projected.interpretationOrder,
    'signatureGeometryHook': p.source.signatureGeometryHook.name,
    'phase3Geometry': p.projected.geometryHook.name,
    'lengthBand': p.projected.lengthBand.name,
    'edges': [
      for (final e in p.edges) _edgeMap(e),
    ],
    'projectedRelationRowCount': p.projectedRelationRowCount,
    'offeredInLivePicker': p.source.offeredInLivePicker,
    'supportedQuestionKinds': [
      for (final k in p.source.supportedQuestionKinds) k.name,
    ]..sort(),
    'primaryQuestionKind': p.source.primaryQuestionKind.name,
  };
}

Map<String, Object?> _edgeMap(SignatureSpreadEdge e) => {
      'from': e.fromPositionKey,
      'to': e.toPositionKey,
      'directed': e.directed,
      'kind': e.edgeKind.name,
    };
