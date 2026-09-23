import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/domain/narrative_keyword_ids.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_evidence_error.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_semantic_channel.dart';

void main() {
  group('NarrativeSemanticChannel', () {
    test('FR-F04 dedupes same keyword+tag id once', () {
      final ch = NarrativeSemanticChannel.from(
        keywordIds: const ['belonging', 'hope'],
        symbolTags: const ['belonging', 'alchemy'],
      );
      expect(ch.keywordIds, ['belonging', 'hope']);
      expect(ch.ontologyTagIds, ['belonging']);
      expect(ch.tagOnlyIds, ['alchemy']);
      expect(ch.semanticIds, ['belonging', 'hope']);
      expect(ch.keywordTagDuplicateIds, ['belonging']);
      expect(ch.semanticIds.where((id) => id == 'belonging'), hasLength(1));
    });

    test('deterministic lexicographic order ignores input order', () {
      final a = NarrativeSemanticChannel.from(
        keywordIds: const ['scatter', 'haste', 'delay'],
        symbolTags: const ['alchemy', 'balance'],
      );
      final b = NarrativeSemanticChannel.from(
        keywordIds: const ['delay', 'scatter', 'haste'],
        symbolTags: const ['balance', 'alchemy'],
      );
      expect(a.keywordIds, b.keywordIds);
      expect(a.ontologyTagIds, b.ontologyTagIds);
      expect(a.tagOnlyIds, b.tagOnlyIds);
      expect(a.semanticIds, b.semanticIds);
      expect(a.keywordIds, ['delay', 'haste', 'scatter']);
    });

    test('tag-only motifs preserved separately', () {
      final ch = NarrativeSemanticChannel.from(
        keywordIds: const ['clarity'],
        symbolTags: const ['alchemy', 'breakthrough', 'clarity'],
      );
      expect(ch.tagOnlyIds, containsAll(['alchemy', 'breakthrough']));
      expect(ch.semanticIds, isNot(contains('alchemy')));
      expect(ch.semanticIds, contains('clarity'));
    });

    test('unknown keyword throws invalidOntologyId', () {
      expect(
        () => NarrativeSemanticChannel.from(
          keywordIds: const ['notARealKeyword'],
          symbolTags: const [],
        ),
        throwsA(
          isA<NarrativeEvidenceException>().having(
            (e) => e.code,
            'code',
            NarrativeEvidenceErrorCode.invalidOntologyId,
          ),
        ),
      );
    });

    test('lists are immutable', () {
      final ch = NarrativeSemanticChannel.from(
        keywordIds: const ['hope'],
        symbolTags: const ['alchemy'],
      );
      expect(() => ch.keywordIds.add('x'), throwsUnsupportedError);
      expect(() => ch.semanticIds.add('x'), throwsUnsupportedError);
      expect(() => ch.tagOnlyIds.add('x'), throwsUnsupportedError);
    });

    test('all NarrativeKeywordIds accepted', () {
      final ch = NarrativeSemanticChannel.from(
        keywordIds: NarrativeKeywordIds.all,
        symbolTags: const [],
      );
      expect(ch.keywordIds, hasLength(NarrativeKeywordIds.all.length));
      expect(ch.semanticIds, ch.keywordIds);
    });
  });
}
