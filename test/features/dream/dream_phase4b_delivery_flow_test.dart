// Dream Phase 4B — configured AI delivery fails closed. A premium reply is
// persisted once with one version; an unacceptable one is a typed invalid
// response with no record, memory, version, or second provider call.
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/ai/production/contexts/reading_ai_context.dart';
import 'package:oracly_new/features/ai/production/models/dream_ai_analysis.dart';
import 'package:oracly_new/features/dream/models/dream_insight.dart';
import 'package:oracly_new/features/dream/services/dream_premium_delivery_quality.dart';

import 'dream_phase1_support.dart';
import 'dream_phase2_support.dart';
import 'dream_phase4b_support.dart';

class _GoldenAi extends HeldDreamAi {
  _GoldenAi(this.reply);

  DreamAiAnalysis reply;

  @override
  Future<AiOutcome<DreamAiAnalysis>> analyzeDream(
    DreamAiContext context,
  ) async {
    calls++;
    narratives.add(context.narrative);
    return AiOutcome.success(reply);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final id in [
    'tr-rich-negated-fear',
    'en-rich-negated-fear',
    'ru-rich-negated-fear',
  ]) {
    test('$id: premium success persists once with one version', () async {
      final g = dreamGolden(id);
      final env = await DreamPhase1Env.open(ai: _GoldenAi(g.analysis));
      final result = await env.service().analyze(narrative: g.narrative);

      expect(env.ai.calls, 1);
      expect(DreamPremiumDeliveryQuality.firstGap(result.dream.insights), isNull);
      for (final kind in DreamPremiumDeliveryQuality.required) {
        final section =
            result.dream.insights.singleWhere((i) => i.kind == kind);
        expect(section.source, DreamInsightSource.ai, reason: '$kind');
      }
      expect(result.dream.fromAi, isTrue);
      expect(env.recordCount, 1);
      expect(env.versions.groupFor(result.dream.id)?.entries, hasLength(1));
    });
  }

  final horse = dreamGolden('en-sparse-horse');
  final unacceptable = <String, DreamAiAnalysis>{
    'ungrounded interpretation': horse.withField('interpretation',
        'A lighthouse over a harbour keeps watch for a returning ship across dark water.'),
    'ungrounded reflection': horse.withField('dailyLifeReflection',
        'Today, practise patience like a lighthouse keeper on a long night shift.'),
    'closing without a question': horse.withField(
        'conclusion', 'The pale creature waits, strong and unhurried, for a reason to go.'),
  };

  unacceptable.forEach((name, reply) {
    test('$name: invalid response, nothing persisted, one call', () async {
      final env = await DreamPhase1Env.open(ai: _GoldenAi(reply));
      await expectLater(
        env.service().analyze(narrative: horse.narrative),
        throwsInvalidDreamResponse,
      );
      expect(env.ai.calls, 1);
      expect(env.persistedDreamState(), '##');
      expect(env.versionsRaw, isNull);
    });
  });

  test('unacceptable reinterpretation adds no version and mutates nothing',
      () async {
    final ai = _GoldenAi(horse.analysis);
    final env = await DreamPhase1Env.open(ai: ai);
    final first = await env.service().analyze(narrative: horse.narrative);
    final before = env.persistedDreamState();

    ai.reply = unacceptable.values.first;
    await expectLater(
        env.service().reinterpret(first.dream), throwsInvalidDreamResponse);

    expect(ai.calls, 2);
    expect(env.persistedDreamState(), before);
    expect(env.versions.groupFor(first.dream.id)?.entries, hasLength(1));
  });
}
