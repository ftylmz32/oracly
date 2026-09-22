import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/deck/oracly_tarot_deck.dart';
import 'package:oracly_new/features/tarot/narrative/data/narrative_tarot_profile_catalog.dart';
import 'package:oracly_new/features/tarot/narrative/domain/narrative_card_profile_validator.dart';
import 'package:oracly_new/features/tarot/narrative/domain/narrative_symbol_tags.dart';

void main() {
  const expectedWands = [
    'wands_01',
    'wands_02',
    'wands_03',
    'wands_04',
    'wands_05',
    'wands_06',
    'wands_07',
    'wands_08',
    'wands_09',
    'wands_10',
    'wands_11',
    'wands_12',
    'wands_13',
    'wands_14',
  ];

  test('exactly 14 Wands profiles with canonical ids', () {
    expect(NarrativeTarotProfileCatalog.wandsProfiles.length, 14);
    final ids = NarrativeTarotProfileCatalog.wandsProfiles.map(
      (p) => p.canonicalCardId,
    );
    expect(ids.toSet(), equals(expectedWands.toSet()));
    expect(ids.length, ids.toSet().length);
  });

  test('Wands remain 14 within expanded V2 catalog; no Pentacles', () {
    expect(NarrativeTarotProfileCatalog.wandsProfiles.length, 14);
    expect(NarrativeTarotProfileCatalog.majorProfiles.length, 22);
    expect(NarrativeTarotProfileCatalog.count, greaterThanOrEqualTo(36));
    for (final p in NarrativeTarotProfileCatalog.wandsProfiles) {
      expect(p.canonicalCardId.startsWith('wands_'), isTrue);
    }
    expect(NarrativeTarotProfileCatalog.lookup('pentacles_01'), isNull);
  });

  test('no full-profile duplication across Wands profiles', () {
    final sigs = <String, String>{};
    for (final p in NarrativeTarotProfileCatalog.wandsProfiles) {
      final sig = NarrativeCardProfileValidator.primarySignature(p);
      expect(
        sigs.containsKey(sig),
        isFalse,
        reason: '${p.canonicalCardId} duplicates ${sigs[sig]}',
      );
      sigs[sig] = p.canonicalCardId;
    }
  });

  test('every Wands id exists on OraclyTarotDeck and is complete', () {
    for (final id in expectedWands) {
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

  test('Wands Ace-10 and courts have distinct core meanings', () {
    final cores = NarrativeTarotProfileCatalog.wandsProfiles
        .map((p) => p.coreMeaning.en.trim().toLowerCase())
        .toList();
    expect(cores.toSet().length, 14);

    final courts = [
      NarrativeTarotProfileCatalog.lookup('wands_11')!,
      NarrativeTarotProfileCatalog.lookup('wands_12')!,
      NarrativeTarotProfileCatalog.lookup('wands_13')!,
      NarrativeTarotProfileCatalog.lookup('wands_14')!,
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
  });

  /// Automated limitation: this proves structural uniqueness across Ace–10,
  /// not classical Tarot correctness of the authored meanings.
  test('Wands Ace-10 progression signatures are unique', () {
    final pip = NarrativeTarotProfileCatalog.wandsProfiles.where((p) {
      final n = int.parse(p.canonicalCardId.split('_').last);
      return n >= 1 && n <= 10;
    }).toList();
    expect(pip.length, 10);
    final sigs = pip
        .map(NarrativeCardProfileValidator.primarySignature)
        .toSet();
    expect(sigs.length, 10);
  });
}
