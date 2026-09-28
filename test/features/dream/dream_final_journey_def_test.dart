/// Dream final audit §25 — journeys D–F through the real screen: privacy
/// clear, local safety guidance, and long multilingual readings.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/ai/production/models/dream_ai_analysis.dart';
import 'package:oracly_new/features/dream/controllers/dream_analysis_controller.dart';
import 'package:oracly_new/features/dream/presentation/reference/dream_reference_entry_hub.dart';
import 'package:oracly_new/features/dream/presentation/reference/dream_reference_result_view.dart';
import 'package:oracly_new/features/dream/presentation/reference/dream_reference_safety_view.dart';
import 'package:oracly_new/features/dream/services/dream_attempt_store.dart';
import 'package:oracly_new/features/privacy/services/privacy_data_refresh.dart';
import 'package:oracly_new/features/privacy/services/privacy_dream_clear.dart';

import 'dream_final_audit_support.dart';
import 'dream_phase1_support.dart';

void main() {
  Future<DreamPhase1Env> open(WidgetTester tester) async {
    final env =
        (await tester.runAsync(() => DreamPhase1Env.open(ai: FinalAuditAi())))!;
    await pumpDreamApp(tester, env);
    await openDreamRoute(tester);
    return env;
  }

  Future<void> clearDreams(WidgetTester tester, DreamPhase1Env env) async {
    final ok = await tester.runAsync(
      () => PrivacyDreamClear.run(env.storage, env.memory),
    );
    expect(ok, isTrue);
    PrivacyDataRefresh.afterDiscoveryHistoryClear(launcherRef);
    await settle(tester, 6);
  }

  testWidgets('D: privacy clear while a result is open leaves nothing',
      (tester) async {
    final env = await open(tester);
    await writeAndSubmit(tester, phase1NarrativeA);
    expect(find.byType(DreamReferenceResultView), findsOneWidget);

    await clearDreams(tester, env);
    expect(find.byType(DreamReferenceResultView), findsNothing);
    expect(find.text(phase1NarrativeA), findsNothing,
        reason: 'a cleared Dream must not come back as a draft');
    expect(find.byType(DreamReferenceEntryHub), findsOneWidget);
    expect(dreamController(tester).history, isEmpty);
    expect(env.recordCount, 0);
    expect(env.dreamMemoryCount, 0);
    expect(env.versionsRaw ?? '', isNot(contains('"kind":"dream"')));

    await writeAndSubmit(tester, phase1NarrativeA2);
    expect(find.byType(DreamReferenceResultView), findsOneWidget,
        reason: 'a new Dream after a clear works normally');
    expect(env.recordCount, 1);
  });

  testWidgets('D: clear after leaving — return shows an empty hub',
      (tester) async {
    final env = await open(tester);
    await writeAndSubmit(tester, phase1NarrativeA);
    await popDreamRoute(tester);
    await clearDreams(tester, env);
    await openDreamRoute(tester);
    expect(find.byType(DreamReferenceEntryHub), findsOneWidget);
    expect(dreamController(tester).history, isEmpty);
    expect(env.recordCount, 0);
  });

  testWidgets('E: safety guidance — no provider, no attempt, no storage',
      (tester) async {
    final env = await open(tester);
    await writeAndSubmit(tester, 'I want to kill myself, I dreamt about it.');
    expect(find.byType(DreamReferenceSafetyView), findsOneWidget);
    expect(env.ai.calls, 0);
    expect(env.storage.getString(DreamAttemptStore.key), isNull);
    expect(env.recordCount, 0);
    expect(env.versionsRaw, isNull);
    expect(dreamController(tester).dream, isNull);
  });

  const longTr = 'Rüyamda uzun bir koridorda yürüyordum, duvarlarda eski '
      'aile fotoğrafları vardı ve her kapının ardından denizin sesi geliyordu. ';
  const longEn = 'In my dream I walked a long corridor lined with old family '
      'photographs, and behind every door I could hear the sea breathing. ';
  const longRu = 'Во сне я шёл по длинному коридору со старыми семейными '
      'фотографиями, и за каждой дверью слышалось дыхание моря. ';

  for (final (lang, base) in [('tr', longTr), ('en', longEn), ('ru', longRu)]) {
    testWidgets('F: long $lang dream reads end to end without overflow',
        (tester) async {
      final env = await open(tester);
      final narrative = (base * 6).trim();
      expect(narrative.length, lessThanOrEqualTo(1000));
      final opening = base.split(',').first;
      String quote(String s) => s
          .replaceAll(narrative, opening)
          .replaceAll(narrative.replaceAll(RegExp(r'\.$'), ''), opening);
      (env.ai as FinalAuditAi).rewrites.add(
            (a) => DreamAiAnalysis(
              summary: quote(a.summary),
              symbols: a.symbols,
              emotionalTheme: quote(a.emotionalTheme),
              interpretation: quote(a.interpretation),
              dailyLifeReflection: quote(a.dailyLifeReflection),
              conclusion: quote(a.conclusion),
            ),
          );
      await writeAndSubmit(tester, narrative);

      expect(find.byType(DreamReferenceResultView), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(dreamController(tester).phase, DreamJourneyPhase.complete);
      expect(env.ai.narratives.single, narrative);
      final stored = (await tester.runAsync(
        () => env.repo.getById(dreamController(tester).dream!.id),
      ))!;
      expect(stored.text, narrative, reason: 'the full text is kept');
      await tester.drag(find.byType(Scrollable).last, const Offset(0, -4000));
      await settle(tester, 4);
      expect(tester.takeException(), isNull);
    });
  }
}
