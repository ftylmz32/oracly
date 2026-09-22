import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/data/narrative_tarot_profile_catalog.dart';
import 'package:oracly_new/features/tarot/narrative/domain/reversed_transform_kind.dart';

/// Phase 3C.1 — orientation quality anchors on remediitated representatives.
void main() {
  test('cups_05 reversed names excess/avoidance, not shadow clone', () {
    final p = NarrativeTarotProfileCatalog.lookup('cups_05')!;
    final rev = p.reversed.expression.en.toLowerCase();
    final shadow = p.shadow.en.toLowerCase();
    expect(rev, isNot(equals(shadow)));
    expect(
      rev.contains('excess') ||
          rev.contains('avoid') ||
          rev.contains('fixation') ||
          rev.contains('spilled'),
      isTrue,
    );
    expect(
      p.reversed.transforms,
      containsAll([
        ReversedTransformKind.excess,
        ReversedTransformKind.avoidance,
      ]),
    );
  });

  test('swords_10 reversed uses internalization/blockedExpression', () {
    final p = NarrativeTarotProfileCatalog.lookup('swords_10')!;
    final rev = p.reversed.expression.en.toLowerCase();
    expect(rev, isNot(equals(p.shadow.en.toLowerCase())));
    expect(
      rev.contains('internal') ||
          rev.contains('block') ||
          rev.contains('disaster') ||
          rev.contains('all-is-over') ||
          rev.contains('all is over'),
      isTrue,
    );
    expect(rev.contains('body'), isFalse);
    expect(
      p.reversed.transforms,
      containsAll([
        ReversedTransformKind.internalization,
        ReversedTransformKind.blockedExpression,
      ]),
    );
  });

  test('pentacles_07 reversed uses delay/avoidance cultivation frame', () {
    final p = NarrativeTarotProfileCatalog.lookup('pentacles_07')!;
    final rev = p.reversed.expression.en.toLowerCase();
    expect(rev, isNot(equals(p.shadow.en.toLowerCase())));
    expect(
      rev.contains('delay') ||
          rev.contains('avoid') ||
          rev.contains('frozen') ||
          rev.contains('reassess'),
      isTrue,
    );
    expect(RegExp(r'\b(buy|sell) now\b').hasMatch(rev), isFalse);
    expect(
      p.reversed.transforms,
      containsAll([
        ReversedTransformKind.delay,
        ReversedTransformKind.avoidance,
      ]),
    );
  });

  test('wands_10 reversed uses excess/blockedExpression load frame', () {
    final p = NarrativeTarotProfileCatalog.lookup('wands_10')!;
    final rev = p.reversed.expression.en.toLowerCase();
    expect(rev, isNot(equals(p.shadow.en.toLowerCase())));
    expect(
      rev.contains('excess') ||
          rev.contains('block') ||
          rev.contains('hero') ||
          rev.contains('delegat'),
      isTrue,
    );
  });

  test(
    'major profiles still have distinct shadow vs reversed where present',
    () {
      for (final p in NarrativeTarotProfileCatalog.majorProfiles) {
        expect(
          p.shadow.en.trim().toLowerCase(),
          isNot(equals(p.reversed.expression.en.trim().toLowerCase())),
          reason: p.canonicalCardId,
        );
      }
    },
  );
}
