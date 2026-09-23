import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/data/narrative_tarot_profile_catalog.dart';
import 'package:oracly_new/features/tarot/narrative/domain/narrative_keyword_ids.dart';
import 'package:oracly_new/features/tarot/narrative/domain/reversed_transform_kind.dart';

/// Phase 3C.5E — FR-M04 canonical keyword ontology invariants + Appendix B fixture.
void main() {
  late Map<String, dynamic> fixture;
  late List<Map<String, dynamic>> rows;

  setUpAll(() {
    final raw = File(
      'test/fixtures/tarot_keyword_ontology_v1.json',
    ).readAsStringSync();
    fixture = jsonDecode(raw) as Map<String, dynamic>;
    rows = (fixture['rows'] as List).cast<Map<String, dynamic>>();
  });

  test('catalog is 78 and ontology defines 128 ids', () {
    expect(NarrativeTarotProfileCatalog.all.length, 78);
    expect(NarrativeKeywordIds.all.length, 128);
    expect(NarrativeKeywordIds.ontologyRevision, 1);
    expect(fixture['definedVocabulary'], 128);
    expect(rows.length, 156);
  });

  test('canonical ids are stable lowerCamelCase', () {
    final re = RegExp(r'^[a-z][a-zA-Z0-9]*$');
    for (final id in NarrativeKeywordIds.all) {
      expect(id, isNotEmpty);
      expect(re.hasMatch(id), isTrue, reason: id);
      expect(id.contains(' '), isFalse);
    }
    expect(
      NarrativeKeywordIds.all.length,
      NarrativeKeywordIds.all.toSet().length,
    );
  });

  test('every production keyword belongs to canonical set', () {
    for (final p in NarrativeTarotProfileCatalog.all) {
      for (final id in [...p.upright.keywordIds, ...p.reversed.keywordIds]) {
        expect(
          NarrativeKeywordIds.all.contains(id),
          isTrue,
          reason: '${p.canonicalCardId} has non-canonical $id',
        );
      }
    }
  });

  test('projected ontology metrics match 3C.5D.1', () {
    final freq = <String, int>{};
    var assignments = 0;
    var uprightSum = 0;
    var reversedSum = 0;
    for (final p in NarrativeTarotProfileCatalog.all) {
      uprightSum += p.upright.keywordIds.length;
      reversedSum += p.reversed.keywordIds.length;
      for (final id in p.upright.keywordIds) {
        freq[id] = (freq[id] ?? 0) + 1;
        assignments++;
      }
      for (final id in p.reversed.keywordIds) {
        freq[id] = (freq[id] ?? 0) + 1;
        assignments++;
      }
    }
    final used = freq.length;
    final singletons = freq.values.where((c) => c == 1).length;
    expect(assignments, 439);
    expect(used, 122);
    expect(singletons, 30);
    expect(100.0 * singletons / used, closeTo(24.59, 0.05));
    expect(uprightSum / 78, closeTo(2.76, 0.01));
    expect(reversedSum / 78, closeTo(2.87, 0.01));

    final top = freq.entries.reduce((a, b) => a.value >= b.value ? a : b);
    expect(top.key, 'scatter');
    expect(top.value, 14);
  });

  test('orientation density, uniqueness, and upright/reversed distinction', () {
    for (final p in NarrativeTarotProfileCatalog.all) {
      for (final ori in [p.upright, p.reversed]) {
        expect(ori.keywordIds.length, inInclusiveRange(2, 4));
        expect(ori.keywordIds.toSet().length, ori.keywordIds.length);
      }
      expect(
        p.upright.keywordIds.toSet(),
        isNot(p.reversed.keywordIds.toSet()),
        reason: p.canonicalCardId,
      );
    }
  });

  test('no unsafe accusation/certainty keyword ids', () {
    const unsafe = {
      'cheating',
      'liar',
      'disease',
      'pregnancy',
      'deathPrediction',
      'guaranteedProfit',
      'criminal',
      'soulmate',
      'destinedPartner',
    };
    expect(NarrativeKeywordIds.all.intersection(unsafe), isEmpty);
    for (final p in NarrativeTarotProfileCatalog.all) {
      final ids = {...p.upright.keywordIds, ...p.reversed.keywordIds};
      expect(ids.intersection(unsafe), isEmpty, reason: p.canonicalCardId);
    }
  });

  test('all 156 orientations match Appendix B fixture (set equality)', () {
    final byKey = <String, Set<String>>{};
    for (final row in rows) {
      final key = '${row['canonicalCardId']}|${row['orientation']}';
      byKey[key] = Set<String>.from((row['keywordIds'] as List).cast<String>());
    }
    expect(byKey.length, 156);

    final seen = <String>{};
    for (final p in NarrativeTarotProfileCatalog.all) {
      for (final entry in [
        ('upright', p.upright.keywordIds),
        ('reversed', p.reversed.keywordIds),
      ]) {
        final key = '${p.canonicalCardId}|${entry.$1}';
        seen.add(key);
        expect(byKey.containsKey(key), isTrue, reason: 'missing fixture $key');
        expect(entry.$2.toSet(), byKey[key], reason: key);
      }
    }
    expect(seen.length, 156);
    expect(seen, byKey.keys.toSet());
  });

  test('locked polarity regressions from 3C.5D.1', () {
    Set<String> ids(String card, bool upright) {
      final p = NarrativeTarotProfileCatalog.lookup(card)!;
      return (upright ? p.upright : p.reversed).keywordIds.toSet();
    }

    expect(ids('wands_08', true), {'momentum', 'messenger', 'flow'});
    expect(ids('wands_08', true).contains('haste'), isFalse);

    expect(ids('swords_12', true), {'momentum', 'communication', 'clarity'});
    expect(ids('swords_12', true).contains('haste'), isFalse);

    expect(ids('pentacles_02', true), {'coordination', 'balance', 'focus'});
    expect(ids('pentacles_02', true).contains('imbalance'), isFalse);
    expect(ids('pentacles_02', true).contains('scatter'), isFalse);

    expect(ids('major_11', true), {'balance', 'truth', 'accountability'});
    expect(ids('major_14', true), {'balance', 'integration', 'restraint'});
    expect(ids('wands_13', false), {'control', 'envy', 'withdrawal'});
    expect(ids('major_04', false), {'rigidity', 'control', 'instability'});
    expect(ids('major_10', false), {'resistance', 'delay', 'instability'});
    expect(ids('cups_02', false), {'imbalance', 'projection', 'haste'});
    expect(ids('cups_13', false), {'overflow', 'boundary', 'rescue'});
  });

  test('approved antonym pairs remain distinct canonical ids', () {
    const pairs = [
      ('balance', 'imbalance'),
      ('stability', 'instability'),
      ('momentum', 'haste'),
      ('belonging', 'isolation'),
      ('abundance', 'scarcity'),
      ('inquiry', 'curiosity'),
    ];
    for (final pair in pairs) {
      expect(
        NarrativeKeywordIds.all.contains(pair.$1),
        isTrue,
        reason: pair.$1,
      );
      expect(
        NarrativeKeywordIds.all.contains(pair.$2),
        isTrue,
        reason: pair.$2,
      );
      expect(pair.$1, isNot(pair.$2));
    }
  });

  test('transform-named keywords require additional semantic content', () {
    const transformNames = {
      'internalization',
      'delay',
      'excess',
      'deficiency',
      'avoidance',
      'distortion',
      'blockedExpression',
      'misdirection',
      'release',
      'privateInternal',
    };
    const allowedDual = {'delay', 'avoidance', 'release'};

    for (final p in NarrativeTarotProfileCatalog.all) {
      final kw = p.reversed.keywordIds.toSet();
      final transformIds = p.reversed.transforms.map((t) => t.name).toSet();
      final overlap = kw.intersection(transformNames);
      if (overlap.isEmpty) continue;
      for (final id in overlap) {
        expect(
          allowedDual.contains(id),
          isTrue,
          reason: '${p.canonicalCardId} $id',
        );
      }
      final nonTransform = kw.difference(transformNames);
      expect(
        nonTransform,
        isNotEmpty,
        reason: '${p.canonicalCardId} transform-only keywords',
      );
      expect(p.reversed.transforms, isA<List<ReversedTransformKind>>());
      expect(transformIds, isNotEmpty);
    }
  });

  test('court upright keyword sets are not collapsed within a suit', () {
    const courts = {
      'wands': ['wands_11', 'wands_12', 'wands_13', 'wands_14'],
      'cups': ['cups_11', 'cups_12', 'cups_13', 'cups_14'],
      'swords': ['swords_11', 'swords_12', 'swords_13', 'swords_14'],
      'pentacles': [
        'pentacles_11',
        'pentacles_12',
        'pentacles_13',
        'pentacles_14',
      ],
    };
    for (final entry in courts.entries) {
      final sets = entry.value.map((id) {
        return NarrativeTarotProfileCatalog.lookup(
          id,
        )!.upright.keywordIds.toSet();
      }).toList();
      expect(sets.toSet().length, greaterThan(1), reason: entry.key);
    }
  });
}
