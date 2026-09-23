/// Classical spread semantic catalog — Phase 3D.0.1 §17 (Phase 3D.1A).
library;

import 'narrative_position_edges.dart';
import 'narrative_spread_semantics.dart';

abstract final class ClassicalSpreadSemantics {
  ClassicalSpreadSemantics._();

  static SpreadSemanticDefinition byLegacyTypeName(String legacyTypeName) {
    final def = _byLegacy[legacyTypeName];
    if (def == null) {
      throw ArgumentError.value(
        legacyTypeName,
        'legacyTypeName',
        'unknown classical spread',
      );
    }
    return def;
  }

  static SpreadSemanticDefinition bySpreadId(String spreadId) {
    final def = _byId[spreadId];
    if (def == null) {
      throw ArgumentError.value(
        spreadId,
        'spreadId',
        'unknown classical spread',
      );
    }
    return def;
  }

  static List<SpreadSemanticDefinition> get all =>
      List<SpreadSemanticDefinition>.unmodifiable(_all);

  static final List<SpreadSemanticDefinition> _all = [
    _single,
    _threeCard,
    _fiveCard,
    _sevenCard,
    _celticCross,
  ];

  static final Map<String, SpreadSemanticDefinition> _byLegacy = {
    for (final s in _all) s.legacyTypeName: s,
  };

  static final Map<String, SpreadSemanticDefinition> _byId = {
    for (final s in _all) s.spreadId: s,
  };
}

SpreadPositionSemantic _pos({
  required String legacy,
  required String key,
  required int index,
  required PositionRole role,
  required TemporalOrientation temporal,
}) {
  return SpreadPositionSemantic(
    positionKey: key,
    index: index,
    role: role,
    guidingQuestionKey: 'gq.classical.$legacy.$key',
    temporal: temporal,
    relationToOtherSlots: projectedRelationsFor(
      legacyTypeName: legacy,
      positionKey: key,
    ),
    weight: 1.0,
    displayLabelKey: 'tarot.pos.$key',
  );
}

final _single = SpreadSemanticDefinition(
  spreadId: 'classical.single',
  legacyTypeName: 'single',
  cardCount: 1,
  purposeKey: 'purpose.classical.single',
  positions: [
    _pos(
      legacy: 'single',
      key: 'sign',
      index: 0,
      role: PositionRole.signal,
      temporal: TemporalOrientation.atemporal,
    ),
  ],
  interpretationOrder: const [0],
  geometryHook: NarrativeGeometryHook.singlePoint,
  lengthBand: NarrativeLengthBand.short,
);

final _threeCard = SpreadSemanticDefinition(
  spreadId: 'classical.threeCard',
  legacyTypeName: 'threeCard',
  cardCount: 3,
  purposeKey: 'purpose.classical.threeCard',
  positions: [
    _pos(
      legacy: 'threeCard',
      key: 'past',
      index: 0,
      role: PositionRole.root,
      temporal: TemporalOrientation.past,
    ),
    _pos(
      legacy: 'threeCard',
      key: 'present',
      index: 1,
      role: PositionRole.state,
      temporal: TemporalOrientation.present,
    ),
    _pos(
      legacy: 'threeCard',
      key: 'future',
      index: 2,
      role: PositionRole.direction,
      temporal: TemporalOrientation.future,
    ),
  ],
  interpretationOrder: const [0, 1, 2],
  geometryHook: NarrativeGeometryHook.linearRow,
  lengthBand: NarrativeLengthBand.medium,
);

final _fiveCard = SpreadSemanticDefinition(
  spreadId: 'classical.fiveCard',
  legacyTypeName: 'fiveCard',
  cardCount: 5,
  purposeKey: 'purpose.classical.fiveCard',
  positions: [
    _pos(
      legacy: 'fiveCard',
      key: 'situation',
      index: 0,
      role: PositionRole.context,
      temporal: TemporalOrientation.atemporal,
    ),
    _pos(
      legacy: 'fiveCard',
      key: 'hidden_influence',
      index: 1,
      role: PositionRole.hiddenInfluence,
      temporal: TemporalOrientation.atemporal,
    ),
    _pos(
      legacy: 'fiveCard',
      key: 'challenge',
      index: 2,
      role: PositionRole.challenge,
      temporal: TemporalOrientation.atemporal,
    ),
    _pos(
      legacy: 'fiveCard',
      key: 'strength',
      index: 3,
      role: PositionRole.support,
      temporal: TemporalOrientation.atemporal,
    ),
    _pos(
      legacy: 'fiveCard',
      key: 'direction',
      index: 4,
      role: PositionRole.direction,
      temporal: TemporalOrientation.future,
    ),
  ],
  interpretationOrder: const [0, 1, 2, 3, 4],
  geometryHook: NarrativeGeometryHook.linearRow,
  lengthBand: NarrativeLengthBand.full,
);

