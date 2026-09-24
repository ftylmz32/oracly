/// Phase 6C.1 — relationship correspondence + note privacy.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_relationship_evidence.dart';
import 'package:oracly_new/features/tarot/narrative/prompt/narrative_tarot_prompt_serializer.dart';

import 'narrative_prompt_special_requests.dart';
import 'narrative_prompt_test_support.dart';

void main() {
  group('Relationship correspondence', () {
    test('wrong left position throws', () {
      final base = buildFromCorpusId('three_contrast_exemplar_en');
      final a = base.cards[0];
      final b = base.cards[1];
      expect(
        () => NarrativeTarotPromptSerializer.serialize(
          copyRequest(
            base,
            relationships: [
              TarotNarrativeRelationshipEvidence(
                evidenceId: 'x',
                leftCardId: a.canonicalCardId,
                rightCardId: b.canonicalCardId,
                leftPositionKey: b.positionKey,
                rightPositionKey: a.positionKey,
                kind: RelationshipKind.contrast,
                provenance: 't',
                strength: 0.5,
              ),
            ],
          ),
        ),
        throwsArgumentError,
      );
    });

    test('wrong right position throws', () {
      final base = buildFromCorpusId('three_contrast_exemplar_en');
      final a = base.cards[0];
      final b = base.cards[1];
      final c = base.cards[2];
      expect(
        () => NarrativeTarotPromptSerializer.serialize(
          copyRequest(
            base,
            relationships: [
              TarotNarrativeRelationshipEvidence(
                evidenceId: 'x',
                leftCardId: a.canonicalCardId,
                rightCardId: b.canonicalCardId,
                leftPositionKey: a.positionKey,
                rightPositionKey: c.positionKey,
                kind: RelationshipKind.contrast,
                provenance: 't',
                strength: 0.5,
              ),
            ],
          ),
        ),
        throwsArgumentError,
      );
    });

    test('self-pair throws', () {
      final base = buildFromCorpusId('three_contrast_exemplar_en');
      final a = base.cards[0];
      final b = base.cards[1];
      expect(
        () => NarrativeTarotPromptSerializer.serialize(
          copyRequest(
            base,
            relationships: [
              TarotNarrativeRelationshipEvidence(
                evidenceId: 'x',
                leftCardId: a.canonicalCardId,
                rightCardId: a.canonicalCardId,
                leftPositionKey: a.positionKey,
                rightPositionKey: b.positionKey,
                kind: RelationshipKind.contrast,
                provenance: 't',
                strength: 0.5,
              ),
            ],
          ),
        ),
        throwsArgumentError,
      );
    });

    test('noteKeyOrText not model-facing; note-only change stable', () {
      final withNote = privacySentinelRequest();
      final encoded = encodeModel(withNote);
      expect(encoded.contains('SECRET_INTERNAL_RELATION_NOTE_6C1'), isFalse);
      expect(cacheKey(withNote).contains('SECRET_INTERNAL'), isFalse);
      final cleared = copyRequest(
        withNote,
        relationships: [
          for (final r in withNote.relationships)
            TarotNarrativeRelationshipEvidence(
              evidenceId: r.evidenceId,
              leftCardId: r.leftCardId,
              rightCardId: r.rightCardId,
              leftPositionKey: r.leftPositionKey,
              rightPositionKey: r.rightPositionKey,
              kind: r.kind,
              provenance: r.provenance,
              strength: r.strength,
              noteKeyOrText: null,
            ),
        ],
      );
      expect(encodeModel(withNote), encodeModel(cleared));
      expect(cacheKey(withNote), cacheKey(cleared));
    });
  });
}
