import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/data/narrative_tarot_profile_catalog.dart';

/// Phase 3C.1 — soft near-clone diagnostic (candidates only; never fail on score).
void main() {
  Set<String> tokens(String s) => RegExp(
    r'[a-zа-яё]{3,}',
    caseSensitive: false,
  ).allMatches(s.toLowerCase()).map((m) => m.group(0)!).toSet();

  double jaccard(Set<String> a, Set<String> b) {
    if (a.isEmpty || b.isEmpty) return 0;
    return a.intersection(b).length / a.union(b).length;
  }

  test('diagnostic lists shadow↔reversed EN similarity candidates', () {
    final candidates = <String>[];
    for (final p in NarrativeTarotProfileCatalog.all) {
      final sc = jaccard(tokens(p.shadow.en), tokens(p.reversed.expression.en));
      if (sc >= 0.75) {
        candidates.add('${p.canonicalCardId}:$sc');
      }
    }
    // After RT-M02 remediation, no ≥0.75 candidates should remain.
    expect(candidates, isEmpty, reason: candidates.join(', '));
  });
}
