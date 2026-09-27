/// Dream Phase 2.1 — known TR local-copy nits closed; structured entry
/// context round-trips without touching display tags.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/ai/production/models/dream_ai_analysis.dart';
import 'package:oracly_new/features/dream/data/dream_record_mapper.dart';
import 'package:oracly_new/features/dream/models/dream.dart';
import 'package:oracly_new/features/dream/models/dream_entry_context.dart';
import 'package:oracly_new/features/dream/models/dream_entry_selection.dart';
import 'package:oracly_new/features/dream/models/dream_insight.dart';
import 'package:oracly_new/features/dream/services/dream_analysis_beats.dart';
import 'package:oracly_new/features/dream/services/dream_analysis_facts.dart';
import 'package:oracly_new/features/dream/services/dream_experience_service.dart';

import '../../support/dream_test_owner.dart';
import 'dream_honesty_fakes.dart';
import 'dream_phase2_support.dart';

DreamAnalysisFacts _tr(String emotion) => DreamAnalysisFacts(
      told: phase2Narrative,
      scene: 'sessiz bir ev',
      emotion: emotion,
      language: 'tr',
    );

void main() {
  tearDown(() => OraclyL10n.bind('tr'));

  test('"Ev · Ev" — an item filling image and place is shown once', () async {
    // No provider symbols, so the symbols line is composed locally while the
    // required premium sections stay accepted AI.
    final result = await DreamExperienceService(
      repository: MemDreamRepository(),
      owner: testDreamOwner(),
      ai: ScriptedDreamAi(DreamAiAnalysis(
        summary: phase2AllAccepted.summary,
        symbols: const [],
        emotionalTheme: phase2AllAccepted.emotionalTheme,
        interpretation: phase2AllAccepted.interpretation,
        dailyLifeReflection: phase2AllAccepted.dailyLifeReflection,
        conclusion: phase2AllAccepted.conclusion,
      )),
    ).analyze(narrative: phase2Narrative);
    final symbols = result.dream.insights
        .singleWhere((i) => i.kind == DreamInsightKind.symbols)
        .body;
    final items = symbols.split(' · ').map((s) => s.trim().toLowerCase());
    expect(items.toSet().length, items.length, reason: symbols);
    expect(symbols, isNot(contains('Ev · Ev')));
  });

  group('TR sentence start', () {
    // Slot 1 opens with the softened (lowercased) feeling.
    test('a lowercased feeling opens the sentence capitalized', () {
      expect(DreamAnalysisBeats.feeling(_tr('Korkulu'), 1),
          startsWith('Korkulu bir ton'));
    });

    test('Turkish i / ı keep their dot rules', () {
      expect(DreamAnalysisBeats.feeling(_tr('ılık'), 1), startsWith('Ilık bir'));
      expect(DreamAnalysisBeats.feeling(_tr('içli'), 1), startsWith('İçli bir'));
      expect(DreamAnalysisBeats.feeling(_tr('İçli'), 1), startsWith('İçli bir'));
      expect(DreamAnalysisBeats.feeling(_tr('İçli'), 1), isNot(contains('\u0307')));
    });

    test('every TR feeling slot starts with an uppercase letter', () {
      for (var seed = 0; seed < 6; seed++) {
        final text = DreamAnalysisBeats.feeling(_tr('Huzurlu'), seed);
        expect(text[0], isNot(text[0].toLowerCase()), reason: text);
      }
    });
  });

  test('entry context round-trips through JSON and DreamRecord', () {
    final entry = DreamEntrySelection.of(
      chips: {DreamEntryChipId.clear, DreamEntryChipId.nightmare},
      guided: {
        DreamGuidedQuestionId.where: '  Liman  ',
        DreamGuidedQuestionId.who: '   ',
      },
    );
    expect(entry.chips, [DreamEntryChipId.nightmare, DreamEntryChipId.clear]);
    expect(entry.guided, {DreamGuidedQuestionId.where: 'Liman'});
    final dream = Dream(
      id: 'd1',
      narrative: phase2Narrative,
      recordedAt: DateTime(2026, 9, 27),
      tags: const ['Kabus gördüm'],
      entry: entry,
    );
    final back = DreamRecordMapper.fromRecord(DreamRecordMapper.toRecord(dream));
    expect(back.tags, ['Kabus gördüm']);
    expect(back.entry?.chips, entry.chips);
    expect(back.entry?.guided, entry.guided);
    final legacy = Dream.fromJson({
      ...dream.toJson()..remove('entryContext'),
    });
    expect(legacy.entry, isNull);
    expect(
      DreamEntrySelection.fromJson({
        'chips': ['nightmare', 'future_chip'],
        'guided': {'who': 'Leo', 'future_q': 'x'},
      }).toJson(),
      {
        'chips': ['nightmare'],
        'guided': {'who': 'Leo'},
      },
    );
  });
}
