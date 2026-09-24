/// Phase 6F — billing boundary: a paid Narrative call is cached exactly once
/// and a failed call is never cached. REAL PROVIDER CALLS = 0.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/ai/production/ai_failure.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/tarot/interpretation/models/interpretation_error.dart';
import 'package:oracly_new/features/tarot/narrative/live/narrative_tarot_live_interpreter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../narrative_history/tarot_4c_test_support.dart';
import 'phase6f_live_support.dart';

AiOutcome<Map<String, dynamic>> _success() {
  final call = solCalls().first;
  return AiOutcome.success(
    Map<String, dynamic>.from(call['structuredResult'] as Map),
  );
}

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

  test('provider failure never writes the cache', () async {
    final ai = ScriptedNarrativeAi([_failure()]);
    await expectLater(
      interpreter(ai).interpret(
        session: singleFoolSession(),
        languageCode: 'en',
      ),
      throwsA(isA<InterpretationException>()),
    );
    expect(ai.callCount, 1);
    expect(cache.writes, isEmpty);
  });

  test('valid success writes the cache exactly once', () async {
    final ai = ScriptedNarrativeAi([_success()]);
    final result = await interpreter(ai).interpret(
      session: singleFoolSession(),
      languageCode: 'en',
    );
    expect(result.summary, isNotEmpty);
    expect(ai.callCount, 1);
    expect(cache.writes, hasLength(1));
    expect(cache.writes.single, ai.fingerprints.single);
  });

  test('cache hit serves the second read without a second provider call',
      () async {
    final ai = ScriptedNarrativeAi([_success()]);
    final live = interpreter(ai);
    final session = singleFoolSession();

    final first = await live.interpret(session: session, languageCode: 'en');
    final second = await live.interpret(session: session, languageCode: 'en');

    expect(ai.callCount, 1);
    expect(cache.writes, hasLength(1));
    expect(second.summary, first.summary);
  });

  test('forceRefresh bypasses the cache and re-bills once', () async {
    final ai = ScriptedNarrativeAi([_success(), _success()]);
    final live = interpreter(ai);
    final session = singleFoolSession();

    await live.interpret(session: session, languageCode: 'en');
    final readsAfterFirst = cache.reads;
    await live.interpret(
      session: session,
      languageCode: 'en',
      forceRefresh: true,
    );

    expect(ai.callCount, 2);
    expect(cache.reads, readsAfterFirst, reason: 'forceRefresh skips get()');
    expect(cache.writes, hasLength(2));
    expect(cache.writes.toSet(), hasLength(1));
  });

  test('wire payload carries no session, reading or owner identifiers',
      () async {
    final ai = ScriptedNarrativeAi([_success()]);
    await interpreter(ai).interpret(
      session: singleFoolSession(id: 'sess_billing_secret'),
      languageCode: 'en',
    );
    final encoded = ai.payloads.single.toString();
    expect(encoded, isNot(contains('sess_billing_secret')));
    expect(encoded, isNot(contains('sessionId')));
    expect(encoded, isNot(contains('readingId')));
    expect(encoded, isNot(contains('ownerId')));
  });
}
