import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/data/narrative_tarot_profile_catalog.dart';

/// Phase 3C.2 — RT-M01 Cups 09/10 relationship distinction.
void main() {
  Set<String> tokens(String s) => RegExp(
    r'[a-zа-яё]{3,}',
    caseSensitive: false,
  ).allMatches(s.toLowerCase()).map((m) => m.group(0)!).toSet();

  double jaccard(Set<String> a, Set<String> b) {
    if (a.isEmpty || b.isEmpty) return 0;
    return a.intersection(b).length / a.union(b).length;
  }

  test(
    'cups_09 relationshipDynamic anchors personal sufficiency in connection',
    () {
      final text = NarrativeTarotProfileCatalog.lookup(
        'cups_09',
      )!.relationshipDynamic.en.toLowerCase();
      expect(
        text.contains('personal') ||
            text.contains('contentment') ||
            text.contains('worth'),
        isTrue,
      );
      expect(text.contains('bring'), isTrue);
      expect(
        text.contains('shared field') ||
            text.contains('circle-culture') ||
            text.contains('circle culture'),
        isFalse,
      );
      expect(text.contains('asks to separate'), isFalse);
    },
  );

  test('cups_10 relationshipDynamic anchors shared belonging field', () {
    final text = NarrativeTarotProfileCatalog.lookup(
      'cups_10',
    )!.relationshipDynamic.en.toLowerCase();
    expect(
      text.contains('shared') ||
          text.contains('circle') ||
          text.contains('field'),
      isTrue,
    );
    expect(
      text.contains('together') ||
          text.contains('more than one') ||
          text.contains('room for'),
      isTrue,
    );
    expect(text.contains('manufacture that worth'), isFalse);
    expect(text.contains('asks to separate'), isFalse);
  });

  test('cups_09 and cups_10 relationshipDynamics are no longer near-copies', () {
    final a = NarrativeTarotProfileCatalog.lookup(
      'cups_09',
    )!.relationshipDynamic.en;
    final b = NarrativeTarotProfileCatalog.lookup(
      'cups_10',
    )!.relationshipDynamic.en;
    expect(a.trim().toLowerCase(), isNot(equals(b.trim().toLowerCase())));
    final sc = jaccard(tokens(a), tokens(b));
    // Historical RT-M01 was ~0.77; remediated fields must not remain high-similarity.
    expect(sc, lessThan(0.45), reason: 'similarity=$sc');
  });

  test(
    'cups_09/10 relationshipDynamics avoid destiny / mind-reading claims',
    () {
      for (final id in ['cups_09', 'cups_10']) {
        final blob = NarrativeTarotProfileCatalog.lookup(
          id,
        )!.relationshipDynamic.en.toLowerCase();
        expect(RegExp(r'\bthey love you\b').hasMatch(blob), isFalse);
        expect(RegExp(r'\byou belong together\b').hasMatch(blob), isFalse);
        expect(RegExp(r'\bwill last\b').hasMatch(blob), isFalse);
        expect(RegExp(r'\bmarriage\b').hasMatch(blob), isFalse);
        expect(RegExp(r'\bsoulmate\b').hasMatch(blob), isFalse);
        expect(RegExp(r'\bhappily ever after\b').hasMatch(blob), isFalse);
      }
    },
  );
}
