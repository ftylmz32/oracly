import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/data/narrative_tarot_profile_catalog.dart';
import 'package:oracly_new/features/tarot/narrative/domain/narrative_card_profile.dart';

/// Phase 3C.3A — RT-M03A opener / template monotony diagnostics (part 1).
///
/// Gates only coreMeaning / desire / shadow. Interaction fields are out of scope.
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

  int phraseCount(Iterable<NarrativeCardProfile> profiles, RegExp pat) {
    var n = 0;
    for (final p in profiles) {
      for (final s in [p.coreMeaning.en, p.desire.en, p.shadow.en]) {
        n += pat.allMatches(s.toLowerCase()).length;
      }
    }
    return n;
  }

  final all = NarrativeTarotProfileCatalog.all;

  test('RT-M03A catalog still has 78 profiles', () {
    expect(all.length, 78);
  });

  test('RT-M03A opener share ≤25% for core/desire/shadow × TR/EN/RU', () {
    final checks = <String, String Function(NarrativeCardProfile)>{
      'core.tr': (p) => p.coreMeaning.tr,
      'core.en': (p) => p.coreMeaning.en,
      'core.ru': (p) => p.coreMeaning.ru,
      'desire.tr': (p) => p.desire.tr,
      'desire.en': (p) => p.desire.en,
      'desire.ru': (p) => p.desire.ru,
      'shadow.tr': (p) => p.shadow.tr,
      'shadow.en': (p) => p.shadow.en,
      'shadow.ru': (p) => p.shadow.ru,
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
  });

  test('RT-M03A historical EN stems substantially reduced', () {
    // Baseline at Phase 3C.3A start: it speaks of=62, wish=78, slide=47.
    expect(phraseCount(all, RegExp(r'\bit speaks of\b')), lessThan(20));
    expect(phraseCount(all, RegExp(r'\bthere may be a wish\b')), lessThan(20));
    expect(phraseCount(all, RegExp(r'\bmay slide into\b')), lessThan(20));
  });

  test(
    'RT-M03A no exact substantial cross-card duplicates in target fields',
    () {
      final buckets = <String, List<String>>{
        'core.en': [],
        'desire.en': [],
        'shadow.en': [],
        'core.tr': [],
        'desire.tr': [],
        'shadow.tr': [],
        'core.ru': [],
        'desire.ru': [],
        'shadow.ru': [],
      };
      for (final p in all) {
        buckets['core.en']!.add(p.coreMeaning.en.trim());
        buckets['desire.en']!.add(p.desire.en.trim());
        buckets['shadow.en']!.add(p.shadow.en.trim());
        buckets['core.tr']!.add(p.coreMeaning.tr.trim());
        buckets['desire.tr']!.add(p.desire.tr.trim());
        buckets['shadow.tr']!.add(p.shadow.tr.trim());
        buckets['core.ru']!.add(p.coreMeaning.ru.trim());
        buckets['desire.ru']!.add(p.desire.ru.trim());
        buckets['shadow.ru']!.add(p.shadow.ru.trim());
      }
      final dups = <String>[];
      for (final entry in buckets.entries) {
        final seen = <String, int>{};
        for (final s in entry.value) {
          if (s.length < 24) continue;
          seen[s] = (seen[s] ?? 0) + 1;
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

  test('RT-M03A shadow≠reversed.expression exact EN clones remain 0', () {
    final clones = <String>[];
    for (final p in all) {
      final s = p.shadow.en.trim().toLowerCase();
      final r = p.reversed.expression.en.trim().toLowerCase();
      if (s.isNotEmpty && s == r) clones.add(p.canonicalCardId);
    }
    expect(clones, isEmpty, reason: clones.join(', '));
  });

  test('RT-M03A cups_09/10 relationshipDynamic distinction preserved', () {
    final a = NarrativeTarotProfileCatalog.lookup('cups_09')!;
    final b = NarrativeTarotProfileCatalog.lookup('cups_10')!;
    expect(a.relationshipDynamic.en, isNot(equals(b.relationshipDynamic.en)));
    expect(
      a.relationshipDynamic.en.toLowerCase().contains('personal') ||
          a.relationshipDynamic.en.toLowerCase().contains('contentment') ||
          a.relationshipDynamic.en.toLowerCase().contains('oneself'),
      isTrue,
    );
    expect(
      b.relationshipDynamic.en.toLowerCase().contains('shared') ||
          b.relationshipDynamic.en.toLowerCase().contains('circle') ||
          b.relationshipDynamic.en.toLowerCase().contains('more than one'),
      isTrue,
    );
  });

  test('RT-M03A.1 replacement-scaffold concentration stays bounded', () {
    final scaffolds = <String, RegExp>{
      'At the center:': RegExp(r'^At the center:', multiLine: true),
      'The meaning turns on': RegExp(
        r'^The meaning turns on\b',
        multiLine: true,
      ),
      'Part of this archetype': RegExp(
        r'^Part of this archetype\b',
        multiLine: true,
      ),
      'At the edge of this archetype': RegExp(
        r'^At the edge of this archetype\b',
        multiLine: true,
      ),
      'What is wanted is': RegExp(r'^What is wanted is\b', multiLine: true),
      'The pull is': RegExp(r'^The pull is\b', multiLine: true),
      'A need to': RegExp(r'^A need to\b', multiLine: true),
      'The energy leans toward': RegExp(
        r'^The energy leans toward\b',
        multiLine: true,
      ),
      'Without balance': RegExp(r'^Without balance\b', multiLine: true),
      'The risk is': RegExp(r'^The risk is\b', multiLine: true),
    };
    final heavy = <String>[];
    for (final entry in scaffolds.entries) {
      var n = 0;
      for (final p in all) {
        for (final s in [p.coreMeaning.en, p.desire.en, p.shadow.en]) {
          if (entry.value.hasMatch(s.trim())) n++;
        }
      }
      // Soft cap: occasional natural use OK; mass scaffolding not.
      if (n > 8) heavy.add('${entry.key}=$n');
    }
    expect(heavy, isEmpty, reason: heavy.join(', '));
  });

  test('RT-M03A.1 no fragmentary At-the-edge noun-list shadows', () {
    final bad = <String>[];
    final verb = RegExp(
      r'\b(can|may|becomes?|turns?|hardens?|appears?|is|are|does|do)\b',
      caseSensitive: false,
    );
    for (final p in all) {
      final s = p.shadow.en.trim();
      if (!s.startsWith('At the edge of this archetype,')) continue;
      final rest = s.substring('At the edge of this archetype,'.length);
      if (!verb.hasMatch(rest)) bad.add(p.canonicalCardId);
    }
    expect(bad, isEmpty, reason: bad.join(', '));
  });

  test(
    'RT-M03A.1 high-risk EN shadows stay grammatical and non-telegraphic',
    () {
      String sh(String id) =>
          NarrativeTarotProfileCatalog.lookup(id)!.shadow.en.toLowerCase();
      expect(sh('swords_09').contains('catastrophe-dream'), isFalse);
      expect(sh('swords_09').contains('insomnia-identity'), isFalse);
      expect(sh('swords_09').contains('guilt-load'), isFalse);
      expect(
        sh('swords_09').contains('can') || sh('swords_09').contains('may'),
        isTrue,
      );
      expect(
        sh('pentacles_07').contains('waiting') ||
            sh('pentacles_07').contains('patience'),
        isTrue,
      );
      expect(
        sh('pentacles_07').startsWith('at the edge of this archetype,'),
        isFalse,
      );
    },
  );
}
