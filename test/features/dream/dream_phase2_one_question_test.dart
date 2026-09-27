/// Dream Phase 2 — the closing carries exactly one open question.
/// None or two-plus is rejected (never trimmed into one); `?` elsewhere in
/// the reading never affects the client closing (the backend Phase 4B gate
/// rejects it before delivery).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/ai/production/ai_failure.dart';
import 'package:oracly_new/features/ai/production/ai_request_exception.dart';
import 'package:oracly_new/features/ai/production/models/dream_ai_analysis.dart';
import 'package:oracly_new/features/dream/models/dream_insight.dart';
import 'package:oracly_new/features/dream/services/dream_analysis_facts.dart';
import 'package:oracly_new/features/dream/services/dream_analysis_guard.dart';
import 'package:oracly_new/features/dream/services/dream_experience_service.dart';

import '../../support/dream_test_owner.dart';
import 'dream_honesty_fakes.dart';
import 'dream_phase2_support.dart';

const _en = 'I was walking along a quiet beach at night and a door stood in the sand.';
const _ru =
    'Мне снилось, что я шла по тихому лесу, а за деревьями светилось окно старого дома.';

DreamAnalysisFacts _facts(String told, String language) =>
    DreamAnalysisFacts(told: told, scene: told, language: language);

Future<DreamInsight> _closing(String conclusion) async {
  final reply = DreamAiAnalysis(
    summary: phase2AllAccepted.summary,
    symbols: phase2AllAccepted.symbols,
    emotionalTheme: 'Sessiz evde açık pencere mi? Dingin bir merak hissediliyor.',
    interpretation: phase2AllAccepted.interpretation,
    dailyLifeReflection: phase2AllAccepted.dailyLifeReflection,
    conclusion: conclusion,
  );
  final result = await DreamExperienceService(
    repository: MemDreamRepository(),
    owner: testDreamOwner(),
    ai: ScriptedDreamAi(reply),
  ).analyze(narrative: phase2Narrative);
  return result.dream.insights
      .singleWhere((i) => i.kind == DreamInsightKind.closingTakeaway);
}

void main() {
  tearDown(() => OraclyL10n.bind('tr'));

  group('guard contract', () {
    final tr = _facts(phase2Narrative, 'tr');
    final en = _facts(_en, 'en');
    final ru = _facts(_ru, 'ru');

    test('1 question accepted — TR / EN / RU / full-width', () {
      expect(DreamAnalysisGuard.conclusion(phase2AllAccepted.conclusion, tr),
          isNotNull);
      expect(
        DreamAnalysisGuard.conclusion(
            'What would you hope to find behind the door in the sand?', en),
        isNotNull,
      );
      expect(
        DreamAnalysisGuard.conclusion(
            'Что ты хотела бы увидеть в окне старого дома?', ru),
        isNotNull,
      );
      expect(
        DreamAnalysisGuard.conclusion(
            'Açık pencereden içeri ne girmesini isterdin？', tr),
        isNotNull,
      );
    });

    test('0 questions rejected', () {
      expect(DreamAnalysisGuard.conclusion(
          'Açık pencereden içeri bir esinti giriyor.', tr), isNull);
      expect(DreamAnalysisGuard.conclusion(
          'The door in the sand stays open.', en), isNull);
      expect(DreamAnalysisGuard.conclusion(null, tr), isNull);
    });

    test('2 questions rejected — never trimmed into one', () {
      expect(
        DreamAnalysisGuard.conclusion(
            'Pencere neden açıktı? Evde kim vardı?', tr),
        isNull,
      );
      expect(
        DreamAnalysisGuard.conclusion(
            'Why was the door in the sand? Who opened it?', en),
        isNull,
      );
      expect(
        DreamAnalysisGuard.conclusion(
            'Почему светилось окно? Кто был в старом доме?', ru),
        isNull,
      );
    });
  });

  group('composed closing', () {
    test('1 question → AI closing, even with ? in another section', () async {
      final closing = await _closing('Açık pencereden içeri ne girmesini isterdin?');
      expect(closing.source, DreamInsightSource.ai);
      expect(DreamAnalysisGuard.questionMarks(closing.body), 1);
    });

    // Phase 4B: the closing is a required premium section — a rejected one
    // is an invalid response, never replaced by a local question.
    for (final bad in [
      'Açık pencereden içeri bir esinti giriyor, sessiz ev bekliyor.',
      'Pencere neden açıktı? Sessiz evde kim vardı?',
    ]) {
      test('rejected closing fails closed: $bad', () async {
        await expectLater(
          _closing(bad),
          throwsA(isA<AiRequestException>().having(
            (e) => e.failure.kind,
            'kind',
            AiFailureKind.invalidResponse,
          )),
        );
      });
    }
  });
}
