/// Dream V1 polish — structure, honest AI, history, OR context, gems.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/domain/models/dream_record.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/personality/or_living_voice.dart';
import 'package:oracly_new/features/ai/oracle_conversation/models/oracle_reading_context_sources.dart';
import 'package:oracly_new/features/ai/oracle_conversation/services/oracle_followup_copy.dart';
import 'package:oracly_new/features/dream/copy/dream_copy.dart';
import 'package:oracly_new/features/dream/data/dream_record_mapper.dart';
import 'package:oracly_new/features/dream/economy/dream_economy.dart';
import 'package:oracly_new/features/dream/models/dream.dart';
import 'package:oracly_new/features/dream/models/dream_insight.dart';
import 'package:oracly_new/features/dream/services/dream_reflection_generator.dart';
import 'package:oracly_new/features/dream/services/dream_understanding_service.dart';
import 'package:oracly_new/features/dream/services/unavailable_dream_ai.dart';
import 'package:oracly_new/features/gems/copy/gems_copy.dart';

void main() {
  setUp(() => OraclyL10n.bind('tr'));

  const narrative =
      'Rüyamda uzun bir yılan evin içinden geçti, annem de oradaydı.';

  Dream analyzedDream() {
    final understanding = DreamUnderstandingService().build(
      narrative: narrative,
    );
    final dream = Dream(
      id: 'd-snake',
      narrative: narrative,
      recordedAt: DateTime(2026, 8, 9, 2, 40),
      understanding: understanding,
    );
    return dream.copyWith(
      insights: const DreamReflectionGenerator().generate(
        dream: dream,
        understanding: understanding,
      ),
    );
  }

  test('result sections follow the V1 reading spine', () {
    final kinds = analyzedDream().insights.map((i) => i.kind).toList();
    expect(kinds.first, DreamInsightKind.summary);
    expect(kinds, contains(DreamInsightKind.emotionalMeaning));
    expect(kinds, contains(DreamInsightKind.closingTakeaway));
    expect(
      kinds.indexOf(DreamInsightKind.emotionalMeaning),
      lessThan(kinds.indexOf(DreamInsightKind.closingTakeaway)),
    );
    expect(DreamCopy.disclaimer, contains('sembolik'));
    expect(
      DreamCopy.reflecting,
      isIn(OrLivingVoice.thinkingPool(OrLivingSurface.dream)),
    );
  });

  test('history reopen keeps summary symbols emotion and interpretation', () {
    final dream = analyzedDream();
    final restored = DreamRecordMapper.fromRecord(
      DreamRecord.fromJson(DreamRecordMapper.toRecord(dream).toJson()),
    );
    expect(restored.narrative, narrative);
    expect(restored.understanding?.symbols, isNotEmpty);
    expect(
      restored.insights.map((i) => i.kind),
      containsAll([
        DreamInsightKind.summary,
        DreamInsightKind.symbols,
        DreamInsightKind.emotionalMeaning,
        DreamInsightKind.closingTakeaway,
      ]),
    );
    expect(
      restored.insights
          .firstWhere((i) => i.kind == DreamInsightKind.summary)
          .body,
      dream.insights
          .firstWhere((i) => i.kind == DreamInsightKind.summary)
          .body,
    );
  });

  test('OR answers a symbol question from dream context', () {
    final dream = analyzedDream();
    final interpretation = dream.insights
        .firstWhere((i) => i.kind == DreamInsightKind.symbols)
        .body;
    final emotion = dream.insights
        .firstWhere((i) => i.kind == DreamInsightKind.summary)
        .body;
    final ctx = OracleReadingContextSources.dream(
      id: dream.id,
      narrative: dream.narrative,
      analysis: interpretation,
      symbols: dream.understanding!.symbols.map((s) => s.label).toList(),
      emotionalTheme: emotion,
      fullInterpretation: dream.insights
          .map((i) => '${i.title}: ${i.body}')
          .join('\n\n'),
    );
    expect(ctx.cardsSummary, contains('yılan'));
    expect(ctx.cardNames.map((e) => e.toLowerCase()), contains('yılan'));
    final answer = OracleFollowupCopy.respond(
      context: ctx,
      question: 'Bu rüyadaki yılan neyi temsil ediyor?',
    );
    expect(answer.toLowerCase(), contains('yılan'));
    expect(answer, contains(interpretation.split('.').first));
    expect(answer, isNot(contains('sana ne hissettirdi')));
  });

  test('unavailable AI is honest and dream stays free', () {
    expect(const UnavailableDreamAI().isAvailable, isFalse);
    expect(DreamEconomy.hasCost, isFalse);
    expect(DreamEconomy.analysisCost, isNull);
    expect(GemsCopy.insufficient, 'Yeterli mücevherin yok.');
  });
}
