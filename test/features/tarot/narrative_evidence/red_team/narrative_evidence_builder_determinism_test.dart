/// Phase 3D.1D red-team — builder determinism + immutability.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/deck/oracly_tarot_bridge.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_classical_spread_catalog.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_evidence_builder.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_evidence_input.dart';

final _ritual = <String, int>{
  for (var i = 0; i < 78; i++) OraclyTarotBridge.byRitualId(i)!.id: i,
};

String _project(dynamic req) {
  final cards = (req.cards as List)
      .map(
        (c) =>
            '${c.canonicalCardId}|${c.ritualCardId}|${c.isReversed}|'
            '${c.positionKey}|${c.positionIndex}|${c.displayName}|${c.imageAsset}',
      )
      .join(';');
  final rels = <String>[];
  for (final r in req.relationships as List) {
    final kind = r.kind;
    final kindName = kind.toString().split('.').last;
    rels.add(
      '${r.evidenceId}|${r.leftCardId}|${r.rightCardId}|'
      '${r.leftPositionKey}|${r.rightPositionKey}|$kindName|'
      '${r.provenance}|${(r.strength as double).toStringAsFixed(6)}',
    );
  }
  return '${req.languageCode}|${req.question.kind.toString().split('.').last}|'
      '${req.question.hasRealQuestion}|${req.spread.spreadId}|$cards|'
      '${rels.join(';')}|'
      '${req.memory.included}|${req.recurringCards.length}|'
      '${req.recurringThemes.length}|${req.bounds.maxRelationships}';
}

void main() {
  test('input order independence', () {
    final def = ClassicalSpreadSemantics.byLegacyTypeName('threeCard');
    final cards = [
      ('major_01', false),
      ('major_06', true),
      ('major_11', false),
    ];
    NarrativeEvidenceInput build(List<(String, bool)> order) {
      // Map by intended position index 0,1,2 for the logical cards, then
      // feed in permuted list order.
      final logical = [
        for (var i = 0; i < 3; i++)
          NarrativeEvidenceCardInput(
            canonicalCardId: cards[i].$1,
            ritualCardId: _ritual[cards[i].$1]!,
            isReversed: cards[i].$2,
            positionKey: def.positions[i].positionKey,
            positionIndex: def.positions[i].index,
          ),
      ];
      final byId = {for (final c in logical) c.canonicalCardId: c};
      return NarrativeEvidenceInput(
        sessionId: 's',
        readingId: 'r',
        languageCode: 'en',
        questionRaw: 'Need guidance for my next step',
        spreadType: TarotSpreadType.threeCard,
        cards: [for (final o in order) byId[o.$1]!],
      );
    }

    final a = NarrativeEvidenceBuilder.build(build(cards));
    final b = NarrativeEvidenceBuilder.build(build(cards.reversed.toList()));
    final c = NarrativeEvidenceBuilder.build(
      build([cards[1], cards[2], cards[0]]),
    );
    expect(_project(a), _project(b));
    expect(_project(a), _project(c));
  });

  test('request collections are unmodifiable', () {
    final def = ClassicalSpreadSemantics.byLegacyTypeName('single');
    final mutableCards = [
      NarrativeEvidenceCardInput(
        canonicalCardId: 'major_00',
        ritualCardId: 0,
        isReversed: false,
        positionKey: def.positions.first.positionKey,
        positionIndex: 0,
      ),
    ];
    final input = NarrativeEvidenceInput(
      sessionId: 's',
      readingId: 'r',
      languageCode: 'en',
      spreadType: TarotSpreadType.single,
      cards: mutableCards,
    );
    final req = NarrativeEvidenceBuilder.build(input);
    expect(() => input.cards.add(mutableCards.first), throwsUnsupportedError);
    expect(() => req.cards.clear(), throwsUnsupportedError);
    expect(() => req.relationships.clear(), throwsUnsupportedError);
    expect(() => req.recurringCards.clear(), throwsUnsupportedError);
    expect(() => req.recurringThemes.clear(), throwsUnsupportedError);
  });
}
