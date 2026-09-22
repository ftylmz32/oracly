import 'package:flutter_test/flutter_test.dart';

import '../../../support/narrative_tarot_v2/narrative_tarot_v2_corpus_loader.dart';
import '../../../support/narrative_tarot_v2/narrative_tarot_v2_evaluator.dart';
import '../../../support/narrative_tarot_v2/narrative_tarot_v2_hard_failures.dart';
import '../../../support/narrative_tarot_v2/narrative_tarot_v2_language.dart';
import '../../../support/narrative_tarot_v2/narrative_tarot_v2_text.dart';

/// Phase 2.1 hardening self-checks (false-positive / coverage gates).
void main() {
  final corpus = Ntv2CorpusLoader.load();

  test('no PASS scenario is wrong-language dominant', () {
    for (final s in corpus.scenarios.where((s) => s.expected.pass)) {
      final text = Ntv2TextHeuristics.allText(
        s.candidate,
        (s.candidate['beats'] as List? ?? const []).cast<Map>(),
      );
      expect(
        Ntv2LanguageContract.isMismatch(s.locale, text),
        isFalse,
        reason: s.id,
      );
    }
  });

  test('all 15 hard tags appear in intentional FAIL fixtures', () {
    final seen = <String>{};
    for (final s in corpus.scenarios) {
      seen.addAll(s.expected.hardFailures);
    }
    expect(seen, containsAll(Ntv2HardFailure.all));
  });

  test('spread_fact_mismatch has intentional fixtures', () {
    final n = corpus.scenarios
        .where(
          (s) => s.expected.hardFailures.contains(
            Ntv2HardFailure.spreadFactMismatch,
          ),
        )
        .length;
    expect(n, greaterThanOrEqualTo(1));
  });

  test('PASS primary narratives are distinct', () {
    final sigs = <String, List<String>>{};
    for (final s in corpus.scenarios.where((s) => s.expected.pass)) {
      final sig = Ntv2TextHeuristics.primarySignature(s.candidate);
      sigs.putIfAbsent(sig, () => []).add(s.id);
    }
    final dups = sigs.entries.where((e) => e.value.length > 1).toList();
    expect(dups, isEmpty, reason: '$dups');
  });

  test(
    'same-cards different-question PASS pairs differ in grounding/focus',
    () {
      final groups = <String, List<dynamic>>{};
      for (final s in corpus.scenarios.where((s) => s.expected.pass)) {
        final cards = (s.input['cards'] as List).cast<Map>();
        final key = [
          s.input['spreadId'],
          ...cards.map((c) => '${c['canonicalCardId']}:${c['isReversed']}'),
        ].join('|');
        groups.putIfAbsent(key, () => []).add(s);
      }
      var pairCount = 0;
      for (final list in groups.values) {
        if (list.length < 2) continue;
        final questions = list
            .map((s) => '${s.input['questionText']}')
            .where((q) => q.trim().isNotEmpty)
            .toSet();
        if (questions.length < 2) continue;
        final anchors = list
            .map(
              (s) => ((s.input['groundingAnchors'] as List?) ?? const []).join(
                '|',
              ),
            )
            .toSet();
        final sigs = list
            .map((s) => Ntv2TextHeuristics.primarySignature(s.candidate))
            .toSet();
        expect(anchors.length, greaterThanOrEqualTo(2), reason: '$questions');
        expect(sigs.length, equals(list.length), reason: '$questions');
        pairCount++;
      }
      expect(pairCount, greaterThanOrEqualTo(2));
    },
  );

  test('language coverage includes non-stock mismatch per locale', () {
    for (final loc in ['tr', 'en', 'ru']) {
      final passes = corpus.scenarios.where(
        (s) => s.locale == loc && s.expected.pass,
      );
      expect(passes.length, greaterThanOrEqualTo(2), reason: loc);
      final mismatches = corpus.scenarios.where(
        (s) =>
            s.locale == loc &&
            s.expected.hardFailures.contains(Ntv2HardFailure.languageMismatch),
      );
      expect(mismatches, isNotEmpty, reason: loc);
      expect(
        mismatches.any(
          (s) =>
              s.tags.contains('non_stock') ||
              s.tags.contains('mixed') ||
              s.category.contains('non_stock') ||
              s.category.contains('mixed') ||
              s.id.contains('NOSTK') ||
              s.id.contains('MIX') ||
              s.id.contains('DETAIL-LANG'),
        ),
        isTrue,
        reason: '$loc non-stock',
      );
    }
  });

  test('cardDetails-only defects are detected', () {
    for (final id in const [
      'NTV2-TR-DETAIL-CERT-001',
      'NTV2-TR-DETAIL-LANG-001',
      'NTV2-TR-DETAIL-UNDRAWN-001',
      'NTV2-TR-DETAIL-UNKNOWN-001',
      'NTV2-TR-SPREAD-FACT-001',
    ]) {
      final s = corpus.scenarios.firstWhere((x) => x.id == id);
      final eval = Ntv2ContractEvaluator.evaluate(s);
      expect(s.expected.pass, isFalse, reason: id);
      expect(eval.hardFailures, isNotEmpty, reason: id);
      expect(eval.hardFailures, equals(s.expected.hardFailures.toSet()));
    }
  });

  test('question grounding never uses length alone', () {
    // Fixture with long irrelevant prose and no anchors should fail grounding
    // when kind is explicit — covered by MEM-002 / soft fails.
    final explicit = corpus.scenarios.where(
      (s) =>
          '${s.input['questionKind']}' == 'explicit' &&
          ((s.input['groundingAnchors'] as List?)?.isNotEmpty ?? false),
    );
    expect(explicit, isNotEmpty);
    for (final s in explicit.where((s) => s.expected.pass)) {
      final text = Ntv2TextHeuristics.allText(
        s.candidate,
        (s.candidate['beats'] as List? ?? const []).cast<Map>(),
      ).toLowerCase();
      final anchors = ((s.input['groundingAnchors'] as List?) ?? const [])
          .cast<String>();
      expect(
        anchors.any((a) => text.contains(a.toLowerCase())),
        isTrue,
        reason: s.id,
      );
    }
  });
}
