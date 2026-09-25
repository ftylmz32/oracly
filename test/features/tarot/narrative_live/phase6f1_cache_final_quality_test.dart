/// Phase 6F.1 — cache commits only after Reflective + AiOutputQuality.
/// REAL PROVIDER CALLS = 0.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/reading/ai_output_quality_tarot.dart';
import 'package:oracly_new/features/ai/production/ai_failure.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/insights/services/reflective_intelligence.dart';
import 'package:oracly_new/features/tarot/interpretation/models/interpretation_error.dart';
import 'package:oracly_new/features/tarot/interpretation/models/interpretation_result.dart';
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

  test('structural PASS + AiOutputQuality FAIL → cache writes = 0', () async {
    final ai = ScriptedNarrativeAi([
      AiOutcome.success(qualityFailStructured()),
      AiOutcome.success(qualityFailStructured()),
    ]);
    await expectLater(
      service(ai).generateContent(singleFoolSession(), language: 'en'),
      throwsA(isA<InterpretationException>()),
    );
    expect(ai.callCount, 2);
    expect(ai.attempts, [1, 2]);
    expect(cache.writes, isEmpty);
  });

  test('Reflective-guarded invalid final result → cache writes = 0', () async {
    final bad = cloneSolStructured();
    bad['summary'] = 'I am a real human. ${bad['summary']}';
    final ai = ScriptedNarrativeAi([
      AiOutcome.success(bad),
      AiOutcome.success(bad),
    ]);
    await expectLater(
      service(ai).generateContent(singleFoolSession(), language: 'en'),
      throwsA(isA<InterpretationException>()),
    );
    expect(cache.writes, isEmpty);
  });

  test('attempt1 low-quality + attempt2 valid → one cache of attempt2', () async {
    final good = cloneSolStructured();
    good['synthesis'] =
        '${good['synthesis']} A second quiet note of presence.';
    final ai = ScriptedNarrativeAi([
      AiOutcome.success(qualityFailStructured()),
      AiOutcome.success(good),
    ]);
    final svc = service(ai);
    final session = singleFoolSession(id: 'sess_6f1_retry');
    final content = await svc.generateContent(session, language: 'en');

    expect(ai.callCount, 2);
    expect(ai.attempts, [1, 2]);
    expect(cache.writes, hasLength(1));
    expect(content.generalMeaning, isNotEmpty);
    expect(
      cache.writtenResults.single.summary,
      isNot(contains('I am a real human')),
    );
    expect(
      AiOutputQualityTarot.passes(cache.writtenResults.single),
      isTrue,
    );
  });

  test('attempt1 valid → cache once, no attempt2', () async {
    final ai = ScriptedNarrativeAi([
      AiOutcome.success(cloneSolStructured()),
    ]);
    await service(ai).generateContent(singleFoolSession(), language: 'en');
    expect(ai.callCount, 1);
    expect(ai.attempts, [1]);
    expect(cache.writes, hasLength(1));
  });

  test('both attempts fail → cache writes = 0', () async {
    final second = qualityFailStructured();
    second['advice'] = 'I am a real human. ${second['advice']}';
    final ai = ScriptedNarrativeAi([
      AiOutcome.success(qualityFailStructured()),
      AiOutcome.success(second),
    ]);
    await expectLater(
      service(ai).generateContent(singleFoolSession(), language: 'en'),
      throwsA(isA<InterpretationException>()),
    );
    expect(ai.callCount, 2);
    expect(cache.writes, isEmpty);
  });

  test('interpreter alone never caches fresh candidate', () async {
    final ai = ScriptedNarrativeAi([
      AiOutcome.success(cloneSolStructured()),
    ]);
    final live = interpreter(ai);
    final candidate = await live.interpret(
      session: singleFoolSession(),
      languageCode: 'en',
      attempt: 1,
    );
    expect(candidate.fromCache, isFalse);
    expect(cache.writes, isEmpty);
    final guarded = ReflectiveIntelligence.guard(candidate.result);
    await live.commitValidated(candidate, guarded);
    expect(cache.writes, hasLength(1));
  });

  test('cache hit after final-quality commit → provider calls = 0', () async {
    final ai = ScriptedNarrativeAi([
      AiOutcome.success(cloneSolStructured()),
    ]);
    final svc = service(ai);
    final session = singleFoolSession(id: 'sess_6f1_hit');
    await svc.generateContent(session, language: 'en');
    expect(ai.callCount, 1);
    await svc.generateContent(session, language: 'en');
    expect(ai.callCount, 1);
    expect(cache.writes, hasLength(1));
  });

  test('bad cache invalidated; fresh path may succeed within budget', () async {
    final session = singleFoolSession(id: 'sess_6f1_badcache');
    // Seed a poisoned cache entry under the real Narrative key.
    final seedAi = ScriptedNarrativeAi([
      AiOutcome.success(cloneSolStructured()),
    ]);
    final seedLive = interpreter(seedAi);
    final ok = await seedLive.interpret(
      session: session,
      languageCode: 'en',
      attempt: 1,
    );
    await cache.set(
      ok.cacheKey,
      InterpretationResult(
        requestId: ok.result.requestId,
        sessionId: ok.result.sessionId,
        summary: 'I am a real human with a medical diagnosis of cancer.',
        love: ok.result.love,
        career: ok.result.career,
        money: ok.result.money,
        health: ok.result.health,
        spiritualGuidance: ok.result.spiritualGuidance,
        advice: ok.result.advice,
        warnings: ok.result.warnings,
        luckyEnergy: ok.result.luckyEnergy,
        dailyFocus: ok.result.dailyFocus,
        closingMessage: ok.result.closingMessage,
        generatedAt: ok.result.generatedAt,
        source: ok.result.source,
        fromCache: true,
      ),
    );
    cache.writes.clear();
    cache.writtenResults.clear();

    final ai = ScriptedNarrativeAi([
      AiOutcome.success(cloneSolStructured()),
    ]);
    final content = await service(ai).generateContent(session, language: 'en');
    expect(content.generalMeaning, isNot(contains('I am a real human')));
    expect(ai.callCount, 1);
    expect(cache.writes, hasLength(1));
    expect(
      AiOutputQualityTarot.passes(cache.writtenResults.last),
      isTrue,
    );
  });

  test('provider failure never writes cache', () async {
    final ai = ScriptedNarrativeAi([
      AiOutcome.failure(AiFailure.providerError()),
    ]);
    await expectLater(
      service(ai).generateContent(singleFoolSession(), language: 'en'),
      throwsA(isA<InterpretationException>()),
    );
    expect(cache.writes, isEmpty);
  });
}
