import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/deck/oracly_tarot_deck.dart';

import '../../../support/narrative_tarot_v2/narrative_tarot_v2_corpus_loader.dart';
import '../../../support/narrative_tarot_v2/narrative_tarot_v2_hard_failures.dart';

/// Schema + uniqueness + card-id validity for Narrative Tarot V2 corpus.
void main() {
  final corpus = Ntv2CorpusLoader.load();

  test('corpus metadata and unique ids', () {
    expect(corpus.corpusId, 'narrative_tarot_v2');
    expect(corpus.scenarios.length, corpus.scenarioCount);
    expect(corpus.scenarioCount, greaterThanOrEqualTo(60));
    expect(corpus.legacyCorpusNote, isNotEmpty);

    final ids = corpus.scenarios.map((s) => s.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('required scenario fields exist', () {
    for (final s in corpus.scenarios) {
      expect(s.id, isNotEmpty);
      expect(['tr', 'en', 'ru'], contains(s.locale));
      expect(s.tags, isNotEmpty);
      expect(s.category, isNotEmpty);
      expect(s.input['spreadId'], isNotEmpty);
      expect(s.input['cards'], isA<List>());
      expect((s.input['cards'] as List), isNotEmpty);
      expect(s.candidate, isNotEmpty);
      expect(s.expected.flags, isNotEmpty);
      for (final tag in s.expected.hardFailures) {
        expect(Ntv2HardFailure.all, contains(tag), reason: s.id);
      }
    }
  });

  test('fixture card ids validate against OraclyTarotDeck', () {
    final known = OraclyTarotDeck.expectedIds.toSet();
    for (final s in corpus.scenarios) {
      for (final c in (s.input['cards'] as List).cast<Map>()) {
        final id = c['canonicalCardId'] as String;
        expect(known, contains(id), reason: '${s.id} card $id');
      }
    }
  });

  test('intra-fixture position and evidence ids are well-formed', () {
    for (final s in corpus.scenarios) {
      final cards = (s.input['cards'] as List).cast<Map>();
      final positions = cards.map((c) => c['positionKey'] as String).toSet();
      expect(positions.length, cards.length, reason: s.id);
      for (final r in (s.input['relationships'] as List? ?? const [])) {
        final m = r as Map;
        expect(m['evidenceId'], isNotEmpty);
        expect(positions, contains(m['leftPositionKey']));
        expect(positions, contains(m['rightPositionKey']));
      }
    }
  });
}
