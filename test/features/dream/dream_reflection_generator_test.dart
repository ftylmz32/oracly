import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/dream/copy/dream_copy.dart';
import 'package:oracly_new/features/dream/models/dream.dart';
import 'package:oracly_new/features/dream/models/dream_emotion.dart';
import 'package:oracly_new/features/dream/models/dream_insight.dart';
import 'package:oracly_new/features/dream/services/dream_reflection_generator.dart';
import 'package:oracly_new/features/dream/services/dream_understanding_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => OraclyL10n.bind('tr'));

  test('dream result is five grounded beats, not a dictionary', () {
    final understanding = DreamUnderstandingService().build(
      narrative: 'Evde kedimle deniz kenarında yürüdüm, annem de vardı.',
      selectedEmotions: [DreamEmotion(id: DreamEmotionId.peaceful)],
    );
    final dream = Dream(
      id: 'd1',
      narrative: 'Evde kedimle deniz kenarında yürüdüm, annem de vardı.',
      recordedAt: DateTime(2026, 8, 8),
      understanding: understanding,
    );

    final insights = const DreamReflectionGenerator().generate(
      dream: dream,
      understanding: understanding,
    );

    expect(
      insights.map((i) => i.kind),
      containsAll(<DreamInsightKind>[
        DreamInsightKind.summary,
        DreamInsightKind.symbols,
        DreamInsightKind.emotionalMeaning,
        DreamInsightKind.closingTakeaway,
      ]),
    );
    expect(
      insights.map((i) => i.kind),
      isNot(contains(DreamInsightKind.practicalTakeaway)),
    );

    final summary =
        insights.firstWhere((i) => i.kind == DreamInsightKind.summary);
    expect(summary.title, DreamCopy.summaryTitle);
    // Some variants name the scene, so the guard is that the summary reads the
    // dream in ORACLY's voice instead of handing the narrative back verbatim.
    expect(summary.body.toLowerCase(), contains('huzurlu'));
    expect(
      summary.body.trim(),
      isNot(equalsIgnoringCase(dream.narrative.trim())),
    );

    final emotion = insights
        .firstWhere((i) => i.kind == DreamInsightKind.emotionalMeaning);
    expect(emotion.title, DreamCopy.emotionalMeaningTitle);
    expect(emotion.body.toLowerCase(), isNot(contains('anlam:')));
    expect(emotion.body.contains('?'), isFalse);

    final symbols =
        insights.firstWhere((i) => i.kind == DreamInsightKind.symbols);
    expect(symbols.title, DreamCopy.symbolsTitle);
    expect(symbols.body.toLowerCase(), isNot(contains('anlam:')));
    expect(
      symbols.body.toLowerCase(),
      anyOf(contains('kedi'), contains('deniz'), contains('anne')),
    );

    final question =
        insights.firstWhere((i) => i.kind == DreamInsightKind.closingTakeaway);
    expect(question.title, DreamCopy.optionalQuestionTitle);
    expect(question.body.contains('?'), isTrue);
    expect(question.body.split('?').length - 1, 1);
  });
}
