import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread_positions.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_classical_spread_catalog.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_position_edges.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_spread_semantics.dart';

void main() {
  final spreads = ClassicalSpreadSemantics.all;

  group('ClassicalSpreadSemantics catalog', () {
    test('exactly 5 classical spreads, no signature', () {
      expect(spreads, hasLength(5));
      expect(spreads.map((s) => s.spreadId).toList(), [
        'classical.single',
        'classical.threeCard',
        'classical.fiveCard',
        'classical.sevenCard',
        'classical.celticCross',
      ]);
      expect(spreads.any((s) => s.spreadId.startsWith('signature.')), isFalse);
    });

    test('26 positions total; all weights 1.0; role == narrativeFunction', () {
      final positions = spreads.expand((s) => s.positions).toList();
      expect(positions, hasLength(26));
      for (final p in positions) {
        expect(p.weight, 1.0);
        expect(p.narrativeFunction, p.role);
        expect(p.displayLabelKey, 'tarot.pos.${p.positionKey}');
      }
    });

    test('purposeKey / guidingQuestionKey / geometry / length exact', () {
      expect(_legacy('single').purposeKey, 'purpose.classical.single');
      expect(_legacy('threeCard').purposeKey, 'purpose.classical.threeCard');
      expect(_legacy('fiveCard').purposeKey, 'purpose.classical.fiveCard');
      expect(_legacy('sevenCard').purposeKey, 'purpose.classical.sevenCard');
      expect(
        _legacy('celticCross').purposeKey,
        'purpose.classical.celticCross',
      );

      expect(_legacy('single').geometryHook, NarrativeGeometryHook.singlePoint);
      expect(_legacy('single').lengthBand, NarrativeLengthBand.short);
      expect(
        _legacy('threeCard').geometryHook,
        NarrativeGeometryHook.linearRow,
      );
      expect(_legacy('threeCard').lengthBand, NarrativeLengthBand.medium);
      expect(_legacy('fiveCard').geometryHook, NarrativeGeometryHook.linearRow);
      expect(_legacy('fiveCard').lengthBand, NarrativeLengthBand.full);
      expect(
        _legacy('sevenCard').geometryHook,
        NarrativeGeometryHook.linearRow,
      );
      expect(_legacy('sevenCard').lengthBand, NarrativeLengthBand.full);
      expect(
        _legacy('celticCross').geometryHook,
        NarrativeGeometryHook.celticCross,
      );
      expect(_legacy('celticCross').lengthBand, NarrativeLengthBand.long);

      for (final s in spreads) {
        for (final p in s.positions) {
          expect(
            p.guidingQuestionKey,
            'gq.classical.${s.legacyTypeName}.${p.positionKey}',
          );
        }
      }
    });

    test('runtime position parity', () {
      _assertParity(_legacy('single'), kSinglePositions);
      _assertParity(_legacy('threeCard'), kThreeCardPositions);
      _assertParity(_legacy('fiveCard'), kFiveCardPositions);
      _assertParity(_legacy('sevenCard'), kSevenCardPositions);
      _assertParity(_legacy('celticCross'), kCelticCrossPositions);
    });

    test('no duplicate position keys inside a spread', () {
      for (final s in spreads) {
        final keys = s.positions.map((p) => p.positionKey).toList();
        expect(keys.toSet(), hasLength(keys.length));
      }
    });

    test('temporal mapping exact', () {
      expect(_pos('single', 'sign').temporal, TemporalOrientation.atemporal);
      expect(_pos('threeCard', 'past').temporal, TemporalOrientation.past);
      expect(
        _pos('threeCard', 'present').temporal,
        TemporalOrientation.present,
      );
      expect(_pos('threeCard', 'future').temporal, TemporalOrientation.future);
      expect(
        _pos('fiveCard', 'direction').temporal,
        TemporalOrientation.future,
      );
      expect(
        _pos('sevenCard', 'current_energy').temporal,
        TemporalOrientation.present,
      );
      expect(_pos('celticCross', 'distant_past').role, PositionRole.root);
      expect(_pos('celticCross', 'hopes').role, PositionRole.hopeFear);
      expect(
        _pos('celticCross', 'outcome').temporal,
        TemporalOrientation.future,
      );
    });
  });

  group('§17.4 edges', () {
    test('29 authoritative rows; 13 directed; 16 undirected', () {
      expect(kAuthoritativePositionEdges, hasLength(29));
      expect(
        kAuthoritativePositionEdges.where((e) => e.directed),
        hasLength(13),
      );
      expect(
        kAuthoritativePositionEdges.where((e) => !e.directed),
        hasLength(16),
      );
    });

    test('frozen edge table exact match', () {
      expect(
        kAuthoritativePositionEdges
            .map(
              (e) =>
                  '${e.legacyTypeName}|${e.fromPositionKey}|${e.toPositionKey}|${e.directed}|${e.edgeKind.name}',
            )
            .toList(),
        _expectedEdgeRows,
      );
    });

    test('45 projected relation entries; single has zero', () {
      var projected = 0;
      for (final s in spreads) {
        for (final p in s.positions) {
          projected += p.relationToOtherSlots.length;
        }
      }
      expect(projected, 45);
      expect(_legacy('single').positions.single.relationToOtherSlots, isEmpty);
    });

    test('no edge references unknown position; typed PositionEdgeKind', () {
      for (final e in kAuthoritativePositionEdges) {
        final spread = _legacy(e.legacyTypeName);
        final keys = spread.positions.map((p) => p.positionKey).toSet();
        expect(keys, contains(e.fromPositionKey));
        expect(keys, contains(e.toPositionKey));
        expect(e.edgeKind, isA<PositionEdgeKind>());
      }
    });

    test('directed edges project source-only', () {
      final edge = kAuthoritativePositionEdges.firstWhere(
        (e) =>
            e.legacyTypeName == 'threeCard' &&
            e.fromPositionKey == 'past' &&
            e.toPositionKey == 'present' &&
            e.directed,
      );
      final past = _pos('threeCard', 'past');
      final present = _pos('threeCard', 'present');
      expect(
        past.relationToOtherSlots.any(
          (r) =>
              r.otherPositionKey == edge.toPositionKey &&
              r.directed &&
              r.edgeKind == edge.edgeKind,
        ),
        isTrue,
      );
      expect(
        present.relationToOtherSlots.any(
          (r) => r.otherPositionKey == 'past' && r.directed,
        ),
        isFalse,
      );
    });

    test('undirected edges project both sides directed:false', () {
      final challenge = _pos('fiveCard', 'challenge');
      final strength = _pos('fiveCard', 'strength');
      expect(
        challenge.relationToOtherSlots.any(
          (r) =>
              r.otherPositionKey == 'strength' &&
              !r.directed &&
              r.edgeKind == PositionEdgeKind.supportive,
        ),
        isTrue,
      );
      expect(
        strength.relationToOtherSlots.any(
          (r) =>
              r.otherPositionKey == 'challenge' &&
              !r.directed &&
              r.edgeKind == PositionEdgeKind.supportive,
        ),
        isTrue,
      );
    });
  });
}

