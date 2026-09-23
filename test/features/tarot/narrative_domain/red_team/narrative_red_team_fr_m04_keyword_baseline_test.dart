import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/data/narrative_tarot_profile_catalog.dart';
import 'package:oracly_new/features/tarot/narrative/domain/narrative_keyword_ids.dart';

/// Phase 3C.5E — FR-M04 ontology implemented; baseline now asserts canonical metrics.
void main() {
  test('FR-M04 keyword ontology is implemented at revision 1', () {
    final freq = <String, int>{};
    var assignments = 0;
    for (final p in NarrativeTarotProfileCatalog.all) {
      for (final id in p.upright.keywordIds) {
        freq[id] = (freq[id] ?? 0) + 1;
        assignments++;
      }
      for (final id in p.reversed.keywordIds) {
        freq[id] = (freq[id] ?? 0) + 1;
        assignments++;
      }
    }
    final unique = freq.length;
    final singletons = freq.values.where((c) => c == 1).length;
    final singletonPct = 100.0 * singletons / unique;

    expect(NarrativeTarotProfileCatalog.all.length, 78);
    expect(NarrativeKeywordIds.ontologyRevision, 1);
    expect(NarrativeKeywordIds.all.length, 128);
    expect(assignments, 439);
    expect(unique, 122);
    expect(singletons, 30);
    expect(singletonPct, closeTo(24.59, 0.05));
  });
}
