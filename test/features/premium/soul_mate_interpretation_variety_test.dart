/// Soulmate text should not read as one of a tiny fixed set of combos.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/premium/data/soul_mate_interpretation_catalogue.dart';

void main() {
  test('feeling/yourSide reach all 5 tone variants, not just 3', () {
    final feelings = <String>{};
    final sides = <String>{};
    for (var tone = 0; tone < 5; tone++) {
      final parts = SoulMateInterpretationCatalogue.forInputs(
        name: 'Ada',
        intention: '',
        season: 'kış',
        preference: '',
        tone: tone,
      );
      feelings.add(parts.feeling);
      sides.add(parts.yourSide);
    }
    expect(feelings, hasLength(5));
    expect(sides, hasLength(5));
  });

  test('tone wraps modulo 5 — tone and tone+5 produce the same text', () {
    final a = SoulMateInterpretationCatalogue.forInputs(
      name: 'Ada',
      intention: '',
      season: 'kış',
      preference: '',
      tone: 2,
    );
    final b = SoulMateInterpretationCatalogue.forInputs(
      name: 'Ada',
      intention: '',
      season: 'kış',
      preference: '',
      tone: 7,
    );
    expect(a.feeling, b.feeling);
    expect(a.yourSide, b.yourSide);
  });
}