SpreadSemanticDefinition _legacy(String name) =>
    ClassicalSpreadSemantics.byLegacyTypeName(name);

SpreadPositionSemantic _pos(String legacy, String key) =>
    _legacy(legacy).positions.firstWhere((p) => p.positionKey == key);

void _assertParity(
  SpreadSemanticDefinition semantic,
  List<TarotPosition> runtime,
) {
  expect(semantic.cardCount, runtime.length);
  expect(semantic.positions, hasLength(runtime.length));
  for (var i = 0; i < runtime.length; i++) {
    expect(semantic.positions[i].index, runtime[i].index);
    expect(semantic.positions[i].positionKey, runtime[i].key);
  }
}

const _expectedEdgeRows = [
  'threeCard|past|present|true|temporal',
  'threeCard|present|future|true|temporal',
  'threeCard|past|future|true|temporal',
  'fiveCard|situation|direction|true|temporal',
  'fiveCard|situation|hidden_influence|false|pressure',
  'fiveCard|situation|challenge|false|opposition',
  'fiveCard|challenge|strength|false|supportive',
  'fiveCard|strength|direction|true|supportive',
  'fiveCard|hidden_influence|challenge|false|pressure',
  'sevenCard|question|current_energy|false|mirror',
  'sevenCard|current_energy|obstacle|false|opposition',
  'sevenCard|obstacle|what_helps|false|supportive',
  'sevenCard|what_to_avoid|direction|false|pressure',
  'sevenCard|hidden_factor|current_energy|false|pressure',
  'sevenCard|question|direction|true|temporal',
  'sevenCard|what_helps|direction|true|supportive',
  'sevenCard|obstacle|what_to_avoid|false|pressure',
  'celticCross|distant_past|recent_past|true|temporal',
  'celticCross|recent_past|present|true|temporal',
  'celticCross|distant_past|present|true|temporal',
  'celticCross|present|near_future|true|temporal',
  'celticCross|present|challenge|false|opposition',
  'celticCross|self|environment|false|mirror',
  'celticCross|present|self|false|mirror',
  'celticCross|challenge|outcome|false|pressure',
  'celticCross|hopes|outcome|false|pressure',
  'celticCross|crown|outcome|true|temporal',
  'celticCross|challenge|self|false|pressure',
  'celticCross|near_future|outcome|true|temporal',
];
