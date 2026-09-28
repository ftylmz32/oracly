/// Dream final audit §9/§10 — every failure kind ends in a calm, typed
/// error with nothing stored, and the same narrative then retries cleanly.
/// Partial or unsafe provider bodies are rejected before any write.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/ai/production/ai_failure.dart';
import 'package:oracly_new/features/ai/production/models/dream_ai_analysis.dart';
import 'package:oracly_new/features/dream/controllers/dream_analysis_controller.dart';
import 'package:oracly_new/features/dream/models/dream_insight.dart';
import 'package:oracly_new/features/dream/services/dream_premium_delivery_quality.dart';

import 'dream_final_audit_support.dart';
import 'dream_phase1_support.dart';

final _technical = RegExp(
  r'exception|error:|stack|http|\b[45]\d\d\b|json|null|openai|gpt|proxy|timeout\(',
  caseSensitive: false,
);

DreamAiAnalysis _drop(DreamAiAnalysis a, String field) => DreamAiAnalysis(
      summary: field == 'summary' ? '' : a.summary,
      symbols: a.symbols,
      emotionalTheme: field == 'emotionalMeaning' ? '' : a.emotionalTheme,
      interpretation: field == 'mainInterpretation' ? '' : a.interpretation,
      dailyLifeReflection:
          field == 'personalConnection' ? '' : a.dailyLifeReflection,
      conclusion: field == 'closingTakeaway' ? '' : a.conclusion,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<(DreamPhase1Env, DreamAnalysisController)> open() async {
    final env = await DreamPhase1Env.open(ai: FinalAuditAi());
    final controller = DreamAnalysisController(
      env.service(),
      organizingDelay: Duration.zero,
    );
    addTearDown(controller.dispose);
    return (env, controller);
  }

  Future<void> expectCleanFailure(
    DreamPhase1Env env,
    DreamAnalysisController controller,
  ) async {
    await controller.submit(narrative: phase1NarrativeA);
    expect(controller.phase, DreamJourneyPhase.error);
    expect(controller.dream, isNull);
    expect(controller.errorMessage, isNotEmpty);
    expect(controller.errorMessage, isNot(matches(_technical)));
    expect(env.recordCount, 0);
    expect(env.dreamMemoryCount, 0);
    expect(env.versionsRaw ?? '', isNot(contains('"kind":"dream"')));

    await controller.submit(narrative: phase1NarrativeA);
    expect(controller.phase, DreamJourneyPhase.complete);
    expect(env.recordCount, 1, reason: 'retry persists exactly one Dream');
    expect(env.ai.narratives.toSet(), {phase1NarrativeA});
  }

  final kinds = <String, AiFailure Function()>{
    'network': AiFailure.network,
    'timeout': AiFailure.timeout,
    'rateLimit (429)': AiFailure.rateLimit,
    'providerError (5xx)': AiFailure.providerError,
    'invalidResponse (server parse/quality reject)': AiFailure.invalidResponse,
    'noConfiguration': AiFailure.noConfiguration,
    'unauthorized': AiFailure.unauthorized,
    'authPending': AiFailure.authPending,
    'appCheck': AiFailure.appCheck,
  };

  for (final entry in kinds.entries) {
    test('${entry.key}: calm error, nothing stored, retry succeeds', () async {
      final (env, controller) = await open();
      (env.ai as FinalAuditAi).failures.add(entry.value());
      await expectCleanFailure(env, controller);
    });
  }

  for (final field in [
    'summary',
    'emotionalMeaning',
    'mainInterpretation',
    'personalConnection',
    'closingTakeaway',
  ]) {
    test('missing required section $field is rejected before storage',
        () async {
      final (env, controller) = await open();
      (env.ai as FinalAuditAi).rewrites.add((a) => _drop(a, field));
      await expectCleanFailure(env, controller);
    });
  }

  test('unsafe provider prose is rejected before storage', () async {
    final (env, controller) = await open();
    (env.ai as FinalAuditAi).rewrites.add(
          (a) => DreamAiAnalysis(
            summary: a.summary,
            symbols: a.symbols,
            emotionalTheme: a.emotionalTheme,
            interpretation: a.interpretation,
            dailyLifeReflection:
                '${a.dailyLifeReflection} Bu rüya yakında öleceksin demek.',
            conclusion: a.conclusion,
          ),
        );
    await expectCleanFailure(env, controller);
  });

  test('a complete reply renders all five required sections', () async {
    final (env, controller) = await open();
    await controller.submit(narrative: phase1NarrativeA);
    final dream = controller.dream!;
    expect(dream.fromAi, isTrue);
    expect(DreamPremiumDeliveryQuality.firstGap(dream.insights), isNull);
    final stored = (await env.service().loadOwnedDream(dream.id))!;
    for (final kind in DreamPremiumDeliveryQuality.required) {
      final section = stored.insights.firstWhere((i) => i.kind == kind);
      expect(section.body.trim(), isNotEmpty, reason: '$kind survives reopen');
      expect(section.source, DreamInsightSource.ai);
    }
    expect(env.recordCount, 1);
  });
}
