/// Phase 6F — billing boundary: cache only after final quality commit.
/// REAL PROVIDER CALLS = 0.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/ai/production/ai_failure.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/insights/services/reflective_intelligence.dart';
import 'package:oracly_new/features/tarot/interpretation/models/interpretation_error.dart';
import 'package:oracly_new/features/tarot/narrative/live/narrative_tarot_live_interpreter.dart';
import 'package:oracly_new/features/tarot/services/tarot_interpretation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../narrative_history/tarot_4c_test_support.dart';
import 'phase6f_live_support.dart';

AiOutcome<Map<String, dynamic>> _success() =>
    AiOutcome.success(cloneSolStructured());

AiOutcome<Map<String, dynamic>> _failure() =>
    AiOutcome.failure(AiFailure.providerError());

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Phase4cHarness harness;
  late CountingInterpretationCache cache;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    harness = Phase4cHarness(LocalStorage(await SharedPreferences.getInstance()));
    cache = CountingInterpretationCache();
  });

  NarrativeTarotLiveInterpreter interpreter(ScriptedNarrativeAi ai) =>
      NarrativeTarotLiveInterpreter(
        ai: ai,
        historyLoader: harness.loader(),
        cache: cache,
        clock: () => DateTime.utc(2026, 9, 24, 19),
      );

  TarotInterpretationService service(ScriptedNarrativeAi ai) =>
      TarotInterpretationService(
        narrativeInterpreter: interpreter(ai),
        allowLocalFallback: false,
      );

  test('provider failure never writes the cache', () async {
    final ai = ScriptedNarrativeAi([_failure(), _failure()]);
    await expectLater(
      service(ai).generateContent(singleFoolSession(), language: 'en'),
      throwsA(isA<InterpretationException>()),
    );
    expect(ai.callCount, 2);
    expect(cache.writes, isEmpty);
  });

  test('valid success writes the cache exactly once via service', () async {
    final ai = ScriptedNarrativeAi([_success()]);
    final result = await service(ai).generateContent(singleFoolSession(), language: 'en');
    expect(result.generalMeaning, isNotEmpty);
    expect(ai.callCount, 1);
    expect(cache.writes, hasLength(1));
    expect(cache.writes.single, ai.fingerprints.single);
  });

  test('interpreter candidate path does not write before commitValidated',
      () async {
    final ai = ScriptedNarrativeAi([_success()]);
    final live = interpreter(ai);
    final candidate = await live.interpret(
      session: singleFoolSession(),
      languageCode: 'en',
    );
    expect(cache.writes, isEmpty);
    await live.commitValidated(
      candidate,
      ReflectiveIntelligence.guard(candidate.result),
    );
    expect(cache.writes, hasLength(1));
  });

  test('cache hit serves the second read without a second provider call',
      () async {
    final ai = ScriptedNarrativeAi([_success()]);
    final svc = service(ai);
    final session = singleFoolSession();

    final first = await svc.generateContent(session, language: 'en');
    final second = await svc.generateContent(session, language: 'en');

    expect(ai.callCount, 1);
    expect(cache.writes, hasLength(1));
    expect(second.generalMeaning, first.generalMeaning);
  });

  test('forceRefresh bypasses the cache and re-generates once', () async {
    final ai = ScriptedNarrativeAi([_success(), _success()]);
    final svc = service(ai);
    final session = singleFoolSession();

    await svc.generateContent(session, language: 'en');
    final readsAfterFirst = cache.reads;
    await svc.generateContent(session, language: 'en', forceRefresh: true);

    expect(ai.callCount, 2);
    expect(ai.attempts, [1, 1]);
    expect(cache.reads, readsAfterFirst, reason: 'forceRefresh skips get()');
    expect(cache.writes, hasLength(2));
    expect(cache.writes.toSet(), hasLength(1));
  });

  test('wire payload carries no session, reading or owner identifiers',
      () async {
    final ai = ScriptedNarrativeAi([_success()]);
    await service(ai).generateContent(
      singleFoolSession(id: 'sess_billing_secret'),
      language: 'en',
    );
    final encoded = ai.payloads.single.toString();
    expect(encoded, isNot(contains('sess_billing_secret')));
    expect(encoded, isNot(contains('sessionId')));
    expect(encoded, isNot(contains('readingId')));
    expect(encoded, isNot(contains('ownerId')));
  });
}
