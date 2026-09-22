import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/data/narrative_tarot_profile_catalog.dart';

/// Phase 3C.5D — FR-M04 current keyword baseline diagnostic (does NOT enforce ontology).
void main() {
  test('FR-M04 diagnostic reports current keyword fragmentation baseline', () {
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

    // Reproducible CURRENT baseline (Phase 3C.5D inventory).
    expect(NarrativeTarotProfileCatalog.all.length, 78);
    expect(assignments, 468);
    expect(unique, 397);
    expect(singletons, 352);
    expect(singletonPct, closeTo(88.66, 0.05));

    // FR-M04 remains open: do NOT assert proposed ontology metrics here.
  });
}
