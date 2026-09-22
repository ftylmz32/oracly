import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/deck/oracly_tarot_deck.dart';
import 'package:oracly_new/features/tarot/narrative/data/narrative_tarot_profile_catalog.dart';
import 'package:oracly_new/features/tarot/narrative/domain/narrative_card_profile_validator.dart';
import 'package:oracly_new/features/tarot/narrative/domain/narrative_symbol_tags.dart';

/// Phase 3B4 — exact equality: V2 catalog ids == canonical deck ids.
void main() {
  test('NarrativeTarotProfileCatalog ids == OraclyTarotDeck.expectedIds', () {
    final catalogIds = NarrativeTarotProfileCatalog.all
        .map((p) => p.canonicalCardId)
        .toSet();
    final deckIds = OraclyTarotDeck.expectedIds.toSet();

    expect(catalogIds.length, 78);
    expect(deckIds.length, 78);
    expect(NarrativeTarotProfileCatalog.count, 78);
    expect(NarrativeTarotProfileCatalog.all.length, 78);
    expect(NarrativeTarotProfileCatalog.majorProfiles.length, 22);
    expect(NarrativeTarotProfileCatalog.wandsProfiles.length, 14);
    expect(NarrativeTarotProfileCatalog.cupsProfiles.length, 14);
    expect(NarrativeTarotProfileCatalog.swordsProfiles.length, 14);
    expect(NarrativeTarotProfileCatalog.pentaclesProfiles.length, 14);
    expect(NarrativeTarotProfileCatalog.minorProfiles.length, 56);

    final missing = deckIds.difference(catalogIds);
    final extra = catalogIds.difference(deckIds);
    expect(missing, isEmpty, reason: 'missing: $missing');
    expect(extra, isEmpty, reason: 'extra: $extra');

    final listIds = NarrativeTarotProfileCatalog.all
        .map((p) => p.canonicalCardId)
        .toList();
    expect(listIds.length, listIds.toSet().length, reason: 'duplicates');
  });

  test('all 78 profiles pass structural authoring invariants', () {
    for (final p in NarrativeTarotProfileCatalog.all) {
      final id = p.canonicalCardId;
      expect(OraclyTarotDeck.byId(id), isNotNull, reason: id);
      expect(NarrativeCardProfileValidator.isComplete(p), isTrue, reason: id);
      expect(p.profileRevision, greaterThanOrEqualTo(1), reason: id);
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

  test('no full-profile duplication across all 78 V2 profiles', () {
    final sigs = <String, String>{};
    for (final p in NarrativeTarotProfileCatalog.all) {
      final sig = NarrativeCardProfileValidator.primarySignature(p);
      expect(
        sigs.containsKey(sig),
        isFalse,
        reason: '${p.canonicalCardId} duplicates ${sigs[sig]}',
      );
      sigs[sig] = p.canonicalCardId;
    }
  });

  test('lookup never fabricates unknown ids', () {
    expect(NarrativeTarotProfileCatalog.lookup('major_99'), isNull);
    expect(NarrativeTarotProfileCatalog.lookup('pentacles_99'), isNull);
    expect(NarrativeTarotProfileCatalog.contains('fake_card'), isFalse);
  });
}
