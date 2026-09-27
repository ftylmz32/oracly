// Dream Phase 3 — dedicated safety view: no reading controls, neutral
// actions, country-neutral TR/EN/RU copy.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/dream/controllers/dream_analysis_controller.dart';
import 'package:oracly_new/features/dream/controllers/dream_voice_controller.dart';
import 'package:oracly_new/features/dream/presentation/reference/dream_reference_result_view.dart';
import 'package:oracly_new/features/dream/presentation/reference/dream_reference_safety_view.dart';
import 'package:oracly_new/features/dream/presentation/reference/dream_reference_session_body.dart';
import 'package:oracly_new/features/dream/presentation/reference/dream_result_summary_card.dart';
import 'package:oracly_new/features/dream/safety/dream_safety_concern.dart';
import 'package:oracly_new/features/dream/services/dream_experience_service.dart';
import 'package:oracly_new/features/dream/services/dream_voice_input_port.dart';

import '../../support/dream_test_owner.dart';
import 'dream_honesty_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('copy: every concern in TR/EN/RU, local emergency wording, no numbers',
      () {
    const emergency = {
      'tr': 'yerel acil yardım hizmetine',
      'en': 'local emergency services',
      'ru': 'местную экстренную помощь',
    };
    for (final lang in emergency.keys) {
      for (final concern in DreamSafetyConcern.values) {
        final title = OraclyL10n.t('dream.safety.${concern.code}.title',
            languageCode: lang);
        final body = OraclyL10n.t('dream.safety.${concern.code}.body',
            languageCode: lang);
        expect(title, isNot(contains('dream.safety')));
        expect(body, isNot(matches(RegExp(r'\d'))), reason: '$lang $concern');
        if (concern == DreamSafetyConcern.crisis ||
            concern == DreamSafetyConcern.acuteDistress) {
          expect(body, contains(emergency[lang]), reason: '$lang $concern');
        }
      }
    }
  });

  testWidgets('safety view replaces the reading; actions stay neutral',
      (tester) async {
    OraclyL10n.bind('en');
    final analysis = DreamAnalysisController(
      DreamExperienceService(
        repository: MemDreamRepository(),
        owner: testDreamOwner(),
        ai: const LiveDreamAiStub(),
      ),
    );
    analysis.presentSafety(
      DreamSafetyConcern.delusion,
      narrative: 'This dream proves aliens are communicating with me.',
    );
    var composed = 0;
    var newDream = 0;
    await tester.pumpWidget(ProviderScope(
      overrides: [
        localStorageProvider.overrideWithValue(LocalStorage.ephemeral()),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: DreamReferenceSessionBody(
            analysis: analysis,
            voice: DreamVoiceController(const UnavailableDreamVoiceInput()),
            narrative: TextEditingController(),
            selectedChips: const {},
            guidedAnswers: const {},
            composing: false,
            onChipToggle: (_) {},
            onGuidedChanged: (_, _) {},
            onVoiceTap: () {},
            onCompose: () => composed++,
            onSubmit: () {},
            onEditDream: () {},
            onStopVoice: () {},
            onListenAgain: () {},
            onAnalyzeVoice: () {},
            onVoiceRetry: () {},
            onVoiceBack: () {},
            onNewDream: () => newDream++,
            onAnalysisRetry: () {},
            onAnalysisBack: () {},
            onOpenSaved: (_) {},
          ),
        ),
      ),
    ));
    await tester.pump();
    expect(find.byType(DreamReferenceSafetyView), findsOneWidget);
    expect(find.byType(DreamReferenceResultView), findsNothing);
    expect(find.byType(DreamResultSummaryCard), findsNothing);
    expect(
      find.text('A dream cannot confirm the outside world'),
      findsOneWidget,
    );
    expect(find.textContaining('outside world.'), findsOneWidget);
    expect(find.textContaining('aliens'), findsNothing);

    await tester.tap(find.text('New dream'));
    expect(newDream, 1);
    await tester.tap(find.text('Back to my words'));
    await tester.pump();
    expect(composed, 1);
    expect(analysis.phase, DreamJourneyPhase.entry);
    expect(analysis.safety, isNull);
  });
}
