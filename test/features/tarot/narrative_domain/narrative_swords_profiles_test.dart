import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/deck/oracly_tarot_deck.dart';
import 'package:oracly_new/features/tarot/narrative/data/narrative_tarot_profile_catalog.dart';
import 'package:oracly_new/features/tarot/narrative/domain/narrative_card_profile_validator.dart';
import 'package:oracly_new/features/tarot/narrative/domain/narrative_symbol_tags.dart';

void main() {
  const expectedSwords = [
    'swords_01',
    'swords_02',
    'swords_03',
    'swords_04',
    'swords_05',
    'swords_06',
    'swords_07',
    'swords_08',
    'swords_09',
    'swords_10',
    'swords_11',
    'swords_12',
    'swords_13',
    'swords_14',
  ];

  String blobOf(String id) {
    final p = NarrativeTarotProfileCatalog.lookup(id)!;
    final buf = StringBuffer();
    for (final f in p.semanticFields) {
      buf
        ..writeln(f.tr)
        ..writeln(f.en)
        ..writeln(f.ru);
    }
    return buf.toString();
  }

  test('exactly 14 Swords profiles with canonical ids', () {
    expect(NarrativeTarotProfileCatalog.swordsProfiles.length, 14);
    final ids = NarrativeTarotProfileCatalog.swordsProfiles.map(
      (p) => p.canonicalCardId,
    );
    expect(ids.toSet(), equals(expectedSwords.toSet()));
    expect(ids.length, ids.toSet().length);
  });

  test('Swords remain 14 within completed 78-profile V2 catalog', () {
    expect(NarrativeTarotProfileCatalog.swordsProfiles.length, 14);
    expect(NarrativeTarotProfileCatalog.count, 78);
    expect(NarrativeTarotProfileCatalog.minorProfiles.length, 56);
    for (final p in NarrativeTarotProfileCatalog.swordsProfiles) {
      expect(p.canonicalCardId.startsWith('swords_'), isTrue);
    }
  });

  test('every Swords id exists on OraclyTarotDeck and is complete', () {
    for (final id in expectedSwords) {
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

  test('no full-profile duplication across Swords profiles', () {
    final sigs = <String, String>{};
    for (final p in NarrativeTarotProfileCatalog.swordsProfiles) {
      final sig = NarrativeCardProfileValidator.primarySignature(p);
      expect(
        sigs.containsKey(sig),
        isFalse,
        reason: '${p.canonicalCardId} duplicates ${sigs[sig]}',
      );
      sigs[sig] = p.canonicalCardId;
    }
  });

  test('Swords Ace-10 and courts have distinct key semantics', () {
    final cores = NarrativeTarotProfileCatalog.swordsProfiles
        .map((p) => p.coreMeaning.en.trim().toLowerCase())
        .toList();
    expect(cores.toSet().length, 14);

    final courts = [
      for (final id in ['swords_11', 'swords_12', 'swords_13', 'swords_14'])
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

  test('high-risk Swords pairs remain semantically distinct', () {
    String core(String id) =>
        NarrativeTarotProfileCatalog.lookup(id)!.coreMeaning.en.toLowerCase();
    expect(core('swords_02'), isNot(equals(core('swords_08'))));
    expect(core('swords_03'), isNot(equals(core('swords_05'))));
    expect(core('swords_04'), isNot(equals(core('swords_09'))));
    expect(core('swords_08'), isNot(equals(core('swords_09'))));
    expect(core('swords_09'), isNot(equals(core('swords_10'))));
    expect(core('swords_13'), isNot(equals(core('swords_14'))));
  });

  /// Authoring guard only — not a complete safety proof.
  test('Swords fields reject clinical / accusation / violence assertions', () {
    final patterns = <RegExp>[
      RegExp(
        r'\byou have (a |an )?(mental illness|depression|anxiety disorder|ocd|ptsd|psychosis|paranoia|personality disorder)\b',
        caseSensitive: false,
      ),
      RegExp(r'\byou are (depressed|paranoid)\b', caseSensitive: false),
      RegExp(
        r'\bthey (are plotting|want to hurt you|betrayed you|are lying to you)\b',
        caseSensitive: false,
      ),
      RegExp(r'\bthis person is dangerous\b', caseSensitive: false),
      RegExp(r'\byou will be attacked\b', caseSensitive: false),
      RegExp(r'\byou (are going to|will) die\b', caseSensitive: false),
      RegExp(r'\bsomeone close will die\b', caseSensitive: false),
      RegExp(r'\byou should hurt (them|yourself)\b', caseSensitive: false),
      RegExp(r'\bkill yourself\b', caseSensitive: false),
      RegExp(
        r'ruhsal hastalık|anksiyete bozukluğu|depresyonsun',
        caseSensitive: false,
      ),
      RegExp(r'öldürecek(ler)?|kendine zarar ver', caseSensitive: false),
      RegExp(r'они (лгут|предали|замышляют)', caseSensitive: false),
      RegExp(r'ты умрёшь|убей себя', caseSensitive: false),
    ];
    for (final p in NarrativeTarotProfileCatalog.swordsProfiles) {
      final text = blobOf(p.canonicalCardId);
      for (final re in patterns) {
        expect(
          re.hasMatch(text),
          isFalse,
          reason: '${p.canonicalCardId} matched ${re.pattern}',
        );
      }
    }
  });

  /// Automated limitation: string patterns only; does not prove interpretive safety.
  test(
    'swords_10 preserves mental ending, not physical death or self-harm',
    () {
      final text = blobOf('swords_10').toLowerCase();
      expect(
        text.contains('mental') ||
            text.contains('zihin') ||
            text.contains('умствен'),
        isTrue,
      );
      expect(RegExp(r'\bphysical death\b').hasMatch(text), isFalse);
      expect(RegExp(r'\bsuicide\b').hasMatch(text), isFalse);
      expect(RegExp(r'\bfatal (injury|event)\b').hasMatch(text), isFalse);
      expect(RegExp(r'\byou will die\b').hasMatch(text), isFalse);
      expect(RegExp(r'intihar|kendini öldür').hasMatch(text), isFalse);
      expect(RegExp(r'самоубийств|ты умрёшь').hasMatch(text), isFalse);
      final core = NarrativeTarotProfileCatalog.lookup(
        'swords_10',
      )!.coreMeaning;
      expect(core.en.toLowerCase().contains('mental'), isTrue);
      expect(core.en.toLowerCase().contains('body'), isTrue);
    },
  );

  test('swords_09 describes rumination without diagnosis or prophecy', () {
    final text = blobOf('swords_09').toLowerCase();
    expect(
      text.contains('night') ||
          text.contains('gece') ||
          text.contains('ночн') ||
          text.contains('worry') ||
          text.contains('kaygı') ||
          text.contains('тревог'),
      isTrue,
    );
    expect(RegExp(r'\banxiety disorder\b').hasMatch(text), isFalse);
    expect(RegExp(r'\bdepression\b').hasMatch(text), isFalse);
    expect(
      RegExp(
        r'\bthis (fear|worry) (will|shall) (happen|come true)\b',
      ).hasMatch(text),
      isFalse,
    );
  });
}
