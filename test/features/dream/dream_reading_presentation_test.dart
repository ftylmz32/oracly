/// Dream result is the user's story plus editorial sections.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/dream/copy/dream_copy.dart';
import 'package:oracly_new/features/dream/models/dream.dart';
import 'package:oracly_new/features/dream/models/dream_insight.dart';
import 'package:oracly_new/features/dream/services/dream_reading_presentation.dart';

void main() {
  setUp(() => OraclyL10n.bind('tr'));

  test('story stays the user narrative; insights become one reading', () {
    const narrative = 'Yağmur sessizce düşüyordu, evin eşiğinde durdum.';
    final dream = Dream(
      id: 'd1',
      narrative: narrative,
      recordedAt: DateTime(2026, 8, 17),
      insights: [
        DreamInsight(
          kind: DreamInsightKind.summary,
          title: DreamCopy.summaryTitle,
          body: 'Sahne sessiz bir eşikte duruyor.',
        ),
        DreamInsight(
          kind: DreamInsightKind.emotionalMeaning,
          title: DreamCopy.emotionalMeaningTitle,
          body: 'Eşik bir geçiş hissini tutuyor.',
        ),
        DreamInsight(
          kind: DreamInsightKind.themes,
          title: DreamCopy.symbolsHighlightTitle,
          body: 'Yağmur yıkanmayı değil, yumuşak bir duruşu anlatıyor.',
        ),
      ],
    );

    expect(DreamReadingPresentation.story(dream), narrative);
    final sections = DreamReadingPresentation.sections(dream);
    expect(sections.length, greaterThanOrEqualTo(2));
    expect(sections.any((s) => s.body.contains('Eşik bir geçiş')), isTrue);
    expect(sections.any((s) => s.emphasized), isTrue);
    final reading = DreamReadingPresentation.interpretation(dream);
    expect(reading, contains(DreamCopy.summaryTitle));
    expect(reading, isNot(contains(narrative)));
  });
}
