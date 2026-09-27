/// Dream Phase 1 — Tests E/F: discovery clear + account wipe leave no Dream.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/user_local_data_wipe.dart';
import 'package:oracly_new/core/data/repositories/mock_history_repository.dart';
import 'package:oracly_new/core/reading_version/models/reading_version_kind.dart';
import 'package:oracly_new/core/reading_version/services/reading_version_store.dart';
import 'package:oracly_new/core/services/history_service.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:oracly_new/features/ai/production/oracly_ai_providers.dart';
import 'package:oracly_new/features/dream/controllers/dream_analysis_controller.dart';
import 'package:oracly_new/features/dream/providers/dream_providers.dart';
import 'package:oracly_new/features/dream/services/dream_attempt_store.dart';
import 'package:oracly_new/features/dream/services/dream_owner_guard.dart';
import 'package:oracly_new/features/privacy/services/privacy_data_refresh.dart';
import 'package:oracly_new/features/privacy/services/privacy_discovery_clear.dart';
import 'package:oracly_new/features/privacy/services/privacy_dream_clear.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/false_return_local_storage.dart';
import '../../test_helpers/provider_scope_harness.dart';
import '../birth_chart/evidence/test_birth_owner.dart';
import 'dream_phase1_support.dart';

Future<void> _seedDreamState(DreamPhase1Env env) async {
  await env.service().analyze(narrative: phase1NarrativeA);
  await Future<void>.delayed(const Duration(milliseconds: 3));
  await env.service().analyze(narrative: phase1NarrativeA2);
  await env.versions.seedOriginal(
    rootId: 'coffee_keep',
    kind: ReadingVersionKind.coffee,
    data: const {'overall': 'coffee chain survives'},
  );
  await env.versions.seedOriginal(
    rootId: 'tarot_keep',
    kind: ReadingVersionKind.tarot,
    data: const {'overall': 'tarot chain survives'},
  );
  await DreamAttemptStore(env.storage).resolveId(phase1NarrativeA);
  expect(env.recordCount, 2);
  expect(env.dreamMemoryCount, 2);
  expect(env.versionsRaw, contains(phase1NarrativeA));
}

void _expectNoDreamState(DreamPhase1Env env) {
  expect(env.recordCount, 0);
  expect(env.dreamMemoryCount, 0);
  expect(env.versionsRaw ?? '', isNot(contains('"kind":"dream"')));
  expect(env.versionsRaw ?? '', isNot(contains(phase1NarrativeA)));
  expect(env.storage.getString(DreamAttemptStore.key), isNull);
}

void main() {
  testWidgets('E: discovery clear removes all Dream state and refreshes the '
      'controller without restart', (tester) async {
    late DreamPhase1Env env;
    await tester.runAsync(() async {
      env = await DreamPhase1Env.open();
      await _seedDreamState(env);
    });

    late WidgetRef ref;
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: env.storage,
        overrides: [oraclyAiServiceProvider.overrideWithValue(env.ai)],
        child: MaterialApp(
          home: Consumer(
            builder: (context, r, _) {
              ref = r;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    final before = ref.read(dreamAnalysisControllerProvider);
    await tester.runAsync(before.loadHistory);
    expect(before.history, hasLength(2));
    before.openSaved(before.history.first);
    await tester.pump();

    await tester.runAsync(
      () => PrivacyDiscoveryClear.run(
        storage: env.storage,
        history: HistoryService(MockHistoryRepository(env.storage)),
        birthCharts: testBirthChartRepo(env.storage, ownerId: 'owner-a'),
      ),
    );
    PrivacyDataRefresh.afterDiscoveryHistoryClear(ref);
    final after = ref.read(dreamAnalysisControllerProvider);
    await tester.runAsync(after.loadHistory);

    _expectNoDreamState(env);
    final store = ReadingVersionStore(env.storage);
    expect(store.byRootId('coffee_keep'), isNotNull);
    expect(store.byRootId('tarot_keep'), isNotNull);
    expect(identical(before, after), isFalse);
    expect(after.history, isEmpty);
    expect(after.dream, isNull);
    expect(after.phase, DreamJourneyPhase.entry);
  });

  test('E: an analysis in flight during a Dream clear cannot re-persist',
      () async {
    final env = await DreamPhase1Env.open(ai: HeldDreamAi(hold: true));
    final pending = env.service().analyze(narrative: phase1NarrativeA);
    await env.ai.entered;

    expect(await PrivacyDreamClear.run(env.storage, env.memory), isTrue);
    env.ai.release();

    await expectLater(pending, throwsA(isA<DreamOwnerChangedException>()));
    _expectNoDreamState(env);
  });

  test('E: clear never reports success while the attempt row survives',
      () async {
    SharedPreferences.setMockInitialValues({});
    final storage = FalseReturnLocalStorage(
      await SharedPreferences.getInstance(),
    );
    await DreamAttemptStore(storage).resolveId(phase1NarrativeA);
    storage.falseReturnRemoveKeys.add(DreamAttemptStore.key);

    await expectLater(
      PrivacyDiscoveryClear.run(
        storage: storage,
        history: HistoryService(MockHistoryRepository(storage)),
        birthCharts: testBirthChartRepo(storage, ownerId: 'owner-a'),
      ),
      throwsStateError,
    );
    expect(storage.getStringList('dream_records') ?? const [], isEmpty);
  });

  test('F: canonical account wipe removes every Dream store', () async {
    final env = await DreamPhase1Env.open();
    await _seedDreamState(env);

    final result = await UserLocalDataWipe.run(
      env.storage,
      secureStorage: InMemorySecureStorage(),
    );

    expect(result.isComplete, isTrue);
    expect(env.recordCount, 0);
    expect(env.dreamMemoryCount, 0);
    expect(env.versionsRaw, isNull);
    expect(env.storage.getString(DreamAttemptStore.key), isNull);
  });
}
