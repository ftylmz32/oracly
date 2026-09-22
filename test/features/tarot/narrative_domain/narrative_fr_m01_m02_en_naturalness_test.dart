import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/data/narrative_tarot_profile_catalog.dart';
import 'package:oracly_new/features/tarot/narrative/domain/narrative_card_profile.dart';
import 'package:oracly_new/features/tarot/narrative/domain/reversed_transform_kind.dart';

/// Phase 3C.5C — FR-M01 / FR-M02 authored EN prose naturalness.
void main() {
  List<String> authoredEn(NarrativeCardProfile p) => [
    p.coreMeaning.en,
    p.light.en,
    p.shadow.en,
    p.tension.en,
    p.desire.en,
    p.fear.en,
    p.relationshipDynamic.en,
    p.decisionDynamic.en,
    p.actionDirection.en,
    p.upright.expression.en,
    p.reversed.expression.en,
  ];

  String normalize(String raw) {
    var s = raw.trim().toLowerCase();
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    s = s.replaceAll(RegExp(r'''[.,;:!?\-—–"'()\[\]]+'''), '');
    return s.trim();
  }

  test('swords_09 authored EN has no FR-M01 compound shorthand', () {
    final p = NarrativeTarotProfileCatalog.lookup('swords_09')!;
    final blob = authoredEn(p).join('\n').toLowerCase();
    for (final bad in [
      'mind-load',
      'night-mind',
      'night-load',
      'catastrophe-dream',
      'insomnia-identity',
      'guilt-load',
    ]) {
      expect(blob.contains(bad), isFalse, reason: 'found "$bad"');
    }
  });

  test('cups_10 authored EN has no circle-culture', () {
    final p = NarrativeTarotProfileCatalog.lookup('cups_10')!;
    final blob = authoredEn(p).join('\n').toLowerCase();
    expect(blob.contains('circle-culture'), isFalse);
  });

  test('swords_09 reverse transforms stay excess + internalization', () {
    expect(
      NarrativeTarotProfileCatalog.lookup('swords_09')!.reversed.transforms,
      [ReversedTransformKind.excess, ReversedTransformKind.internalization],
    );
  });

  test('swords_09 shadow ≠ reversed.expression EN', () {
    final p = NarrativeTarotProfileCatalog.lookup('swords_09')!;
    expect(
      normalize(p.shadow.en),
      isNot(equals(normalize(p.reversed.expression.en))),
    );
  });

  test('swords_09 reversed still anchors excess and inward turn', () {
    final en = NarrativeTarotProfileCatalog.lookup(
      'swords_09',
    )!.reversed.expression.en.toLowerCase();
    expect(
      en.contains('catastrophic') ||
          en.contains('swell') ||
          en.contains('larger'),
      isTrue,
      reason: en,
    );
    expect(
      en.contains('inward') || en.contains('guilt') || en.contains('sleepless'),
      isTrue,
      reason: en,
    );
  });

  test('cups_10 relationship still anchors shared multi-person belonging', () {
    final en = NarrativeTarotProfileCatalog.lookup(
      'cups_10',
    )!.relationshipDynamic.en.toLowerCase();
    expect(
      en.contains('shared') ||
          en.contains('circle') ||
          en.contains('wellbeing'),
      isTrue,
      reason: en,
    );
    expect(en.contains('more than one'), isTrue, reason: en);
  });

  test('cups_09 vs cups_10 relationship distinction stays green', () {
    final a = NarrativeTarotProfileCatalog.lookup(
      'cups_09',
    )!.relationshipDynamic.en.toLowerCase();
    final b = NarrativeTarotProfileCatalog.lookup(
      'cups_10',
    )!.relationshipDynamic.en.toLowerCase();
    expect(a.contains('personal') || a.contains('contentment'), isTrue);
    expect(b.contains('shared') || b.contains('circle'), isTrue);
    expect(normalize(a), isNot(equals(normalize(b))));
  });
}
