/// Phase 3D.1D red-team — closed universe + theme≠history.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_evidence_builder.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_relationship_evidence.dart';

import '../narrative_evidence_test_support.dart';

void main() {
  final scenarios = (loadEvidenceCorpus()['scenarios'] as List)
      .cast<Map<String, dynamic>>();

  test('closed universe across corpus', () {
    final idRe = RegExp(r'^rel_[0-9]{2}$');
    for (final s in scenarios) {
      final req = NarrativeEvidenceBuilder.build(inputFromScenario(s));
      final cardIds = req.cards.map((c) => c.canonicalCardId).toSet();
      final positions = req.spread.positions.map((p) => p.positionKey).toSet();
      expect(
        req.cards.map((c) => c.canonicalCardId).toSet().length,
        req.cards.length,
      );
      expect(
        req.cards.map((c) => c.positionKey).toSet().length,
        req.cards.length,
      );
      expect(req.relationships.length, lessThanOrEqualTo(12));
      final evidenceIds = <String>{};
      for (final rel in req.relationships) {
        expect(idRe.hasMatch(rel.evidenceId), isTrue);
        expect(evidenceIds.add(rel.evidenceId), isTrue);
        expect(cardIds.contains(rel.leftCardId), isTrue);
        expect(cardIds.contains(rel.rightCardId), isTrue);
        expect(positions.contains(rel.leftPositionKey), isTrue);
        expect(positions.contains(rel.rightPositionKey), isTrue);
      }
    }
  });

  test(
    'current-spread themeRepetition does not leak into historical recurrence',
    () {
      var sawTheme = false;
      for (final s in scenarios) {
        final req = NarrativeEvidenceBuilder.build(inputFromScenario(s));
        if (req.relationships.any(
          (r) => r.kind == RelationshipKind.themeRepetition,
        )) {
          sawTheme = true;
          expect(req.recurringCards, isEmpty);
          expect(req.recurringThemes, isEmpty);
          expect(req.memory.recentCardNames, isEmpty);
          expect(req.memory.recurringThemeLabels, isEmpty);
          expect(req.memory.included, isFalse);
        }
      }
      expect(sawTheme, isTrue);
    },
  );
}
