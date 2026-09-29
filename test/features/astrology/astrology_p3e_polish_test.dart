/// P3E — optional profile must not block the hub; OR chrome follows locale.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/ai/oracle_conversation/models/oracle_reading_context_sources.dart';

void main() {
  test('OR astrology chrome follows the bound locale', () {
    OraclyL10n.bind('en');
    final en = OracleReadingContextSources.astrology(
      id: 'aries-today',
      signLabel: 'Aries',
      daily: 'A quiet step.',
    );
    expect(en.sourceLabel, 'Astrology');
    expect(en.deckName, 'Astrology');
    expect(en.readingTitle, 'Aries');
    expect(en.spreadLabel, 'Aries');
    expect(en.cardsSummary, 'Aries · Daily');
    expect(en.fullInterpretation, contains('Sign: Aries'));
    expect(en.fullInterpretation, contains('local sun-sign catalogue'));
    expect(en.fullInterpretation, contains('A quiet step.'));
    expect(en.fullInterpretation, isNot(contains('Burç:')));
    expect(en.fullInterpretation, isNot(contains('Günlük')));
    expect(en.deckName, isNot('Burç Yorumu'));

    OraclyL10n.bind('ru');
    final ru = OracleReadingContextSources.astrology(
      id: 'aries-today',
      signLabel: 'Овен',
      daily: 'Тихий шаг.',
    );
    expect(ru.sourceLabel, 'Астрология');
    expect(ru.cardsSummary, contains('Ежедневно'));
    expect(ru.fullInterpretation, isNot(contains('Burç:')));

    OraclyL10n.bind('tr');
    final tr = OracleReadingContextSources.astrology(
      id: 'koc-today',
      signLabel: 'Koç',
      daily: 'Bugün ölçülü ilerle.',
    );
    expect(tr.sourceLabel, 'Astroloji');
    expect(tr.fullInterpretation, contains('Burç: Koç'));
    expect(tr.fullInterpretation, contains('yerel Güneş burcu kataloğu'));
  });
}
