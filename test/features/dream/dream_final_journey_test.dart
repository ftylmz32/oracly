/// Dream final audit §25 — journeys A–C through the real screen and
/// provider graph (fake provider, synthetic narratives, canonical storage).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/ai/production/ai_failure.dart';
import 'package:oracly_new/features/dream/controllers/dream_analysis_controller.dart';
import 'package:oracly_new/features/dream/copy/dream_copy.dart';
import 'package:oracly_new/features/dream/presentation/utils/dream_history_labels.dart';
import 'package:oracly_new/features/dream/presentation/reference/dream_reference_entry_hub.dart';
import 'package:oracly_new/features/dream/presentation/reference/dream_reference_error_view.dart';
import 'package:oracly_new/features/dream/presentation/reference/dream_reference_result_view.dart';
import 'package:oracly_new/features/dream/services/dream_attempt_store.dart';

import 'dream_final_audit_support.dart';
import 'dream_phase1_support.dart';

void main() {
  Future<DreamPhase1Env> open(WidgetTester tester, FinalAuditAi ai) async {
    final env = (await tester.runAsync(() => DreamPhase1Env.open(ai: ai)))!;
    await pumpDreamApp(tester, env);
    await openDreamRoute(tester);
    return env;
  }

  testWidgets('A: write → result → leave → reopen saved; one call, one save',
      (tester) async {
    final env = await open(tester, FinalAuditAi());
    expect(find.byType(DreamReferenceEntryHub), findsOneWidget);
    await writeAndSubmit(tester, phase1NarrativeA);

    expect(find.byType(DreamReferenceResultView), findsOneWidget);
    expect(env.recordCount, 1);
    expect(env.dreamMemoryCount, 1);
    final dream = dreamController(tester).dream!;
    expect(env.versionsRaw, contains(dream.id));
    expect(env.storage.getString(DreamAttemptStore.key), isNull,
        reason: 'a completed attempt is released');

    await popDreamRoute(tester);
    await openDreamRoute(tester);
    final title = find.text(DreamHistoryLabels.title(dream));
    expect(title, findsOneWidget);
    await tester.tap(title);
    await settle(tester);

    expect(find.byType(DreamReferenceResultView), findsOneWidget);
    expect(dreamController(tester).dream?.id, dream.id);
    expect(env.ai.calls, 1, reason: 'reopen never calls the provider');
    expect(env.recordCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('B: provider failure keeps the attempt; Retry completes once',
      (tester) async {
    final ai = FinalAuditAi()..failures.add(AiFailure.providerError());
    final env = await open(tester, ai);
    await writeAndSubmit(tester, phase1NarrativeA);

    expect(find.byType(DreamReferenceErrorView), findsOneWidget);
    final attempt = env.storage.getString(DreamAttemptStore.key);
    expect(attempt, isNotNull, reason: 'retry reuses the same attempt');
    expect(env.recordCount, 0);

    await tapText(tester, DreamCopy.retry);
    expect(find.byType(DreamReferenceResultView), findsOneWidget);
    expect(ai.narratives, [phase1NarrativeA, phase1NarrativeA]);
    expect(env.recordCount, 1);
    expect(env.storage.getString(DreamAttemptStore.key), isNull);
  });

  testWidgets('C: owner switch in flight — nothing reaches either owner',
      (tester) async {
    final ai = FinalAuditAi()..hold = true;
    final env = await open(tester, ai);
    await writeAndSubmit(tester, phase1NarrativeA);
    expect(dreamController(tester).phase, DreamJourneyPhase.reflecting);

    await tester.runAsync(() => env.switchTo('owner-b'));
    await settle(tester, 4);
    ai.release();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await settle(tester);

    expect(find.byType(DreamReferenceResultView), findsNothing);
    expect(find.byType(DreamReferenceEntryHub), findsOneWidget);
    expect(dreamController(tester).dream, isNull);
    expect(dreamController(tester).history, isEmpty);
    expect(find.text(phase1NarrativeA), findsNothing,
        reason: 'the prior owner\'s narrative is not left on screen');
    expect(env.recordCount, 0);
    expect(env.dreamMemoryCount, 0);
    expect(find.byType(TextField), findsNothing);
  });
}
