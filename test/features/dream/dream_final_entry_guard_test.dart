/// Dream final audit §3/§22/§24 — write-flow guards and basic accessibility
/// on the real screen: too short, double tap, cancelled entry, tap targets.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/ai/production/ai_failure.dart';
import 'package:oracly_new/features/dream/copy/dream_copy.dart';
import 'package:oracly_new/features/dream/presentation/reference/dream_reference_error_view.dart';
import 'package:oracly_new/features/dream/presentation/reference/dream_reference_result_view.dart';
import 'package:oracly_new/features/dream/services/dream_attempt_store.dart';

import 'dream_final_audit_support.dart';
import 'dream_phase1_support.dart';

void main() {
  Future<DreamPhase1Env> open(WidgetTester tester, [FinalAuditAi? ai]) async {
    final env = (await tester.runAsync(
      () => DreamPhase1Env.open(ai: ai ?? FinalAuditAi()),
    ))!;
    await pumpDreamApp(tester, env);
    await openDreamRoute(tester);
    return env;
  }

  testWidgets('too short: calm hint, no attempt, no provider, no save',
      (tester) async {
    final env = await open(tester);
    await writeAndSubmit(tester, 'kısa rüya');
    expect(find.text(DreamCopy.narrativeTooShort), findsOneWidget);
    expect(env.ai.calls, 0);
    expect(env.storage.getString(DreamAttemptStore.key), isNull);
    expect(env.recordCount, 0);
    expect(find.byType(TextField), findsOneWidget, reason: 'input retained');
    expect(find.text('kısa rüya'), findsOneWidget);
  });

  testWidgets('double tap on submit starts exactly one analysis',
      (tester) async {
    final env = await open(tester);
    await tester.tap(find.text(DreamCopy.writeDream));
    await settle(tester, 4);
    await tester.enterText(find.byType(TextField).first, phase1NarrativeA);
    final submit = find.text(DreamCopy.submitCta);
    await tester.ensureVisible(submit);
    await settle(tester, 4);
    WidgetController.hitTestWarningShouldBeFatal = true;
    addTearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);
    await tester.tap(submit);
    await tester.tap(submit);
    await settle(tester);

    expect(find.byType(DreamReferenceResultView), findsOneWidget);
    expect(env.ai.calls, 1);
    expect(env.recordCount, 1);
  });

  testWidgets('a typed but unsent Dream is never saved', (tester) async {
    final env = await open(tester);
    await tester.tap(find.text(DreamCopy.writeDream));
    await settle(tester, 4);
    await tester.enterText(find.byType(TextField).first, phase1NarrativeA);
    await popDreamRoute(tester);
    await openDreamRoute(tester);

    expect(env.ai.calls, 0);
    expect(env.recordCount, 0);
    expect(env.storage.getString(DreamAttemptStore.key), isNull);
  });

  testWidgets('hub meets the 44pt tap-target guideline; every state is labelled',
      (tester) async {
    final semantics = tester.ensureSemantics();
    final ai = FinalAuditAi()..failures.add(AiFailure.network());
    await open(tester, ai);
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

    await writeAndSubmit(tester, phase1NarrativeA);
    expect(find.byType(DreamReferenceErrorView), findsOneWidget);
    // Target size here belongs to the shared OraclyErrorState button (known
    // limitation in the audit doc); Dream only owns that it is labelled.
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

    await tapText(tester, DreamCopy.retry);
    expect(find.byType(DreamReferenceResultView), findsOneWidget);
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    semantics.dispose();
  });
}
