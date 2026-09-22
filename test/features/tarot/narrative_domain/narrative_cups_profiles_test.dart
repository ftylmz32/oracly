import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/deck/oracly_tarot_deck.dart';
import 'package:oracly_new/features/tarot/narrative/data/narrative_tarot_profile_catalog.dart';
import 'package:oracly_new/features/tarot/narrative/domain/narrative_card_profile_validator.dart';
import 'package:oracly_new/features/tarot/narrative/domain/narrative_symbol_tags.dart';

void main() {
  const expectedCups = [
    'cups_01',
    'cups_02',
    'cups_03',
    'cups_04',
    'cups_05',
    'cups_06',
    'cups_07',
    'cups_08',
    'cups_09',
    'cups_10',
    'cups_11',
    'cups_12',
    'cups_13',
    'cups_14',
  ];

  test('exactly 14 Cups profiles with canonical ids', () {
    expect(NarrativeTarotProfileCatalog.cupsProfiles.length, 14);
    final ids = NarrativeTarotProfileCatalog.cupsProfiles.map(
      (p) => p.canonicalCardId,
    );
    expect(ids.toSet(), equals(expectedCups.toSet()));
    expect(ids.length, ids.toSet().length);
  });

  test('catalog totals 50 = 22 Major + 14 Wands + 14 Cups', () {
    expect(NarrativeTarotProfileCatalog.count, 50);
    expect(NarrativeTarotProfileCatalog.all.length, 50);
    expect(NarrativeTarotProfileCatalog.majorProfiles.length, 22);
    expect(NarrativeTarotProfileCatalog.wandsProfiles.length, 14);
    expect(NarrativeTarotProfileCatalog.cupsProfiles.length, 14);
    expect(NarrativeTarotProfileCatalog.minorProfiles.length, 28);
    for (final p in NarrativeTarotProfileCatalog.all) {
      final id = p.canonicalCardId;
      expect(
        id.startsWith('major_') ||
            id.startsWith('wands_') ||
            id.startsWith('cups_'),
        isTrue,
        reason: id,
      );
      expect(id.startsWith('swords_'), isFalse);
      expect(id.startsWith('pentacles_'), isFalse);
    }
    expect(NarrativeTarotProfileCatalog.lookup('swords_01'), isNull);
    expect(NarrativeTarotProfileCatalog.lookup('pentacles_01'), isNull);
  });

  test('every Cups id exists on OraclyTarotDeck and is complete', () {
    for (final id in expectedCups) {
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

  test('no full-profile duplication across all 50 V2 profiles', () {
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

  test('Cups Ace-10 and courts have distinct key semantics', () {
    final cores = NarrativeTarotProfileCatalog.cupsProfiles
        .map((p) => p.coreMeaning.en.trim().toLowerCase())
        .toList();
    expect(cores.toSet().length, 14);

    final courts = [
      for (final id in ['cups_11', 'cups_12', 'cups_13', 'cups_14'])
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

  test('high-risk Cups pairs remain semantically distinct', () {
    String core(String id) =>
        NarrativeTarotProfileCatalog.lookup(id)!.coreMeaning.en.toLowerCase();
    String rel(String id) => NarrativeTarotProfileCatalog.lookup(
      id,
    )!.relationshipDynamic.en.toLowerCase();

    expect(core('cups_02'), isNot(equals(core('cups_06'))));
    expect(rel('cups_02'), isNot(equals(rel('cups_06'))));
    expect(core('cups_04'), isNot(equals(core('cups_08'))));
    expect(core('cups_07'), isNot(equals(core('cups_09'))));
    expect(core('cups_09'), isNot(equals(core('cups_10'))));
  });

  /// Authoring guard only — not a complete safety proof.
  test('Cups fields reject obvious mind-reading destiny phrases', () {
    final patterns = <RegExp>[
      RegExp(r'\bthey secretly love\b', caseSensitive: false),
      RegExp(r'\b(he|she) loves you\b', caseSensitive: false),
      RegExp(r'\bthey will come back\b', caseSensitive: false),
      RegExp(r'\bthey are cheating\b', caseSensitive: false),
      RegExp(r'\bthey secretly want you\b', caseSensitive: false),
      RegExp(r'\bthis is your soulmate\b', caseSensitive: false),
      RegExp(r'\bthey miss you\b', caseSensitive: false),
      RegExp(r'seni (gizli gizli )?seviyor', caseSensitive: false),
      RegExp(r'geri d[oö]necek(ler)?', caseSensitive: false),
      RegExp(r'aldat[ıi]yor', caseSensitive: false),
      RegExp(r'ruh e[sş]in', caseSensitive: false),
      RegExp(r'он[аи]? тебя тайно люб', caseSensitive: false),
      RegExp(r'он[аи]? верн[её]тся к тебе', caseSensitive: false),
      RegExp(r'твоя родственная душа', caseSensitive: false),
    ];

    for (final p in NarrativeTarotProfileCatalog.cupsProfiles) {
      final blob = StringBuffer();
      for (final f in p.semanticFields) {
        blob
          ..writeln(f.tr)
          ..writeln(f.en)
          ..writeln(f.ru);
      }
      final text = blob.toString();
      for (final re in patterns) {
        expect(
          re.hasMatch(text),
          isFalse,
          reason: '${p.canonicalCardId} matched ${re.pattern}',
        );
      }
    }
  });
}
