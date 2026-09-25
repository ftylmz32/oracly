/// Phase 6F.1 — explicit max-two Narrative provider attempt budget.
/// REAL PROVIDER CALLS = 0.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/ai/production/ai_failure.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/tarot/interpretation/models/interpretation_error.dart';
import 'package:oracly_new/features/tarot/narrative/live/narrative_tarot_attempt.dart';
import 'package:oracly_new/features/tarot/narrative/live/narrative_tarot_live_interpreter.dart';
import 'package:oracly_new/features/tarot/services/tarot_interpretation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../narrative_history/tarot_4c_test_support.dart';
import 'phase6f_live_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Phase4cHarness harness;
  late CountingInterpretationCache cache;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    harness = Phase4cHarness(LocalStorage(await SharedPreferences.getInstance()));
    cache = CountingInterpretationCache();
  });

  TarotInterpretationService service(ScriptedNarrativeAi ai) =>
      TarotInterpretationService(
        narrativeInterpreter: NarrativeTarotLiveInterpreter(
          ai: ai,
          historyLoader: harness.loader(),
          cache: cache,
          clock: () => DateTime.utc(2026, 9, 24, 19),
        ),
        allowLocalFallback: false,
      );

  test('MAX_NARRATIVE_PROVIDER_ATTEMPTS is 2', () {
    expect(kMaxNarrativeProviderAttempts, 2);
  });

  test('attempt1 fail + attempt2 fail → exactly 2 Narrative AI calls', () async {
    final ai = ScriptedNarrativeAi([
      AiOutcome.failure(AiFailure.providerError()),
      AiOutcome.failure(AiFailure.providerError()),
      AiOutcome.failure(AiFailure.providerError()),
    ]);
    await expectLater(
      service(ai).generateContent(singleFoolSession(), language: 'en'),
      throwsA(isA<InterpretationException>()),
    );
    expect(ai.callCount, 2);
    expect(ai.attempts, [1, 2]);
    expect(cache.writes, isEmpty);
  });

  test('attempt1 quality fail + attempt2 throw → exactly 2 calls', () async {
    final ai = ScriptedNarrativeAi([
      AiOutcome.success(qualityFailStructured()),
      AiOutcome.failure(AiFailure.providerError()),
      AiOutcome.success(cloneSolStructured()),
    ]);
    await expectLater(
      service(ai).generateContent(singleFoolSession(), language: 'en'),
      throwsA(isA<InterpretationException>()),
    );
    expect(ai.callCount, 2);
    expect(ai.attempts, [1, 2]);
    expect(cache.writes, isEmpty);
  });

  test('invalid attempt fails closed before provider', () async {
    final ai = ScriptedNarrativeAi([
      AiOutcome.success(cloneSolStructured()),
    ]);
    final live = NarrativeTarotLiveInterpreter(
      ai: ai,
      historyLoader: harness.loader(),
      cache: cache,
      clock: () => DateTime.utc(2026, 9, 24, 19),
    );
    await expectLater(
      live.interpret(
        session: singleFoolSession(),
        languageCode: 'en',
        attempt: 3,
      ),
      throwsA(isA<ArgumentError>()),
    );
    expect(ai.callCount, 0);
  });

  test('non-retryable missing interpreter never enters quality budget',
      () async {
    final svc = TarotInterpretationService(allowLocalFallback: false);
    await expectLater(
      svc.generateContent(singleFoolSession(), language: 'en'),
      throwsA(
        isA<InterpretationException>().having(
          (e) => e.retryable,
          'retryable',
          isFalse,
        ),
      ),
    );
  });
}
