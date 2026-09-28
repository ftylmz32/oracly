/// Dream final audit §17 — a failed reinterpret keeps its reading: Retry
/// reinterprets the same Dream, Back returns to it, nothing is duplicated.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/ai/production/ai_failure.dart';
import 'package:oracly_new/features/dream/controllers/dream_analysis_controller.dart';
import 'package:oracly_new/features/dream/copy/dream_copy.dart';
import 'package:oracly_new/features/dream/presentation/reference/dream_reference_error_view.dart';
import 'package:oracly_new/features/dream/presentation/reference/dream_reference_result_view.dart';
import 'package:oracly_new/core/l10n/l10n.dart';

import 'dream_final_audit_support.dart';
import 'dream_phase1_support.dart';

void main() {
  Future<(DreamPhase1Env, String)> reachFailedReinterpret(
    WidgetTester tester,
  ) async {
    final ai = FinalAuditAi();
    final env = (await tester.runAsync(() => DreamPhase1Env.open(ai: ai)))!;
    await pumpDreamApp(tester, env);
    await openDreamRoute(tester);
    await writeAndSubmit(tester, phase1NarrativeA);
    expect(find.byType(DreamReferenceResultView), findsOneWidget);
    final id = dreamController(tester).dream!.id;
    ai.failures.add(AiFailure.timeout());
    await tapText(tester, DreamCopy.resultReinterpret);
    expect(find.byType(DreamReferenceErrorView), findsOneWidget);
    expect(ai.calls, 2);
    return (env, id);
  }

  testWidgets('Retry reinterprets the same Dream — no new record',
      (tester) async {
    final (env, id) = await reachFailedReinterpret(tester);
    await tapText(tester, DreamCopy.retry);

    final controller = dreamController(tester);
    expect(env.ai.calls, 3);
    expect(env.ai.narratives.last, phase1NarrativeA);
    expect(controller.phase, DreamJourneyPhase.complete);
    expect(controller.dream?.id, id);
    expect(env.recordCount, 1, reason: 'a reinterpret never mints a Dream');
    expect(find.text(DreamCopy.narrativeTooShort), findsNothing);
  });

  testWidgets('Back returns to the retained reading, storage untouched',
      (tester) async {
    final (env, id) = await reachFailedReinterpret(tester);
    final before = env.persistedDreamState();
    await tapText(tester, OraclyL10n.t(L10nKeys.back));

    final controller = dreamController(tester);
    expect(controller.phase, DreamJourneyPhase.complete);
    expect(controller.dream?.id, id);
    expect(find.byType(DreamReferenceResultView), findsOneWidget);
    expect(env.persistedDreamState(), before);
    expect(env.ai.calls, 2);
  });

  testWidgets('a failed first analysis still retries the typed narrative',
      (tester) async {
    final ai = FinalAuditAi()..failures.add(AiFailure.rateLimit());
    final env = (await tester.runAsync(() => DreamPhase1Env.open(ai: ai)))!;
    await pumpDreamApp(tester, env);
    await openDreamRoute(tester);
    await writeAndSubmit(tester, phase1NarrativeA);
    expect(find.byType(DreamReferenceErrorView), findsOneWidget);
    await tapText(tester, DreamCopy.retry);

    expect(ai.calls, 2);
    expect(ai.narratives, [phase1NarrativeA, phase1NarrativeA]);
    expect(find.byType(DreamReferenceResultView), findsOneWidget);
    expect(env.recordCount, 1);
  });
}
