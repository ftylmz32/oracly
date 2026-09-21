/// Dream idle entry shows history hub until the user starts composing.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/local_dream_repository.dart';
import 'package:oracly_new/features/ai/production/unconfigured_oracly_ai_service.dart';
import 'package:oracly_new/features/dream/controllers/dream_analysis_controller.dart';
import 'package:oracly_new/features/dream/controllers/dream_voice_controller.dart';
import 'package:oracly_new/features/dream/models/dream.dart';
import 'package:oracly_new/features/dream/presentation/reference/dream_reference_entry_hub.dart';
import 'package:oracly_new/features/dream/presentation/reference/dream_reference_entry_view.dart';
import 'package:oracly_new/features/dream/presentation/reference/dream_reference_session_body.dart';
import 'package:oracly_new/features/dream/services/dream_experience_service.dart';
import 'package:oracly_new/features/dream/services/dream_voice_input_port.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('composing flag selects hub vs write form', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final analysis = DreamAnalysisController(
      DreamExperienceService(
        repository: LocalDreamRepository(storage),
        ai: const UnconfiguredOraclyAiService(),
      ),
    );
    analysis.seedHistoryForTest([
      Dream(
        id: 'd1',
        narrative: 'A quiet hallway of soft light and open doors.',
        recordedAt: DateTime.utc(2026, 9, 1),
      ),
    ]);
    final voice = DreamVoiceController(const UnavailableDreamVoiceInput());
    final narrative = TextEditingController();

    Widget build({required bool composing}) {
      return ProviderScope(
        overrides: [localStorageProvider.overrideWithValue(storage)],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 844,
              child: DreamReferenceSessionBody(
                analysis: analysis,
                voice: voice,
                narrative: narrative,
                selectedChips: const {},
                guidedAnswers: const {},
                composing: composing,
                onChipToggle: (_) {},
                onGuidedChanged: (_, __) {},
                onVoiceTap: () {},
                onCompose: () {},
                onSubmit: () {},
                onEditDream: () {},
                onStopVoice: () {},
                onListenAgain: () {},
                onAnalyzeVoice: () {},
                onVoiceRetry: () {},
                onVoiceBack: () {},
                onNewDream: () {},
                onAnalysisRetry: () {},
                onAnalysisBack: () {},
                onOpenSaved: (_) {},
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(build(composing: false));
    await tester.pump();
    expect(find.byType(DreamReferenceEntryHub), findsOneWidget);
    expect(find.byType(DreamReferenceEntryView), findsNothing);

    await tester.pumpWidget(build(composing: true));
    await tester.pump();
    expect(find.byType(DreamReferenceEntryView), findsOneWidget);
    expect(find.byType(DreamReferenceEntryHub), findsNothing);
  });
}
