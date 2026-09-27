/// Dream Phase 2 — cross-language contract: the reading follows the
/// narrative's language (app language only when it cannot be identified).
/// Synthetic narratives and scripted replies; zero provider calls.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/ai/production/models/dream_ai_analysis.dart';
import 'package:oracly_new/features/ai/production/openai/openai_paid_requests.dart';
import 'package:oracly_new/features/dream/copy/dream_copy.dart';
import 'package:oracly_new/features/dream/models/dream_provenance.dart';
import 'package:oracly_new/features/dream/services/dream_experience_service.dart';
import 'package:oracly_new/features/dream/services/dream_narrative_language.dart';
import 'package:oracly_new/features/dream/services/dream_reading_provenance.dart';

import '../../support/dream_test_owner.dart';
import 'dream_honesty_fakes.dart';
import 'dream_phase2_support.dart';

const _enTold =
    'I was walking along a quiet beach at night and a door stood in the sand.';
const _ruTold =
    'Мне снилось, что я шла по тихому лесу, а за деревьями светилось окно старого дома.';

const _enReply = DreamAiAnalysis(
  summary:
      'The door standing in the sand turns the quiet beach into a threshold you can approach slowly.',
  symbols: ['The door in the sand', 'The quiet beach at night'],
  emotionalTheme:
      'Walking the quiet beach at night carries a calm, curious attention toward the door.',
  interpretation:
      'The door standing in the sand may mark a quiet threshold you are slowly approaching on the beach.',
  dailyLifeReflection:
      'Today you might notice a quiet moment, like that beach at night, before opening a new door.',
  conclusion: 'What would you hope to find behind the door in the sand?',
);

const _ruReply = DreamAiAnalysis(
  summary:
      'Светящееся окно за деревьями делает тихий лес дорогой к чему-то знакомому и тёплому.',
  symbols: ['Светящееся окно старого дома', 'Тихий лес за деревьями'],
  emotionalTheme:
      'Окно старого дома за деревьями дарит спокойное, тёплое ожидание в тишине.',
  interpretation:
      'Окно старого дома, светящееся за деревьями, может говорить о тихом желании вернуться к знакомому.',
  dailyLifeReflection:
      'Сегодня можно найти минуту тишины и вспомнить окно старого дома за деревьями.',
  conclusion: 'Что ты хотела бы увидеть в окне старого дома?',
);

Future<(DreamExperienceResult, ScriptedDreamAi)> _run(
  String narrative,
  DreamAiAnalysis reply, {
  required String app,
}) async {
  OraclyL10n.bind(app);
  final ai = ScriptedDreamAi(reply);
  final result = await DreamExperienceService(
    repository: MemDreamRepository(),
    owner: testDreamOwner(),
    ai: ai,
  ).analyze(narrative: narrative);
  return (result, ai);
}

void _expectOperation(
  DreamExperienceResult result,
  ScriptedDreamAi ai,
  String language,
) {
  final context = ai.contexts.single;
  expect(context.language, language);
  expect(
    OpenAiPaidRequests.dream(model: 'm', context: context).payload['language'],
    language,
  );
  for (final insight in result.dream.insights) {
    expect(insight.title, DreamCopy.sectionTitle(insight.kind, language));
  }
}

void main() {
  tearDown(() => OraclyL10n.bind('tr'));

  final cases = {
    'TR narrative + EN app': (phase2Narrative, 'en', 'tr', phase2AllAccepted),
    'EN narrative + TR app': (_enTold, 'tr', 'en', _enReply),
    'RU narrative + EN app': (_ruTold, 'en', 'ru', _ruReply),
  };

  for (final MapEntry(key: name, value: c) in cases.entries) {
    final (told, app, operation, reply) = c;

    test('$name: operation $operation, grounded reply accepted as AI',
        () async {
      final (result, ai) = await _run(told, reply, app: app);
      _expectOperation(result, ai, operation);
      expect(DreamReadingProvenance.of(result.dream), DreamProvenance.aiOnly);
    });

    // Phase 4B: unrelated prose is an invalid response in the operation
    // language — never a locally completed reading.
    test('$name: unrelated prose fails closed after one call', () async {
      final ai = ScriptedDreamAi(phase2AllRejected);
      OraclyL10n.bind(app);
      final repo = MemDreamRepository();
      await expectLater(
        DreamExperienceService(repository: repo, owner: testDreamOwner(), ai: ai)
            .analyze(narrative: told),
        throwsInvalidDreamResponse,
      );
      expect(ai.contexts.single.language, operation);
      expect(await repo.getAll(), isEmpty);
    });
  }

  test('invented image fails closed in a cross-language operation', () async {
    final invented = DreamAiAnalysis(
      summary: _enReply.summary,
      symbols: _enReply.symbols,
      emotionalTheme: _enReply.emotionalTheme,
      interpretation:
          'A snake coiled by the door in the sand may mark the quiet beach as a threshold.',
      dailyLifeReflection: _enReply.dailyLifeReflection,
      conclusion: _enReply.conclusion,
    );
    await expectLater(
      _run(_enTold, invented, app: 'tr'),
      throwsInvalidDreamResponse,
    );
  });

  group('narrative language detection', () {
    test('identifies TR / EN / RU deterministically', () {
      expect(DreamNarrativeLanguage.detect(phase2Narrative), 'tr');
      expect(DreamNarrativeLanguage.detect(_enTold), 'en');
      expect(DreamNarrativeLanguage.detect(_ruTold), 'ru');
    });

    test('unknown or close call falls back to the app language', () {
      for (final told in ['Mira, Leo, lantern, fener.', '12:30 …', '']) {
        expect(DreamNarrativeLanguage.detect(told), isNull);
        expect(DreamNarrativeLanguage.forOperation(told, 'en'), 'en');
        expect(DreamNarrativeLanguage.forOperation(told, 'xx'), 'tr');
      }
    });
  });
}
