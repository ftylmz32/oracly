import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/deck/oracly_tarot_deck.dart';
import 'package:oracly_new/features/tarot/narrative/data/narrative_tarot_profile_catalog.dart';
import 'package:oracly_new/features/tarot/narrative/domain/narrative_card_profile_validator.dart';
import 'package:oracly_new/features/tarot/narrative/domain/narrative_symbol_tags.dart';

void main() {
  final majors = OraclyTarotDeck.expectedIds
      .where((id) => id.startsWith('major_'))
      .toList();

  test('canonical deck remains 78 / 22 / 56', () {
    expect(OraclyTarotDeck.all.length, OraclyTarotDeck.expectedCount);
    expect(OraclyTarotDeck.majorArcana.length, OraclyTarotDeck.expectedMajor);
    expect(OraclyTarotDeck.minorArcana.length, OraclyTarotDeck.expectedMinor);
    expect(majors.length, 22);
  });

  test('exactly 22 Major Narrative profiles remain', () {
    expect(NarrativeTarotProfileCatalog.majorProfiles.length, 22);
    for (final p in NarrativeTarotProfileCatalog.majorProfiles) {
      expect(p.canonicalCardId.startsWith('major_'), isTrue);
    }
  });

  test('one Major profile per Major id, no duplicates', () {
    final ids = NarrativeTarotProfileCatalog.majorProfiles
        .map((p) => p.canonicalCardId)
        .toList();
    expect(ids.toSet().length, ids.length);
    expect(ids.toSet(), equals(majors.toSet()));
  });

  test('every Major profile is complete TR/EN/RU', () {
    for (final id in majors) {
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

  test('Major profile ids exist on OraclyTarotDeck', () {
    for (final p in NarrativeTarotProfileCatalog.majorProfiles) {
      expect(OraclyTarotDeck.byId(p.canonicalCardId), isNotNull);
    }
  });

  test('lookup never fabricates missing Pentacles profiles', () {
    expect(NarrativeTarotProfileCatalog.lookup('pentacles_10'), isNull);
    expect(NarrativeTarotProfileCatalog.contains('pentacles_01'), isFalse);
    expect(NarrativeTarotProfileCatalog.lookup('major_99'), isNull);
  });

  test('no cross-Major full profile duplication', () {
    final sigs = <String, String>{};
    for (final p in NarrativeTarotProfileCatalog.majorProfiles) {
      final sig = NarrativeCardProfileValidator.primarySignature(p);
      expect(
        sigs.containsKey(sig),
        isFalse,
        reason: '${p.canonicalCardId} duplicates ${sigs[sig]}',
      );
      sigs[sig] = p.canonicalCardId;
    }
  });

  test('basic locale script sanity on sample Major fields', () {
    final fool = NarrativeTarotProfileCatalog.lookup('major_00')!;
    expect(RegExp(r'[ğüşöçıİĞÜŞÖÇ]').hasMatch(fool.coreMeaning.tr), isTrue);
    expect(RegExp(r'[А-Яа-яЁё]').hasMatch(fool.coreMeaning.ru), isTrue);
    expect(RegExp(r'[A-Za-z]').hasMatch(fool.coreMeaning.en), isTrue);
    final tower = NarrativeTarotProfileCatalog.lookup('major_16')!;
    expect(RegExp(r'[А-Яа-яЁё]').hasMatch(tower.shadow.ru), isTrue);
  });
}
