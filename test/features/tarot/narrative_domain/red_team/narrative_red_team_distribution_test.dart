import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/data/narrative_tarot_profile_catalog.dart';
import 'package:oracly_new/features/tarot/narrative/domain/reversed_transform_kind.dart';

/// Phase 3C — distribution / candidate reports (never fail on prose similarity).
void main() {
  test('reversed transform distribution is fully enumerable', () {
    final freq = <ReversedTransformKind, int>{
      for (final k in ReversedTransformKind.values) k: 0,
    };
    for (final p in NarrativeTarotProfileCatalog.all) {
      for (final t in p.reversed.transforms) {
        freq[t] = (freq[t] ?? 0) + 1;
      }
    }
    final total = freq.values.fold<int>(0, (a, b) => a + b);
    expect(total, greaterThanOrEqualTo(78));
    expect(freq.values.every((c) => c >= 0), isTrue);
  });

  test('symbol tag frequencies are countable for ontology review', () {
    final freq = <String, int>{};
    for (final p in NarrativeTarotProfileCatalog.all) {
      for (final t in p.symbolTags) {
        freq[t] = (freq[t] ?? 0) + 1;
      }
    }
    expect(freq.isNotEmpty, isTrue);
    expect(freq.values.every((c) => c >= 1), isTrue);
  });

  test('keywordId inventory has no empty ids', () {
    for (final p in NarrativeTarotProfileCatalog.all) {
      for (final id in [...p.upright.keywordIds, ...p.reversed.keywordIds]) {
        expect(id.trim(), isNotEmpty, reason: p.canonicalCardId);
      }
    }
  });

  test('high-risk cards retain anti-literal hedges in EN core', () {
    String core(String id) =>
        NarrativeTarotProfileCatalog.lookup(id)!.coreMeaning.en.toLowerCase();

    expect(core('swords_10').contains('mental'), isTrue);
    expect(core('swords_10').contains('body'), isTrue);
    expect(
      core('pentacles_07').contains('ripe') ||
          core('pentacles_07').contains('patience'),
      isTrue,
    );
    expect(
      core('pentacles_05').contains('worth') ||
          core('pentacles_05').contains('scarcity'),
      isTrue,
    );
    expect(
      core('cups_02').contains('marriage') ||
          core('cups_02').contains('reciprocity'),
      isTrue,
    );
  });
}
