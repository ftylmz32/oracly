import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/data/narrative_tarot_profile_catalog.dart';

import 'narrative_fr_m03_support.dart';

/// Phase 3C.5B — FR-M03 shadow vs reversed.expression separation.
void main() {
  test('FR-M03 targets remain present in catalog', () {
    for (final id in kFrM03Targets) {
      expect(NarrativeTarotProfileCatalog.lookup(id), isNotNull, reason: id);
    }
  });

  test('FR-M03 shadow ≠ reversed.expression exact normalization TR/EN/RU', () {
    final clones = <String>[];
    for (final id in kFrM03Targets) {
      final p = NarrativeTarotProfileCatalog.lookup(id)!;
      for (final loc in const ['tr', 'en', 'ru']) {
        final left = frM03Normalize(p.shadow.of(loc));
        final right = frM03Normalize(p.reversed.expression.of(loc));
        if (left.isNotEmpty && left == right) clones.add('$id:$loc');
      }
    }
    expect(clones, isEmpty, reason: clones.join(', '));
  });

  test('FR-M03 reversed transforms remain the Phase 3C.4 assignments', () {
    for (final id in kFrM03Targets) {
      expect(
        NarrativeTarotProfileCatalog.lookup(id)!.reversed.transforms,
        kFrM03ExpectedTransforms[id],
        reason: id,
      );
    }
  });

  test('cups_11 reversed anchors sensitivity/sign/dream mechanism', () {
    final en = frM03RevEn('cups_11');
    expect(
      en.contains('feeling') || en.contains('sensation') || en.contains('sign'),
      isTrue,
      reason: en,
    );
    expect(
      en.contains('swell') ||
          en.contains('dream') ||
          en.contains('imagination') ||
          en.contains('bend'),
      isTrue,
      reason: en,
    );
  });

  test('swords_11 reversed anchors inquiry/listening misdirection', () {
    final en = frM03RevEn('swords_11');
    expect(
      en.contains('inquir') || en.contains('question') || en.contains('listen'),
      isTrue,
      reason: en,
    );
    expect(
      en.contains('rumor') ||
          en.contains('rush') ||
          en.contains('steer') ||
          en.contains('answer'),
      isTrue,
      reason: en,
    );
  });

  test('swords_13 reversed anchors clarity/boundary warmth loss', () {
    final en = frM03RevEn('swords_13');
    expect(
      en.contains('clarity') || en.contains('boundary') || en.contains('line'),
      isTrue,
      reason: en,
    );
    expect(
      en.contains('warmth') ||
          en.contains('humane') ||
          en.contains('cutting') ||
          en.contains('defense'),
      isTrue,
      reason: en,
    );
  });

  test('swords_14 reversed anchors principle/judgment context loss', () {
    final en = frM03RevEn('swords_14');
    expect(
      en.contains('principle') ||
          en.contains('judgment') ||
          en.contains('structure'),
      isTrue,
      reason: en,
    );
    expect(
      en.contains('context') ||
          en.contains('detached') ||
          en.contains('control') ||
          en.contains('fair'),
      isTrue,
      reason: en,
    );
  });

  test('wands_11 reversed anchors spark/inquiry scatter-excess', () {
    final en = frM03RevEn('wands_11');
    expect(
      en.contains('spark') ||
          en.contains('fire') ||
          en.contains('ask') ||
          en.contains('listen'),
      isTrue,
      reason: en,
    );
    expect(
      en.contains('scatter') ||
          en.contains('outrun') ||
          en.contains('showing') ||
          en.contains('exploratory'),
      isTrue,
      reason: en,
    );
  });

  test('FR-M03 locale triples stay non-empty', () {
    for (final id in kFrM03Targets) {
      final expr = NarrativeTarotProfileCatalog.lookup(id)!.reversed.expression;
      expect(expr.tr.trim(), isNotEmpty, reason: id);
      expect(expr.en.trim(), isNotEmpty, reason: id);
      expect(expr.ru.trim(), isNotEmpty, reason: id);
    }
  });
}