final _sevenCard = SpreadSemanticDefinition(
  spreadId: 'classical.sevenCard',
  legacyTypeName: 'sevenCard',
  cardCount: 7,
  purposeKey: 'purpose.classical.sevenCard',
  positions: [
    _pos(
      legacy: 'sevenCard',
      key: 'question',
      index: 0,
      role: PositionRole.question,
      temporal: TemporalOrientation.atemporal,
    ),
    _pos(
      legacy: 'sevenCard',
      key: 'current_energy',
      index: 1,
      role: PositionRole.state,
      temporal: TemporalOrientation.present,
    ),
    _pos(
      legacy: 'sevenCard',
      key: 'obstacle',
      index: 2,
      role: PositionRole.challenge,
      temporal: TemporalOrientation.atemporal,
    ),
    _pos(
      legacy: 'sevenCard',
      key: 'hidden_factor',
      index: 3,
      role: PositionRole.hiddenInfluence,
      temporal: TemporalOrientation.atemporal,
    ),
    _pos(
      legacy: 'sevenCard',
      key: 'what_helps',
      index: 4,
      role: PositionRole.support,
      temporal: TemporalOrientation.atemporal,
    ),
    _pos(
      legacy: 'sevenCard',
      key: 'what_to_avoid',
      index: 5,
      role: PositionRole.avoid,
      temporal: TemporalOrientation.atemporal,
    ),
    _pos(
      legacy: 'sevenCard',
      key: 'direction',
      index: 6,
      role: PositionRole.direction,
      temporal: TemporalOrientation.future,
    ),
  ],
  interpretationOrder: const [0, 1, 2, 3, 4, 5, 6],
  geometryHook: NarrativeGeometryHook.linearRow,
  lengthBand: NarrativeLengthBand.full,
);

final _celticCross = SpreadSemanticDefinition(
  spreadId: 'classical.celticCross',
  legacyTypeName: 'celticCross',
  cardCount: 10,
  purposeKey: 'purpose.classical.celticCross',
  positions: [
    _pos(
      legacy: 'celticCross',
      key: 'present',
      index: 0,
      role: PositionRole.state,
      temporal: TemporalOrientation.present,
    ),
    _pos(
      legacy: 'celticCross',
      key: 'challenge',
      index: 1,
      role: PositionRole.challenge,
      temporal: TemporalOrientation.atemporal,
    ),
    _pos(
      legacy: 'celticCross',
      key: 'distant_past',
      index: 2,
      role: PositionRole.root,
      temporal: TemporalOrientation.past,
    ),
    _pos(
      legacy: 'celticCross',
      key: 'recent_past',
      index: 3,
      role: PositionRole.root,
      temporal: TemporalOrientation.past,
    ),
    _pos(
      legacy: 'celticCross',
      key: 'crown',
      index: 4,
      role: PositionRole.direction,
      temporal: TemporalOrientation.atemporal,
    ),
    _pos(
      legacy: 'celticCross',
      key: 'near_future',
      index: 5,
      role: PositionRole.direction,
      temporal: TemporalOrientation.future,
    ),
    _pos(
      legacy: 'celticCross',
      key: 'self',
      index: 6,
      role: PositionRole.self,
      temporal: TemporalOrientation.atemporal,
    ),
    _pos(
      legacy: 'celticCross',
      key: 'environment',
      index: 7,
      role: PositionRole.environment,
      temporal: TemporalOrientation.atemporal,
    ),
    _pos(
      legacy: 'celticCross',
      key: 'hopes',
      index: 8,
      role: PositionRole.hopeFear,
      temporal: TemporalOrientation.atemporal,
    ),
    _pos(
      legacy: 'celticCross',
      key: 'outcome',
      index: 9,
      role: PositionRole.outcome,
      temporal: TemporalOrientation.future,
    ),
  ],
  interpretationOrder: const [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
  geometryHook: NarrativeGeometryHook.celticCross,
  lengthBand: NarrativeLengthBand.long,
);
