/// Phase 5D.1 — Crossroads is intentionally outside Phase 3 Classical builder.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/deck/oracly_tarot_bridge.dart';
import 'package:oracly_new/features/tarot/deck/oracly_tarot_deck.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_classical_spread_catalog.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_evidence_builder.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_evidence_input.dart';

final _ritual = <String, int>{
  for (var i = 0; i < 78; i++) OraclyTarotBridge.byRitualId(i)!.id: i,
};

NarrativeEvidenceInput _classicalReading(TarotSpreadType type) {
  final def = ClassicalSpreadSemantics.byLegacyTypeName(type.name);
  final ids = OraclyTarotDeck.expectedIds.take(type.cardCount).toList();
  return NarrativeEvidenceInput(
    sessionId: 'sess',
    readingId: 'read',
    languageCode: 'en',
    spreadType: type,
    cards: [
      for (var i = 0; i < ids.length; i++)
        NarrativeEvidenceCardInput(
          canonicalCardId: ids[i],
          ritualCardId: _ritual[ids[i]]!,
          isReversed: false,
          positionKey: def.positions[i].positionKey,
          positionIndex: def.positions[i].index,
        ),
    ],
  );
}

NarrativeEvidenceInput _crossroadsAttempt() {
  // Borrow fiveCard position keys only to shape a multi-card payload —
  // resolveSpread must fail closed before any fabricated request.
  final five = ClassicalSpreadSemantics.byLegacyTypeName('fiveCard');
  final ids = OraclyTarotDeck.expectedIds.take(5).toList();
  return NarrativeEvidenceInput(
    sessionId: 'sess-cr',
    readingId: 'read-cr',
    languageCode: 'en',
    spreadType: TarotSpreadType.crossroads,
    cards: [
      for (var i = 0; i < ids.length; i++)
        NarrativeEvidenceCardInput(
          canonicalCardId: ids[i],
          ritualCardId: _ritual[ids[i]]!,
          isReversed: false,
          positionKey: five.positions[i].positionKey,
          positionIndex: five.positions[i].index,
        ),
    ],
  );
}

void main() {
  test('classical enum set still builds through NarrativeEvidenceBuilder', () {
    final classical = TarotSpreadType.values
        .where((t) => t != TarotSpreadType.crossroads);
    for (final type in classical) {
      final req = NarrativeEvidenceBuilder.build(_classicalReading(type));
      expect(req.spread.legacyTypeName, type.name);
      expect(req.cards, hasLength(type.cardCount));
    }
  });

  test('Crossroads is not a Phase 3 Classical spread', () {
    expect(
      () => ClassicalSpreadSemantics.byLegacyTypeName('crossroads'),
      throwsA(
        isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('unknown classical spread'),
        ),
      ),
    );
    expect(
      ClassicalSpreadSemantics.all.map((s) => s.legacyTypeName),
      isNot(contains('crossroads')),
    );
  });

  test('Crossroads builder fails closed — never fiveCard fallback', () {
    expect(
      () => NarrativeEvidenceBuilder.build(_crossroadsAttempt()),
      throwsA(
        isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('unknown classical spread'),
        ),
      ),
    );

    // Prove fiveCard remains a distinct classical path — not a silent alias.
    final five = NarrativeEvidenceBuilder.build(
      _classicalReading(TarotSpreadType.fiveCard),
    );
    expect(five.spread.legacyTypeName, 'fiveCard');
    expect(five.spread.spreadId, 'classical.fiveCard');
  });
}
