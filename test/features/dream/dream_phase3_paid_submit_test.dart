// Dream Phase 3 — DreamPaidSubmit: safety before attempt id, Gem operation,
// binder and provider. Billing providers are sentinels that throw if read,
// so the result cannot depend on balance or on Dream cost.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/features/dream/controllers/dream_analysis_controller.dart';
import 'package:oracly_new/features/dream/models/dream_entry_context.dart';
import 'package:oracly_new/features/dream/models/dream_entry_selection.dart';
import 'package:oracly_new/features/dream/services/dream_attempt_store.dart';
import 'package:oracly_new/features/dream/services/dream_paid_submit.dart';
import 'package:oracly_new/features/gems/providers/gem_providers.dart';

import 'dream_phase1_support.dart';

List<String> _blockedCorpus() {
  final file = File('backend/tests/fixtures/dream_safety/input_corpus.json');
  final rows = (jsonDecode(file.readAsStringSync())['rows'] as List)
      .cast<Map<String, dynamic>>();
  return [
    for (final r in rows)
      if (r['expected'] == 'block') r['text'] as String,
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<(DreamPhase1Env, DreamAnalysisController, WidgetRef, BuildContext,
      List<String>)> host(WidgetTester tester) async {
    final env = (await tester.runAsync(DreamPhase1Env.open))!;
    final touched = <String>[];
    final controller = DreamAnalysisController(
      env.service(),
      organizingDelay: Duration.zero,
    );
    late WidgetRef ref;
    late BuildContext context;
    await tester.pumpWidget(ProviderScope(
      overrides: [
        localStorageProvider.overrideWithValue(env.storage),
        paidAiOperationCoordinatorProvider.overrideWith((_) {
          touched.add('operation');
          throw StateError('billing touched');
        }),
        gemWalletProvider.overrideWith((_) {
          touched.add('wallet');
          throw StateError('wallet touched');
        }),
        analyticsServiceProvider.overrideWith((_) {
          touched.add('analytics');
          throw StateError('analytics touched');
        }),
      ],
      child: MaterialApp(
        home: Consumer(builder: (c, r, _) {
          ref = r;
          context = c;
          return const SizedBox();
        }),
      ),
    ));
    return (env, controller, ref, context, touched);
  }

  testWidgets('every blocked corpus row: safety state, zero side effects',
      (tester) async {
    final (env, controller, ref, context, touched) = await host(tester);
    for (final narrative in _blockedCorpus()) {
      await DreamPaidSubmit.run(
        ref: ref,
        context: context,
        controller: controller,
        narrative: narrative,
        emotions: const [],
        tags: const [],
      );
      expect(controller.phase, DreamJourneyPhase.safety, reason: narrative);
    }
    expect(touched, isEmpty);
    expect(env.storage.getString(DreamAttemptStore.key), isNull);
    expect(env.ai.calls, 0);
    expect(env.persistedDreamState(), '##');
  });

  testWidgets('a crisis guided answer stops a safe narrative too',
      (tester) async {
    final (env, controller, ref, context, touched) = await host(tester);
    await DreamPaidSubmit.run(
      ref: ref,
      context: context,
      controller: controller,
      narrative: 'I walked through a quiet garden toward a closed gate.',
      emotions: const [],
      tags: const ['Nightmare'],
      entry: DreamEntrySelection.of(
        chips: {DreamEntryChipId.nightmare},
        guided: {DreamGuidedQuestionId.values.first: 'I want to kill myself'},
      ),
    );
    expect(controller.phase, DreamJourneyPhase.safety);
    expect(touched, isEmpty);
    expect(env.storage.getString(DreamAttemptStore.key), isNull);
    expect(env.ai.calls, 0);
  });

  testWidgets('positive control: a safe dream reaches billing first',
      (tester) async {
    final (env, controller, ref, context, touched) = await host(tester);
    await expectLater(
      DreamPaidSubmit.run(
        ref: ref,
        context: context,
        controller: controller,
        narrative: 'Rüyamda öldüğümü gördüm, sonra sakin bir bahçede uyandım.',
        emotions: const [],
        tags: const [],
      ),
      throwsStateError,
    );
    expect(touched, isNotEmpty);
    expect(controller.phase, DreamJourneyPhase.entry);
    expect(env.ai.calls, 0);
  });
}
