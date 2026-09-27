/// Dream Phase 2 — TR / EN / RU grounding, language snapshot, disclosure copy.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/ai/oracle_conversation/models/oracle_reading_context_sources.dart';
import 'package:oracly_new/features/ai/production/contexts/reading_ai_context.dart';
import 'package:oracly_new/features/ai/production/openai/openai_paid_requests.dart';
import 'package:oracly_new/features/dream/copy/dream_copy.dart';
import 'package:oracly_new/features/dream/models/dream_provenance.dart';
import 'package:oracly_new/features/dream/services/dream_analysis_facts.dart';
import 'package:oracly_new/features/dream/services/dream_analysis_guard.dart';
import 'package:oracly_new/features/dream/services/dream_experience_service.dart';
import 'package:oracly_new/features/dream/services/dream_grounding_words.dart';
import 'package:oracly_new/features/dream/services/dream_reading_provenance.dart';

import '../../support/dream_test_owner.dart';
import 'dream_honesty_fakes.dart';
import 'dream_phase2_support.dart';

DreamAnalysisFacts _facts(String told, String language) =>
    DreamAnalysisFacts(told: told, scene: told, language: language);

const _enTold =
    'I was walking along a quiet beach at night and a door stood in the sand.';
const _ruTold =
    'Мне снилось, что я шла по тихому лесу, а за деревьями светилось окно старого дома.';

void main() {
  tearDown(() => OraclyL10n.bind('tr'));

  group('grounding', () {
    test('TR: grounded prose accepted, unrelated prose rejected', () {
      final facts = _facts(phase2Narrative, 'tr');
      expect(DreamAnalysisGuard.polish(LiveDreamAiStub.interpretation, facts),
          isNotNull);
      expect(DreamAnalysisGuard.polish(phase2AllRejected.interpretation, facts),
          isNull);
    });

    test('EN: grounded prose accepted, unrelated prose rejected', () {
      final facts = _facts(_enTold, 'en');
      expect(
        DreamAnalysisGuard.polish(
          'The door standing in the sand turns the quiet beach into a threshold you can approach slowly.',
          facts,
        ),
        isNotNull,
      );
      expect(
        DreamAnalysisGuard.polish(
          'A lighthouse guides a distant vessel across the harbour after a long voyage home.',
          facts,
        ),
        isNull,
      );
    });

    test('EN: catalogue words match whole words, not substrings', () {
      final facts = _facts(_enTold, 'en');
      expect(
        DreamAnalysisGuard.polish(
          'The quiet beach appeared calmer once the door in the sand was noticed.',
          facts,
        ),
        isNotNull,
      );
      expect(
        DreamAnalysisGuard.polish(
          'A soft glow over the door in the sand makes the quiet beach feel close.',
          facts,
        ),
        isNotNull,
      );
      expect(
        DreamAnalysisGuard.polish(
          'A red glow over the door in the sand makes the quiet beach feel close.',
          facts,
        ),
        isNull,
      );
    });

    test('RU: grounded prose accepted, unrelated prose rejected', () {
      final facts = _facts(_ruTold, 'ru');
      expect(
        DreamAnalysisGuard.polish(
          'Светящееся окно за деревьями делает тихий лес дорогой к чему-то знакомому и тёплому.',
          facts,
        ),
        isNotNull,
      );
      expect(
        DreamAnalysisGuard.polish(
          'Маяк на берегу моря освещает путь далёкому кораблю среди тёмных волн.',
          facts,
        ),
        isNull,
      );
    });

    test('Cyrillic tokenizer folds ё and drops connectors', () {
      final words = DreamGroundingWords.significant('Ёлка у тёмного озера, это было');
      expect(words, containsAll(['елка', 'темного', 'озера']));
      expect(words, isNot(contains('было')));
      expect(DreamGroundingWords.significant('Мне снилось, что сон'), isNot(contains('снов')));
    });
  });

  group('language snapshot', () {
    test('locale change mid-flight never reaches request, guard or titles', () async {
      OraclyL10n.bind('tr');
      final ai = ScriptedDreamAi(
        phase2AllAccepted,
        midFlight: () => OraclyL10n.bind('en'),
      );
      final result = await DreamExperienceService(
        repository: MemDreamRepository(),
        owner: testDreamOwner(),
        ai: ai,
      ).analyze(narrative: phase2Narrative);
      expect(OraclyL10n.code, 'en');
      expect(ai.contexts.single.language, 'tr');
      for (final insight in result.dream.insights) {
        expect(insight.title, DreamCopy.sectionTitle(insight.kind, 'tr'));
      }
      expect(
        DreamReadingProvenance.of(result.dream),
        DreamProvenance.aiOnly,
      );
      final request = OpenAiPaidRequests.dream(
        model: 'm',
        context: ai.contexts.single,
      );
      expect(request.payload['language'], 'tr');
    });

    test('request language comes from the context; fingerprint unchanged', () {
      OraclyL10n.bind('tr');
      const ru = DreamAiContext(narrative: _ruTold, language: 'ru');
      const en = DreamAiContext(narrative: _ruTold, language: 'en');
      const unset = DreamAiContext(narrative: _ruTold);
      final ruReq = OpenAiPaidRequests.dream(model: 'm', context: ru);
      final enReq = OpenAiPaidRequests.dream(model: 'm', context: en);
      expect(ruReq.payload['language'], 'ru');
      expect(enReq.payload['language'], 'en');
      expect(
        OpenAiPaidRequests.dream(model: 'm', context: unset).payload['language'],
        'tr',
      );
      expect(ruReq.idempotencyKey, enReq.idempotencyKey);
    });
  });

  group('disclosure', () {
    test('footnote is localized and never exposes enum names', () {
      for (final code in ['tr', 'en', 'ru']) {
        OraclyL10n.bind(code);
        final notes = {
          for (final p in DreamProvenance.values) p: DreamCopy.readingFootnote(p),
        };
        expect(notes.values.toSet(), hasLength(DreamProvenance.values.length));
        for (final entry in notes.entries) {
          expect(entry.value, isNot(contains(entry.key.name)));
          expect(entry.value, isNot(contains('dream.')));
        }
      }
    });

    test('OR context carries no provenance enum names', () {
      final context = OracleReadingContextSources.dream(
        id: 'd1',
        narrative: phase2Narrative,
        analysis: LiveDreamAiStub.interpretation,
      );
      for (final name in ['legacyUnknown', 'aiOnly', 'localOnly', 'DreamInsightSource']) {
        expect(context.fullInterpretation, isNot(contains(name)));
      }
    });
  });
}
