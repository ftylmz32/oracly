/// Human content engine — remaining surfaces after the hub rewrite.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/reading/human_reader.dart';
import 'package:oracly_new/features/companion/data/companion_answer_copy.dart';
import 'package:oracly_new/features/dream/models/dream.dart';
import 'package:oracly_new/features/dream/services/dream_interpretation_copy.dart';
import 'package:oracly_new/features/dream/services/dream_reading_presentation.dart';
import 'package:oracly_new/features/dream/services/dream_reflection_generator.dart';
import 'package:oracly_new/features/dream/services/dream_understanding_service.dart';
import 'package:oracly_new/features/palm/models/palm_hand.dart';
import 'package:oracly_new/features/palm/models/palm_reading.dart';
import 'package:oracly_new/features/palm/services/palm_fortune_composer.dart';
import 'package:oracly_new/features/premium/services/soul_mate_draw_port.dart';
import 'package:oracly_new/features/premium/services/soul_mate_interpretation.dart';

const _banned = [
  'kehanet değil',
  'uydurma bir anı',
  'elimde bugünün',
  'ay, yükselen',
  'gündüz ertelediğin',
  'sembolik mesaj:',
  'okumanın özeti',
  'yeterli olabilir',
];

void main() {
  setUp(() => OraclyL10n.bind('tr'));

  test('reader skips personal relevance without a real life thread', () {
    final text = HumanReader.write(
      const HumanReaderNotice(
        seed: 3,
        seen: 'kuş',
        meaning: 'Beklenen haber yolun ucunda duruyor.',
        vessel: 'bu fincanda',
      ),
    );
    expect(text.toLowerCase(), contains('kuş'));
    expect(text.toLowerCase(), isNot(contains('herkese aynı')));
    expect(text.toLowerCase(), isNot(contains('kehanet')));
    expect(HumanReader.looksGeneric(text), isFalse);
  });

  test('reader banks stay specific in tr en ru', () {
    for (final code in ['tr', 'en', 'ru']) {
      OraclyL10n.bind(code);
      final text = HumanReader.write(
        HumanReaderNotice(
          seed: 1,
          seen: 'path',
          meaning: 'The unfinished talk sits at the edge.',
          lifeThread: 'relationship',
          vessel: HumanReader.vesselCup(),
        ),
      );
      expect(text.toLowerCase(), contains('path'));
      expect(text.toLowerCase(), contains('relationship'));
      expect(text.contains('reader.'), isFalse, reason: text);
      expect(HumanReader.looksGeneric(text), isFalse, reason: text);
    }
  });

  test('dream palm soulmate and or copy fail the anyone-test', () {
    OraclyL10n.bind('tr');
    const told = 'Rüyamda uzun bir yılan evin içinden geçti.';
    final understanding = DreamUnderstandingService().build(narrative: told);
    final dream = Dream(
      id: 'd1',
      narrative: told,
      recordedAt: DateTime(2026, 8, 18),
      understanding: understanding,
    );
    final withInsights = dream.copyWith(
      insights: const DreamReflectionGenerator().generate(
        dream: dream,
        understanding: understanding,
      ),
    );
    final palm = PalmFortuneComposer.compose(
      PalmReading(
        id: 'p1',
        createdAt: DateTime(2026, 8, 18),
        hand: PalmHand.right,
        overall: 'El geniş ve belirgin çizgili.',
        heartLine: 'Kalp çizgisinin belirgin yapısı.',
        headLine: '',
        lifeLine: '',
        fateLine: '',
      ),
    );
    final soul = SoulMateInterpretation.forRequest(
      SoulMateDrawRequest(
        name: 'Ayşe',
        birthDate: DateTime(1994, 3, 12),
        intention: 'sakin bir bağ',
      ),
    );
    final dreamMain = DreamInterpretationCopy.mainInterpretation(
      understanding: understanding,
      narrative: told,
    );
    final shown = DreamReadingPresentation.interpretation(withInsights);
    final texts = [
      dreamMain,
      shown,
      palm.overall,
      soul,
      CompanionAnswerCopy.energy,
      CompanionAnswerCopy.astrology,
    ];
    for (final text in texts) {
      expect(text, isNotEmpty);
      expect(text.contains('…'), isFalse, reason: text);
      for (final phrase in _banned) {
        expect(text.toLowerCase(), isNot(contains(phrase)), reason: text);
      }
      expect(HumanReader.looksGeneric(text), isFalse, reason: text);
    }
    expect(dreamMain.toLowerCase(), contains('yılan'));
    expect(shown.toLowerCase(), contains('yılan'));
    expect(shown.toLowerCase(), isNot(contains('anlam:')));
    expect(palm.overall.toLowerCase(), contains('el geniş'));
    expect(soul, contains('Ayşe'));
  });
}
