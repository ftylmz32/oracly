import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/data/narrative_tarot_profile_catalog.dart';

/// Phase 3C.5A — FR-B01 Magician desire EN contamination regression.
void main() {
  final desire = NarrativeTarotProfileCatalog.lookup('major_01')!.desire;

  test('major_01.desire.en anchors Magician effort / agency / outcome', () {
    final en = desire.en.toLowerCase();
    final hasEffort =
        en.contains('effort') ||
        en.contains('skill') ||
        en.contains('agency') ||
        en.contains('work') ||
        en.contains('craft');
    final hasEffect =
        en.contains('mark') ||
        en.contains('outcome') ||
        en.contains('effect') ||
        en.contains('result');
    expect(hasEffort, isTrue, reason: desire.en);
    expect(hasEffect, isTrue, reason: desire.en);
  });

  test('major_01.desire.en has no leave-taking contamination', () {
    final en = desire.en.toLowerCase();
    for (final bad in [
      'leave-taking',
      'leave taking',
      'goodbye',
      'departure',
      'walking away',
    ]) {
      expect(
        en.contains(bad),
        isFalse,
        reason: 'found "$bad" in: ${desire.en}',
      );
    }
  });

  test(
    'major_01.desire TR/EN/RU stay aligned on own-effort affecting outcome',
    () {
      final tr = desire.tr.toLowerCase();
      final en = desire.en.toLowerCase();
      final ru = desire.ru.toLowerCase();

      expect(
        tr.contains('emeğ') || tr.contains('emek') || tr.contains('iz'),
        isTrue,
        reason: desire.tr,
      );
      expect(
        en.contains('effort') || en.contains('skill') || en.contains('agency'),
        isTrue,
        reason: desire.en,
      );
      expect(
        ru.contains('труд') ||
            ru.contains('результат') ||
            ru.contains('повлиял'),
        isTrue,
        reason: desire.ru,
      );

      // Shared semantic: own work/effort affecting a result/outcome/mark.
      expect(
        en.contains('outcome') || en.contains('mark') || en.contains('result'),
        isTrue,
      );
      expect(tr.contains('sonuç') || tr.contains('iz'), isTrue);
      expect(ru.contains('результат') || ru.contains('повлиял'), isTrue);
    },
  );
}
