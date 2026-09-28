/// Dream final audit §2 — leaving Dream after a finished session and coming
/// back opens the hub, never the previous result, error or safety screen.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/ai/production/ai_failure.dart';
import 'package:oracly_new/features/dream/controllers/dream_analysis_controller.dart';
import 'package:oracly_new/features/dream/copy/dream_copy.dart';
import 'package:oracly_new/features/dream/presentation/reference/dream_reference_entry_hub.dart';
import 'package:oracly_new/features/dream/presentation/reference/dream_reference_error_view.dart';
import 'package:oracly_new/features/dream/presentation/reference/dream_reference_result_view.dart';
import 'package:oracly_new/features/dream/presentation/reference/dream_reference_safety_view.dart';

import 'dream_final_audit_support.dart';
import 'dream_phase1_support.dart';

void main() {
  Future<DreamPhase1Env> open(WidgetTester tester, FinalAuditAi ai) async =>
      (await tester.runAsync(() => DreamPhase1Env.open(ai: ai)))!;

  testWidgets('complete → leave → return shows the hub with the saved dream',
      (tester) async {
    final env = await open(tester, FinalAuditAi());
    await pumpDreamApp(tester, env);
    await openDreamRoute(tester);
    await writeAndSubmit(tester, phase1NarrativeA);
    expect(find.byType(DreamReferenceResultView), findsOneWidget);
    expect(env.recordCount, 1);

    await popDreamRoute(tester);
    await openDreamRoute(tester);
    expect(find.byType(DreamReferenceResultView), findsNothing);
    expect(find.byType(DreamReferenceEntryHub), findsOneWidget);
    expect(dreamController(tester).history, hasLength(1));
    expect(env.ai.calls, 1, reason: 're-entry never calls the provider');
    expect(env.recordCount, 1);
  });

  testWidgets('error → leave → return shows the hub, not a dead Retry',
      (tester) async {
    final ai = FinalAuditAi()..failures.add(AiFailure.network());
    final env = await open(tester, ai);
    await pumpDreamApp(tester, env);
    await openDreamRoute(tester);
    await writeAndSubmit(tester, phase1NarrativeA);
    expect(find.byType(DreamReferenceErrorView), findsOneWidget);

    await popDreamRoute(tester);
    await openDreamRoute(tester);
    expect(find.byType(DreamReferenceErrorView), findsNothing);
    expect(find.byType(DreamReferenceEntryHub), findsOneWidget);
    expect(env.recordCount, 0);
  });

  testWidgets('safety → leave → return shows the hub', (tester) async {
    final env = await open(tester, FinalAuditAi());
    await pumpDreamApp(tester, env);
    await openDreamRoute(tester);
    await writeAndSubmit(tester, 'I want to kill myself tonight, I dreamt it.');
    expect(find.byType(DreamReferenceSafetyView), findsOneWidget);
    expect(env.ai.calls, 0);

    await popDreamRoute(tester);
    await openDreamRoute(tester);
    expect(find.byType(DreamReferenceSafetyView), findsNothing);
    expect(find.byType(DreamReferenceEntryHub), findsOneWidget);
  });

  testWidgets('leaving mid-analysis keeps the run; return shows its result',
      (tester) async {
    final ai = FinalAuditAi()..hold = true;
    final env = await open(tester, ai);
    await pumpDreamApp(tester, env);
    await openDreamRoute(tester);
    await writeAndSubmit(tester, phase1NarrativeA);
    expect(dreamController(tester).phase, DreamJourneyPhase.reflecting);

    await popDreamRoute(tester);
    expect(dreamController(tester).phase, DreamJourneyPhase.reflecting);
    ai.release();
    await settle(tester);
    await openDreamRoute(tester);
    expect(find.byType(DreamReferenceResultView), findsOneWidget);
    expect(ai.calls, 1);
    expect(env.recordCount, 1);
  });

  testWidgets('a saved dream opened from outside still shows its reading',
      (tester) async {
    final env = await open(tester, FinalAuditAi());
    final saved = (await tester.runAsync(
      () => env.service().analyze(narrative: phase1NarrativeA),
    ))!;
    await pumpDreamApp(tester, env);
    await openDreamRoute(tester);
    await popDreamRoute(tester);
    await tester.runAsync(() => dreamController(tester).openSaved(saved.dream));
    await openDreamRoute(tester);
    expect(find.byType(DreamReferenceResultView), findsOneWidget);
    expect(find.text(DreamCopy.writeDream), findsNothing);
    expect(env.ai.calls, 1);
  });
}
