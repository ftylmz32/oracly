/// Phase 5B — Deep Field vs Crossroads structural distinctness.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_spread_semantics.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_catalog.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_enums.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_projector.dart';

/// TEST-ONLY stable card identifiers (same ordered five for both spreads).
const kDistinctnessCards = <String>[
  'major_00',
  'major_01',
  'major_02',
  'major_03',
  'major_04',
];

void main() {
  test('structurally distinct semantic projection (same five cards)', () {
    final deep = SignatureSpreadProjector.project(
      SignatureSpreadCatalog.launch[2],
    );
    final cross = SignatureSpreadProjector.project(
      SignatureSpreadCatalog.launch[3],
    );

    // Same five canonical cards assigned by index — structural, not scorer.
    expect(kDistinctnessCards, hasLength(5));
    final deepAssign = {
      for (var i = 0; i < 5; i++)
        kDistinctnessCards[i]: (
          key: deep.projected.positions[i].positionKey,
          role: deep.projected.positions[i].role,
        ),
    };
    final crossAssign = {
      for (var i = 0; i < 5; i++)
        kDistinctnessCards[i]: (
          key: cross.projected.positions[i].positionKey,
          role: cross.projected.positions[i].role,
        ),
    };

    expect(deepAssign['major_00']!.key, 'situation');
    expect(deepAssign['major_00']!.role, PositionRole.context);
    expect(deepAssign['major_01']!.key, 'hidden_influence');
    expect(deepAssign['major_01']!.role, PositionRole.hiddenInfluence);
    expect(deepAssign['major_02']!.key, 'challenge');
    expect(deepAssign['major_02']!.role, PositionRole.challenge);
    expect(deepAssign['major_03']!.key, 'strength');
    expect(deepAssign['major_03']!.role, PositionRole.support);
    expect(deepAssign['major_04']!.key, 'direction');
    expect(deepAssign['major_04']!.role, PositionRole.direction);

    expect(crossAssign['major_00']!.key, 'option_a');
    expect(crossAssign['major_00']!.role, PositionRole.direction);
    expect(crossAssign['major_01']!.key, 'option_b');
    expect(crossAssign['major_01']!.role, PositionRole.direction);
    expect(crossAssign['major_02']!.key, 'tension');
    expect(crossAssign['major_02']!.role, PositionRole.challenge);
    expect(crossAssign['major_03']!.key, 'counsel');
    expect(crossAssign['major_03']!.role, PositionRole.support);
    expect(crossAssign['major_04']!.key, 'direction');
    expect(crossAssign['major_04']!.role, PositionRole.direction);

    expect(
      deep.projected.positions.map((p) => p.positionKey).toList(),
      isNot(cross.projected.positions.map((p) => p.positionKey).toList()),
    );
    expect(deep.source.dominantArcKey, 'field');
    expect(cross.source.dominantArcKey, 'crossroads');
    expect(deep.edges.length, isNot(cross.edges.length));
    expect(deep.source.signatureGeometryHook, SignatureGeometryHook.fiveLinear);
    expect(
      cross.source.signatureGeometryHook,
      SignatureGeometryHook.fiveDecision,
    );
    // Live Phase 3 scorer difference is NOT claimed in 5B.
  });
}
