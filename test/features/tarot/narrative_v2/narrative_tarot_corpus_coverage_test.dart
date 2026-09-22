import 'package:flutter_test/flutter_test.dart';

import '../../../support/narrative_tarot_v2/narrative_tarot_v2_corpus_loader.dart';

/// Coverage gates — Phase 2 acceptance minimums.
void main() {
  final corpus = Ntv2CorpusLoader.load();
  final scenarios = corpus.scenarios;

  Set<String> locales() => scenarios.map((s) => s.locale).toSet();
  Set<String> spreads() =>
      scenarios.map((s) => '${s.input['spreadId']}').toSet();
  Set<String> tags() => {for (final s in scenarios) ...s.tags};
  Set<String> categories() => scenarios.map((s) => s.category).toSet();

  bool anyTag(String t) => tags().contains(t);
  bool anyCat(String c) => categories().any((x) => x.contains(c)) || anyTag(c);

  test('language coverage TR/EN/RU with pass and fail', () {
    expect(locales(), containsAll(['tr', 'en', 'ru']));
    for (final loc in ['tr', 'en', 'ru']) {
      final slice = scenarios.where((s) => s.locale == loc).toList();
      expect(slice.any((s) => s.expected.pass), isTrue, reason: loc);
      expect(slice.any((s) => !s.expected.pass), isTrue, reason: loc);
      expect(
        slice.any((s) => s.expected.hardFailures.contains('language_mismatch')),
        isTrue,
        reason: '$loc language_mismatch',
      );
    }
    expect(
      scenarios.where((s) => s.locale == 'tr').length,
      greaterThan(scenarios.where((s) => s.locale == 'en').length),
    );
  });

  test('spread contracts including signature specs', () {
    expect(
      spreads(),
      containsAll([
        'classical.single',
        'classical.threeCard',
        'classical.fiveCard',
        'classical.sevenCard',
        'classical.celticCross',
        'signature.the_mirror',
        'signature.between_us',
      ]),
    );
  });

  test('question / intention categories represented', () {
    for (final need in [
      'explicit',
      'relationship',
      'decision',
      'career',
      'family',
      'self',
      'breakup',
      'new_relationship',
      'indecision',
      'transition',
      'open',
      'no_question',
    ]) {
      expect(
        anyCat(need) ||
            scenarios.any(
              (s) =>
                  '${s.input['questionKind']}'.contains(need) ||
                  s.id.toLowerCase().contains(need) ||
                  s.category.toLowerCase().contains(need) ||
                  s.tags.any((t) => t.contains(need)),
            ),
        isTrue,
        reason: need,
      );
    }
  });

  test('orientation, memory, recurrence, relationship coverage', () {
    expect(anyTag('orientation') || anyCat('orientation'), isTrue);
    expect(anyTag('memory') || anyCat('memory'), isTrue);
    expect(anyTag('recurrence') || anyCat('recurrence'), isTrue);
    expect(anyTag('relationship') || anyCat('relationship'), isTrue);

    expect(
      scenarios.any(
        (s) => s.expected.hardFailures.contains('deleted_evidence_used'),
      ),
      isTrue,
    );
    expect(
      scenarios.any(
        (s) => s.expected.hardFailures.contains('foreign_account_evidence'),
      ),
      isTrue,
    );
    expect(
      scenarios.any(
        (s) => s.expected.hardFailures.contains('recurrence_count_mismatch'),
      ),
      isTrue,
    );
    expect(
      scenarios.any(
        (s) => s.expected.hardFailures.contains('fabricated_recurrence'),
      ),
      isTrue,
    );
  });

  test('all-card accounting, certainty, safety covered', () {
    expect(
      scenarios.any((s) => s.expected.flags['allCardsAccountedFor'] == false),
      isTrue,
    );
    expect(
      scenarios.any(
        (s) => s.expected.hardFailures.contains('unsupported_certainty'),
      ),
      isTrue,
    );
    expect(
      scenarios.any(
        (s) => s.expected.hardFailures.contains('safety_violation'),
      ),
      isTrue,
    );
  });

  test('positive and negative balance', () {
    final pass = scenarios.where((s) => s.expected.pass).length;
    final fail = scenarios.where((s) => !s.expected.pass).length;
    expect(pass, greaterThan(20));
    expect(fail, greaterThan(15));
  });

  test('paired same-cards different questions exist', () {
    final byCards = <String, List<String>>{};
    for (final s in scenarios) {
      final key = (s.input['cards'] as List)
          .map((c) => (c as Map)['canonicalCardId'])
          .join('|');
      byCards.putIfAbsent(key, () => []).add(s.id);
    }
    expect(byCards.values.any((ids) => ids.length >= 2), isTrue);
  });
}
