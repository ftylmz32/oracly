import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/data/narrative_tarot_profile_catalog.dart';
import 'package:oracly_new/features/tarot/narrative/domain/narrative_card_profile.dart';

/// Phase 3C.3B — RT-M03 interaction-field diversity diagnostics (part 2).
///
/// Gates only relationshipDynamic / decisionDynamic / actionDirection.
/// Core/desire/shadow remain covered (and frozen) by the RT-M03A suite.
void main() {
  const maxOpenerShare = 0.25;
  const openerTokenCount = 4;

  String openerStem(String raw) {
    final lower = raw.trim().toLowerCase();
    final toks = RegExp(
      r"[a-zà-öø-ÿāăąćĉċčđēĕėęěĝğġģĥħĩīĭįıĵķĺļľŀłńņňŋōŏőœŕŗřśŝşšţťŧũūŭůűųŵŷźżžа-яё]+",
      caseSensitive: false,
      unicode: true,
    ).allMatches(lower).map((m) => m.group(0)!).toList();
    if (toks.isEmpty) return '';
    return toks.take(openerTokenCount).join(' ');
  }

  Map<String, int> histogram(
    Iterable<NarrativeCardProfile> profiles,
    String Function(NarrativeCardProfile) pick,
  ) {
    final freq = <String, int>{};
    for (final p in profiles) {
      final stem = openerStem(pick(p));
      freq[stem] = (freq[stem] ?? 0) + 1;
    }
    return freq;
  }

  Set<String> tokens(String s) => RegExp(
    r'[a-zà-öø-ÿа-яё]{3,}',
    caseSensitive: false,
    unicode: true,
  ).allMatches(s.toLowerCase()).map((m) => m.group(0)!).toSet();

  double jaccard(Set<String> a, Set<String> b) {
    if (a.isEmpty || b.isEmpty) return 0;
    return a.intersection(b).length / a.union(b).length;
  }

  final all = NarrativeTarotProfileCatalog.all;

  test('RT-M03B catalog still has 78 profiles', () {
    expect(all.length, 78);
  });

  test(
    'RT-M03B interaction opener share <=25% for relationship/decision/action × TR/EN/RU',
    () {
      final checks = <String, String Function(NarrativeCardProfile)>{
        'relationship.tr': (p) => p.relationshipDynamic.tr,
        'relationship.en': (p) => p.relationshipDynamic.en,
        'relationship.ru': (p) => p.relationshipDynamic.ru,
        'decision.tr': (p) => p.decisionDynamic.tr,
        'decision.en': (p) => p.decisionDynamic.en,
        'decision.ru': (p) => p.decisionDynamic.ru,
        'action.tr': (p) => p.actionDirection.tr,
        'action.en': (p) => p.actionDirection.en,
        'action.ru': (p) => p.actionDirection.ru,
      };

      final failures = <String>[];
      for (final entry in checks.entries) {
        final freq = histogram(all, entry.value);
        final top = freq.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final maxCount = top.first.value;
        final maxPct = maxCount / 78.0;
        if (maxPct > maxOpenerShare + 1e-9) {
          failures.add(
            '${entry.key}: "${top.first.key}" = $maxCount '
            '(${(maxPct * 100).toStringAsFixed(1)}%)',
          );
        }
      }
      expect(failures, isEmpty, reason: failures.join(' | '));
    },
  );

  test('RT-M03B historical EN interaction stems substantially reduced', () {
    int count(RegExp pat) {
      var n = 0;
      for (final p in all) {
        n += pat.allMatches(p.relationshipDynamic.en.toLowerCase()).length;
        n += pat.allMatches(p.decisionDynamic.en.toLowerCase()).length;
        n += pat.allMatches(p.actionDirection.en.toLowerCase()).length;
      }
      return n;
    }

    // Historical Phase 3C / 3C.3B baseline: in a bond=52, the choice=60,
    // asks to separate=39, do not=62.
    expect(count(RegExp(r'\bthe choice\b')), lessThan(5));
    expect(count(RegExp(r'\basks to separate\b')), equals(0));
    expect(count(RegExp(r'\bin a bond\b')), lessThan(10));
    expect(count(RegExp(r'\bdo not\b')), lessThan(15));
  });

  test(
    'RT-M03B no exact substantial cross-card duplicates in interaction fields',
    () {
      final buckets = <String, List<String>>{
        'relationship.en': [],
        'decision.en': [],
        'action.en': [],
        'relationship.tr': [],
        'decision.tr': [],
        'action.tr': [],
        'relationship.ru': [],
        'decision.ru': [],
        'action.ru': [],
      };
      for (final p in all) {
        buckets['relationship.en']!.add(p.relationshipDynamic.en.trim());
        buckets['decision.en']!.add(p.decisionDynamic.en.trim());
        buckets['action.en']!.add(p.actionDirection.en.trim());
        buckets['relationship.tr']!.add(p.relationshipDynamic.tr.trim());
        buckets['decision.tr']!.add(p.decisionDynamic.tr.trim());
        buckets['action.tr']!.add(p.actionDirection.tr.trim());
        buckets['relationship.ru']!.add(p.relationshipDynamic.ru.trim());
        buckets['decision.ru']!.add(p.decisionDynamic.ru.trim());
        buckets['action.ru']!.add(p.actionDirection.ru.trim());
      }
      final dups = <String>[];
      for (final entry in buckets.entries) {
        final seen = <String, int>{};
        for (final s in entry.value) {
          if (s.length < 24) continue;
          seen[s.toLowerCase()] = (seen[s.toLowerCase()] ?? 0) + 1;
        }
        for (final e in seen.entries) {
          if (e.value > 1) {
            dups.add('${entry.key} x${e.value}: ${e.key.substring(0, 40)}…');
          }
        }
      }
      expect(dups, isEmpty, reason: dups.join(' | '));
    },
  );

  test(
    'RT-M03B same-card relationship/decision/action are not paraphrases (EN)',
    () {
      final flagged = <String>[];
      for (final p in all) {
        final r = tokens(p.relationshipDynamic.en);
        final d = tokens(p.decisionDynamic.en);
        final a = tokens(p.actionDirection.en);
        final rd = jaccard(r, d);
        final ra = jaccard(r, a);
        final da = jaccard(d, a);
        if (rd >= 0.5 || ra >= 0.5 || da >= 0.5) {
          flagged.add(
            '${p.canonicalCardId}: rel-dec=${rd.toStringAsFixed(2)} '
            'rel-act=${ra.toStringAsFixed(2)} dec-act=${da.toStringAsFixed(2)}',
          );
        }
        expect(
          p.relationshipDynamic.en.trim().toLowerCase(),
          isNot(equals(p.decisionDynamic.en.trim().toLowerCase())),
          reason: p.canonicalCardId,
        );
        expect(
          p.relationshipDynamic.en.trim().toLowerCase(),
          isNot(equals(p.actionDirection.en.trim().toLowerCase())),
          reason: p.canonicalCardId,
        );
        expect(
          p.decisionDynamic.en.trim().toLowerCase(),
          isNot(equals(p.actionDirection.en.trim().toLowerCase())),
          reason: p.canonicalCardId,
        );
      }
      expect(flagged, isEmpty, reason: flagged.join(' | '));
    },
  );

  test('RT-M03B EN actionDirection leading-verb share <=25%', () {
    final leadFreq = <String, int>{};
    for (final p in all) {
      final text = p.actionDirection.en.trim();
      final m = RegExp(
        r"^[a-zà-öø-ÿ']+",
        caseSensitive: false,
      ).firstMatch(text.toLowerCase());
      final lead = m?.group(0) ?? '(none)';
      leadFreq[lead] = (leadFreq[lead] ?? 0) + 1;
    }
    final top = leadFreq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxPct = top.first.value / 78.0;
    expect(
      maxPct,
      lessThanOrEqualTo(0.25),
      reason:
          '"${top.first.key}" = ${top.first.value} (${leadFreq.length} distinct leads)',
    );
  });

  test('RT-M03B cups_03 <-> cups_10 decisionDynamic collapse resolved', () {
    final c3 = NarrativeTarotProfileCatalog.lookup('cups_03')!;
    final c10 = NarrativeTarotProfileCatalog.lookup('cups_10')!;
    final sc = jaccard(
      tokens(c3.decisionDynamic.en),
      tokens(c10.decisionDynamic.en),
    );
    // Historical RT-m01 was ~0.64; remediated fields must not remain high-similarity.
    expect(sc, lessThan(0.45), reason: 'similarity=$sc');
    expect(
      c3.decisionDynamic.en.trim().toLowerCase(),
      isNot(equals(c10.decisionDynamic.en.trim().toLowerCase())),
    );
  });

  test(
    'RT-M03B cups_09/10 relationshipDynamic regression (RT-M01 stays frozen)',
    () {
      final a = NarrativeTarotProfileCatalog.lookup('cups_09')!;
      final b = NarrativeTarotProfileCatalog.lookup('cups_10')!;
      expect(a.relationshipDynamic.en, isNot(equals(b.relationshipDynamic.en)));
      final sc = jaccard(
        tokens(a.relationshipDynamic.en),
        tokens(b.relationshipDynamic.en),
      );
      expect(sc, lessThan(0.45), reason: 'similarity=$sc');
      expect(
        a.relationshipDynamic.en.toLowerCase().contains('personal') ||
            a.relationshipDynamic.en.toLowerCase().contains('contentment'),
        isTrue,
      );
      expect(
        b.relationshipDynamic.en.toLowerCase().contains('shared') ||
            b.relationshipDynamic.en.toLowerCase().contains('circle'),
        isTrue,
      );
    },
  );

  test(
    'RT-M03B interaction fields avoid destiny / mind-reading / unsafe certainty (EN)',
    () {
      for (final p in all) {
        for (final blob in [
          p.relationshipDynamic.en.toLowerCase(),
          p.decisionDynamic.en.toLowerCase(),
          p.actionDirection.en.toLowerCase(),
        ]) {
          expect(RegExp(r'\bthey love you\b').hasMatch(blob), isFalse);
          expect(RegExp(r'\bthey are cheating\b').hasMatch(blob), isFalse);
          expect(RegExp(r'\bthey are lying\b').hasMatch(blob), isFalse);
          expect(RegExp(r'\byou belong together\b').hasMatch(blob), isFalse);
          expect(RegExp(r'\bwill last\b').hasMatch(blob), isFalse);
          expect(RegExp(r'\bsoulmate\b').hasMatch(blob), isFalse);
          expect(RegExp(r'\bleave them\b').hasMatch(blob), isFalse);
          expect(
            RegExp(r'\bbuy the\b|\bsell the\b|\binvest in\b').hasMatch(blob),
            isFalse,
          );
        }
      }
    },
  );
}
