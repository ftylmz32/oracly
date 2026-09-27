// Dream Phase 4A — the recurring-thread section: localized, exact, local,
// absent without history, deduplicated, and invisible to provenance.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/dream/history/dream_history_evidence.dart';
import 'package:oracly_new/features/dream/history/dream_history_insight.dart';
import 'package:oracly_new/features/dream/models/dream.dart';
import 'package:oracly_new/features/dream/models/dream_insight.dart';
import 'package:oracly_new/features/dream/presentation/reference/dream_result_history_card.dart';
import 'package:oracly_new/features/dream/services/dream_reading_presentation.dart';
import 'package:oracly_new/features/dream/services/dream_reading_provenance.dart';

import 'dream_phase4a_support.dart';

final _last = DateTime(2021, 3, 2, 9);

DreamHistoryEvidence _door(int priors, String label) => DreamHistoryEvidence(
      kind: DreamHistoryEvidenceKind.symbol,
      canonicalKey: 'symbol:door',
      displayLabel: label,
      priorDreamCount: priors,
      priorDreamIds: [for (var i = 0; i < priors; i++) 'p$i'],
      firstSeenAt: DateTime(2021, 3, 1, 9),
      lastSeenAt: _last,
    );

Dream _reading({String? life}) => Dream(
      id: 'current',
      narrative: doorTr3,
      recordedAt: day(20),
      insights: [
        const DreamInsight(
          kind: DreamInsightKind.mainInterpretation,
          title: 'Anlam',
          body: 'Kapının önünde beklemek, durup dinlemeye yer açıyor olabilir.',
          source: DreamInsightSource.ai,
        ),
        if (life != null)
          DreamInsight(
            kind: DreamInsightKind.personalConnection,
            title: 'Hayatına',
            body: life,
            source: DreamInsightSource.ai,
          ),
      ],
    );

List<DreamInsightKind> _kinds(Dream d) =>
    [for (final s in DreamReadingPresentation.sections(d)) s.kind];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => OraclyL10n.bind('tr'));

  // (label, recurring title, recurring line, seen title, seen line)
  const cases = {
    'tr': (
      'Kapı',
      'Tekrar eden iz',
      'Kapı: bu rüya dahil son rüyalarından 3 tanesinde var; en son {d}.',
      'Tanıdık bir iz',
      'Kapı: daha önce bir rüyanda da vardı ({d}).',
    ),
    'en': (
      'door',
      'Recurring thread',
      'Door: in 3 of your recent dreams, this one included; last seen {d}.',
      'A familiar thread',
      'Door: was in one earlier dream too ({d}).',
    ),
    'ru': (
      'дверь',
      'Повторяющаяся нить',
      'Дверь: среди недавних снов таких 3, включая этот; в последний раз — {d}.',
      'Знакомая нить',
      'Дверь: это уже было в одном прошлом сне ({d}).',
    ),
  };

  for (final MapEntry(key: lang, value: c) in cases.entries) {
    test('$lang: localized title and exact counts from saved records', () {
      final date = OraclyFormat.dateNumeric(_last, languageCode: lang);
      final recurring =
          DreamHistoryInsight.of(DreamHistoryContext([_door(2, c.$1)]), lang)!;
      expect(recurring.title, c.$2);
      expect(recurring.body, c.$3.replaceAll('{d}', date));
      expect(recurring.source, DreamInsightSource.local);

      final seen =
          DreamHistoryInsight.of(DreamHistoryContext([_door(1, c.$1)]), lang)!;
      expect(seen.title, c.$4);
      expect(seen.body, c.$5.replaceAll('{d}', date));
    });
  }

  test('no history: section absent from insights and presentation', () {
    expect(DreamHistoryInsight.of(DreamHistoryContext.empty, 'tr'), isNull);
    final dream =
        DreamHistoryInsight.attach(_reading(), DreamHistoryContext.empty, 'tr');
    expect(_kinds(dream), isNot(contains(DreamInsightKind.recurringPattern)));
  });

  test('with history: its own section after the personal connection', () {
    final dream = DreamHistoryInsight.attach(
      _reading(life: 'Bugün bir kapıyı aralık bırakıp neyi beklediğine bak.'),
      DreamHistoryContext([_door(2, 'Kapı')]),
      'tr',
    );
    expect(_kinds(dream), [
      DreamInsightKind.mainInterpretation,
      DreamInsightKind.personalConnection,
      DreamInsightKind.recurringPattern,
    ]);
    final body = DreamReadingPresentation.sections(dream).last.body;
    for (final prior in [doorTr, doorTr2]) {
      expect(body, isNot(contains(prior)));
    }
  });

  test('attach replaces a stale section instead of stacking it', () {
    final first = DreamHistoryInsight.attach(
        _reading(), DreamHistoryContext([_door(2, 'Kapı')]), 'tr');
    final again = DreamHistoryInsight.attach(
        first, DreamHistoryContext([_door(1, 'Kapı')]), 'tr');
    final sections = again.insights
        .where((i) => i.kind == DreamInsightKind.recurringPattern);
    expect(sections.single.title, 'Tanıdık bir iz');
    final cleared =
        DreamHistoryInsight.attach(again, DreamHistoryContext.empty, 'tr');
    expect(_kinds(cleared), isNot(contains(DreamInsightKind.recurringPattern)));
  });

  test('provider already said the same line: shown once', () {
    final history = DreamHistoryContext([_door(2, 'Kapı')]);
    final line = DreamHistoryInsight.of(history, 'tr')!.body;
    final dream =
        DreamHistoryInsight.attach(_reading(life: 'Evet. $line'), history, 'tr');
    expect(_kinds(dream), isNot(contains(DreamInsightKind.recurringPattern)));
    expect(_kinds(dream), contains(DreamInsightKind.personalConnection));
  });

  test('provenance is unchanged by the local section', () {
    final plain = _reading(life: 'Bugün kapıyı aralık bırak.');
    final attached = DreamHistoryInsight.attach(
        plain, DreamHistoryContext([_door(2, 'Kapı')]), 'tr');
    expect(DreamReadingProvenance.of(attached),
        DreamReadingProvenance.of(plain));
  });

  testWidgets('result card renders only with history', (tester) async {
    final dream = DreamHistoryInsight.attach(
        _reading(), DreamHistoryContext([_door(2, 'Kapı')]), 'tr');
    await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: DreamResultHistoryCard(dream: dream))));
    expect(find.text('Tekrar eden iz'), findsOneWidget);

    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: DreamResultHistoryCard(dream: _reading()))));
    expect(find.text('Tekrar eden iz'), findsNothing);
  });
}
