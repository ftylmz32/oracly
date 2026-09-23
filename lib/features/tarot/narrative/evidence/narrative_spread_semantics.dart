/// Classical spread semantic domain types (Phase 3D.1A).
library;

enum TemporalOrientation { past, present, future, atemporal }

/// Structural role of a slot. narrativeFunction MUST equal role (identity lock).
enum PositionRole {
  signal,
  context,
  root,
  state,
  challenge,
  hiddenInfluence,
  support,
  direction,
  self,
  environment,
  hopeFear,
  outcome,
  question,
  avoid,
}

enum NarrativeGeometryHook { singlePoint, linearRow, celticCross }

enum NarrativeLengthBand { short, medium, full, long }

enum PositionEdgeKind { temporal, opposition, supportive, pressure, mirror }

class PositionRelationEdge {
  const PositionRelationEdge({
    required this.otherPositionKey,
    required this.edgeKind,
    required this.directed,
  });

  final String otherPositionKey;
  final PositionEdgeKind edgeKind;

  /// True only on the authoritative directed source side.
  final bool directed;
}

class SpreadPositionSemantic {
  const SpreadPositionSemantic({
    required this.positionKey,
    required this.index,
    required this.role,
    required this.guidingQuestionKey,
    required this.temporal,
    required this.relationToOtherSlots,
    required this.weight,
    required this.displayLabelKey,
  });

  final String positionKey;
  final int index;
  final PositionRole role;
  final String guidingQuestionKey;
  final TemporalOrientation temporal;
  final List<PositionRelationEdge> relationToOtherSlots;
  final double weight;
  final String displayLabelKey;

  /// Identity lock — never diverges from [role].
  PositionRole get narrativeFunction => role;
}

class SpreadSemanticDefinition {
  const SpreadSemanticDefinition({
    required this.spreadId,
    required this.legacyTypeName,
    required this.cardCount,
    required this.purposeKey,
    required this.positions,
    required this.interpretationOrder,
    required this.geometryHook,
    required this.lengthBand,
  });

  final String spreadId;
  final String legacyTypeName;
  final int cardCount;
  final String purposeKey;
  final List<SpreadPositionSemantic> positions;
  final List<int> interpretationOrder;
  final NarrativeGeometryHook geometryHook;
  final NarrativeLengthBand lengthBand;
}

/// One authoritative §17.4 edge row (before projection onto positions).
class AuthoritativePositionEdge {
  const AuthoritativePositionEdge({
    required this.legacyTypeName,
    required this.fromPositionKey,
    required this.toPositionKey,
    required this.directed,
    required this.edgeKind,
  });

  final String legacyTypeName;
  final String fromPositionKey;
  final String toPositionKey;
  final bool directed;
  final PositionEdgeKind edgeKind;
}
