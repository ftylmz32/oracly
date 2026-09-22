import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/deck/oracly_tarot_deck.dart';
import 'package:oracly_new/features/tarot/narrative/data/narrative_tarot_profile_catalog.dart';
import 'package:oracly_new/features/tarot/narrative/domain/narrative_card_profile_validator.dart';
import 'package:oracly_new/features/tarot/narrative/domain/narrative_symbol_tags.dart';

void main() {
  const expectedPentacles = [
    'pentacles_01',
    'pentacles_02',
    'pentacles_03',
    'pentacles_04',
    'pentacles_05',
    'pentacles_06',
    'pentacles_07',
    'pentacles_08',
    'pentacles_09',
    'pentacles_10',
    'pentacles_11',
    'pentacles_12',
    'pentacles_13',
    'pentacles_14',
  ];

  test('exactly 14 Pentacles profiles with canonical ids', () {
    expect(NarrativeTarotProfileCatalog.pentaclesProfiles.length, 14);
    final ids = NarrativeTarotProfileCatalog.pentaclesProfiles.map(
      (p) => p.canonicalCardId,
    );
    expect(ids.toSet(), equals(expectedPentacles.toSet()));
    expect(ids.length, ids.toSet().length);
  });

  test('catalog totals 78 = 22 Major + 56 Minor including Pentacles', () {
    expect(NarrativeTarotProfileCatalog.count, 78);
    expect(NarrativeTarotProfileCatalog.majorProfiles.length, 22);
    expect(NarrativeTarotProfileCatalog.wandsProfiles.length, 14);
    expect(NarrativeTarotProfileCatalog.cupsProfiles.length, 14);
    expect(NarrativeTarotProfileCatalog.swordsProfiles.length, 14);
    expect(NarrativeTarotProfileCatalog.pentaclesProfiles.length, 14);
    expect(NarrativeTarotProfileCatalog.minorProfiles.length, 56);
    expect(NarrativeTarotProfileCatalog.lookup('pentacles_01'), isNotNull);
  });

  test('every Pentacles id exists on OraclyTarotDeck and is complete', () {
    for (final id in expectedPentacles) {
      expect(OraclyTarotDeck.byId(id), isNotNull, reason: id);
      final p = NarrativeTarotProfileCatalog.lookup(id);
      expect(p, isNotNull, reason: id);
      expect(NarrativeCardProfileValidator.isComplete(p!), isTrue, reason: id);
      expect(p.profileRevision, greaterThanOrEqualTo(1));
      expect(p.upright.transforms, isEmpty, reason: id);
      expect(p.reversed.transforms, isNotEmpty, reason: id);
      expect(
        NarrativeCardProfileValidator.uprightDiffersFromReversed(p),
        isTrue,
        reason: id,
      );
      expect(
        NarrativeCardProfileValidator.hasMechanicalFieldDuplication(p),
        isFalse,
        reason: id,
      );
      for (final tag in p.symbolTags) {
        expect(NarrativeSymbolTags.all, contains(tag), reason: '$id $tag');
      }
    }
  });

  test('Pentacles Ace-10 and courts have distinct key semantics', () {
    final cores = NarrativeTarotProfileCatalog.pentaclesProfiles
        .map((p) => p.coreMeaning.en.trim().toLowerCase())
        .toList();
    expect(cores.toSet().length, 14);

    final aceTen = [
      for (var n = 1; n <= 10; n++)
        NarrativeTarotProfileCatalog.lookup(
          'pentacles_${n.toString().padLeft(2, '0')}',
        )!.coreMeaning.en.trim().toLowerCase(),
    ];
    expect(aceTen.toSet().length, 10);

    final courts = [
      for (final id in [
        'pentacles_11',
        'pentacles_12',
        'pentacles_13',
        'pentacles_14',
      ])
        NarrativeTarotProfileCatalog.lookup(id)!,
    ];
    expect(
      courts.map((p) => p.coreMeaning.en.trim().toLowerCase()).toSet().length,
      4,
    );
    expect(
      courts
          .map((p) => p.relationshipDynamic.en.trim().toLowerCase())
          .toSet()
          .length,
      4,
    );
    expect(
      courts
          .map((p) => p.decisionDynamic.en.trim().toLowerCase())
          .toSet()
          .length,
      4,
    );
    expect(
      courts
          .map((p) => p.actionDirection.en.trim().toLowerCase())
          .toSet()
          .length,
      4,
    );
  });

  /// Distinguishes cores only — not mystical correctness.
  test('high-risk Pentacles pairs remain semantically distinct', () {
    String core(String id) =>
        NarrativeTarotProfileCatalog.lookup(id)!.coreMeaning.en.toLowerCase();
    expect(core('pentacles_02'), isNot(equals(core('pentacles_04'))));
    expect(core('pentacles_03'), isNot(equals(core('pentacles_08'))));
    expect(core('pentacles_05'), isNot(equals(core('pentacles_07'))));
    expect(core('pentacles_06'), isNot(equals(core('pentacles_10'))));
    expect(core('pentacles_07'), isNot(equals(core('pentacles_08'))));
    expect(core('pentacles_09'), isNot(equals(core('pentacles_10'))));
    expect(core('pentacles_13'), isNot(equals(core('pentacles_14'))));
  });
}
