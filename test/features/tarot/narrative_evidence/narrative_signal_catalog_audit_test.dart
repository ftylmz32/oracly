import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/data/narrative_tarot_profile_catalog.dart';
import 'package:oracly_new/features/tarot/narrative/domain/narrative_keyword_ids.dart';
import 'package:oracly_new/features/tarot/narrative/domain/narrative_symbol_tags.dart';
import 'package:oracly_new/features/tarot/narrative/domain/reversed_transform_kind.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_semantic_channel.dart';

void main() {
  group('Phase 3D.1B catalog signal audit', () {
    test('all 156 orientations build valid semantic channels', () {
      expect(NarrativeTarotProfileCatalog.all, hasLength(78));
      var orientations = 0;
      var overlapOris = 0;
      var sawOntologyOverlapTag = false;
      var sawTagOnly = false;

      for (final p in NarrativeTarotProfileCatalog.all) {
        for (final tag in p.symbolTags) {
          expect(NarrativeSymbolTags.all.contains(tag), isTrue);
        }
        for (final ori in [p.upright, p.reversed]) {
          orientations++;
          final ch = NarrativeSemanticChannel.from(
            keywordIds: ori.keywordIds,
            symbolTags: p.symbolTags,
          );
          expect(ch.semanticIds.toSet(), hasLength(ch.semanticIds.length));
          for (final id in ch.keywordIds) {
            expect(ch.semanticIds, contains(id));
            expect(NarrativeKeywordIds.all.contains(id), isTrue);
          }
          for (final id in ch.keywordTagDuplicateIds) {
            expect(ch.keywordIds, contains(id));
            expect(ch.ontologyTagIds, contains(id));
          }
          for (final id in ch.tagOnlyIds) {
            expect(NarrativeKeywordIds.all.contains(id), isFalse);
            expect(ch.semanticIds.contains(id), isFalse);
            sawTagOnly = true;
          }
          if (ch.ontologyTagIds.isNotEmpty) sawOntologyOverlapTag = true;
          if (ch.keywordTagDuplicateIds.isNotEmpty) overlapOris++;
        }
      }

      expect(orientations, 156);
      expect(overlapOris, 64);
      expect(sawOntologyOverlapTag, isTrue);
      expect(sawTagOnly, isTrue);
    });

    test('reversed transform distribution locked', () {
      final counts = <ReversedTransformKind, int>{
        for (final t in ReversedTransformKind.values) t: 0,
      };
      for (final p in NarrativeTarotProfileCatalog.all) {
        for (final t in p.reversed.transforms) {
          counts[t] = counts[t]! + 1;
        }
      }
      expect(counts[ReversedTransformKind.excess], 37);
      expect(counts[ReversedTransformKind.distortion], 23);
      expect(counts[ReversedTransformKind.misdirection], 18);
      expect(counts[ReversedTransformKind.avoidance], 17);
      expect(counts[ReversedTransformKind.internalization], 15);
      expect(counts[ReversedTransformKind.delay], 14);
      expect(counts[ReversedTransformKind.blockedExpression], 14);
      expect(counts[ReversedTransformKind.deficiency], 9);
      expect(counts[ReversedTransformKind.privateInternal], 8);
      expect(counts[ReversedTransformKind.release], 1);
    });
  });
}
