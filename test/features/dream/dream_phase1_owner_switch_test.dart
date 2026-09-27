/// Dream Phase 1 — Tests A/B: controller never carries owner A into owner B.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/auth/sign_out_local_cleanup.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:oracly_new/features/ai/production/oracly_ai_providers.dart';
import 'package:oracly_new/features/dream/controllers/dream_analysis_controller.dart';
import 'package:oracly_new/features/dream/providers/dream_providers.dart';
import 'package:oracly_new/features/dream/services/dream_owner_guard.dart';

import 'dream_phase1_support.dart';

Future<void> _settle() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DreamPhase1Env env;
  late ProviderContainer container;

  setUp(() async {
    env = await DreamPhase1Env.open();
    await env.service().analyze(narrative: phase1NarrativeA);
    env.ai.calls = 0;
    env.ai.narratives.clear();
    container = ProviderContainer(
      overrides: [
        localStorageProvider.overrideWithValue(env.storage),
        oraclyAiServiceProvider.overrideWithValue(env.ai),
      ],
    );
  });

  tearDown(() => container.dispose());

  Future<DreamAnalysisController> ownerAResultOpen() async {
    final controller = container.read(dreamAnalysisControllerProvider);
    await controller.loadHistory();
    expect(controller.history, hasLength(1));
    await controller.openSaved(controller.history.single);
    expect(controller.phase, DreamJourneyPhase.complete);
    return controller;
  }

  void expectSafeEntry(DreamAnalysisController controller) {
    expect(controller.phase, DreamJourneyPhase.entry);
    expect(controller.dream, isNull);
    expect(controller.history, isEmpty);
  }

  test('A: account switch A→B rebuilds the controller with B-only history',
      () async {
    final a = await ownerAResultOpen();

    await env.switchTo('owner-b');
    final b = container.read(dreamAnalysisControllerProvider);
    await b.loadHistory();

    expect(identical(a, b), isFalse);
    expectSafeEntry(b);
    // The disposed A controller cannot be revived to show A's result.
    final staleDream = a.dream!;
    await a.openSaved(staleDream);
    expect(container.read(dreamAnalysisControllerProvider).dream, isNull);
  });

  test('A: sign-out (epoch bump, owner removed) also drops A state', () async {
    final a = await ownerAResultOpen();

    await SignOutLocalCleanup.wipeDiskOnly(
      storage: env.storage,
      secureStorage: InMemorySecureStorage(),
    );
    final next = container.read(dreamAnalysisControllerProvider);
    await next.loadHistory();

    expect(identical(a, next), isFalse);
    expectSafeEntry(next);
  });

  test('B: stale A dream handed to B controller is dropped, never shown',
      () async {
    final a = await ownerAResultOpen();
    final staleA = a.dream!;

    await env.switchTo('owner-b');
    final before = env.persistedDreamState();
    final b = container.read(dreamAnalysisControllerProvider);
    final opening = b.openSaved(staleA);
    expect(b.dream, isNull);
    await opening;
    await _settle();

    expectSafeEntry(b);
    expect(env.ai.calls, 0);
    expect(env.persistedDreamState(), before);
  });

  test('B: reinterpreting a stale A dream under B never reaches the provider',
      () async {
    final a = await ownerAResultOpen();
    final staleA = a.dream!;

    await env.switchTo('owner-b');
    final before = env.persistedDreamState();

    await expectLater(
      env.service().reinterpret(staleA),
      throwsA(isA<DreamOwnerChangedException>()),
    );

    final b = container.read(dreamAnalysisControllerProvider);
    await b.openSaved(staleA);
    await expectLater(b.reinterpret(), throwsStateError);
    await _settle();

    expect(env.ai.calls, 0);
    expect(env.recordCount, 0);
    expect(env.dreamMemoryCount, 0);
    expect(env.versionsRaw, isNull);
    expect(env.persistedDreamState(), before);
    expectSafeEntry(b);
  });

  test('same-owner reinterpret still works from stored content', () async {
    final a = await ownerAResultOpen();
    await a.reinterpret();

    expect(env.ai.calls, 1);
    expect(env.ai.narratives.single, contains('penceresinden'));
    expect(a.phase, DreamJourneyPhase.complete);
    expect(env.recordCount, 1);
  });
}
