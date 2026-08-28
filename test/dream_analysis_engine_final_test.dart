/// Final dream analysis engine — personal, symbolic, curious, grounded.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/fortune_voice.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/reading/human_reader.dart';
import 'package:oracly_new/features/ai/production/models/dream_ai_analysis.dart';
import 'package:oracly_new/features/ai/production/openai/dream_prompt_style.dart';
import 'package:oracly_new/features/dream/copy/dream_copy.dart';
import 'package:oracly_new/features/dream/models/dream.dart';
import 'package:oracly_new/features/dream/models/dream_emotion.dart';
import 'package:oracly_new/features/dream/services/dream_analysis_composer.dart';
import 'package:oracly_new/features/dream/services/dream_analysis_guard.dart';
import 'package:oracly_new/features/dream/services/dream_pattern_service.dart';
import 'package:oracly_new/features/dream/services/dream_reading_presentation.dart';
import 'package:oracly_new/features/dream/services/dream_understanding_service.dart';

void main() {
  setUp(() => OraclyL10n.bind('tr'));

  test('short dream stays personal and not a dictionary', () {
    final reading = _read('Yılan vardı.');
    expect(reading.toLowerCase(), contains('yılan'));
    expect(reading, contains(DreamCopy.summaryTitle));
    expect(reading, contains(DreamCopy.symbolsHighlightTitle));
    expect(reading, contains(DreamCopy.optionalQuestionTitle));
    _quality(reading);
    expect(reading.toLowerCase(), isNot(contains('anlam:')));
    expect(reading, isNot(contains('Yılan = ')));
  });

  test('long dream uses a real detail and does not dump the plot', () {
    const told =
        'Gece yarısı eski evin koridorundaydım. Annem mutfakta duruyordu ama '
        'yüzünü tam göremedim. Uzun bir yılan eşiğin altından sessizce geçti, '
        'sonra merdivenler bitti ve ben aynı kapıya üç kez döndüm. Deniz yoktu. '
        'Sadece koridordaki toz ve yılanın soğuk geçişi kaldı. Uyandığımda '
        'hâlâ o kapıyı arıyordum, fakat rüyanın geri kalanı dağılmıştı.';
    final reading = _read(
      told,
      emotions: [DreamEmotion(id: DreamEmotionId.anxious)],
    );
    expect(reading.toLowerCase(), contains('yılan'));
    expect(reading.toLowerCase(), contains('kaygılı'));
    expect(reading, isNot(contains(told)));
    expect(reading.split('?').length - 1, 1);
    _quality(reading);
  });

  test('ambiguous dream stays curious and invents no catalogue image', () {
    final reading = _read('Bir şey vardı ama ne olduğu belirsizdi.');
    expect(reading.toLowerCase(), isNot(contains('yılan')));
    expect(reading.toLowerCase(), isNot(contains('kuş')));
    expect(reading.toLowerCase(), isNot(contains('kapı')));
    expect(reading, contains(DreamCopy.symbolsTitle));
    expect(reading, contains('?'));
    _quality(reading);
  });

  test('empty input does not invent a dream', () {
    final reading = _read('   ');
    expect(reading.toLowerCase(), isNot(contains('yılan')));
    expect(reading.toLowerCase(), isNot(contains('deniz')));
    expect(reading.toLowerCase(), contains('uydurma'));
    expect(reading, contains('?'));
    _quality(reading);
  });

  test('personal connection appears only with a real prior pattern', () {
    final understanding = DreamUnderstandingService().build(
      narrative: 'Kedimle denizin kenarında yürüdüm.',
    );
    final current = Dream(
      id: 'now',
      narrative: 'Kedimle denizin kenarında yürüdüm.',
      recordedAt: DateTime(2026, 8, 18),
      understanding: understanding,
    );
    final prior = Dream(
      id: 'old',
      narrative: 'Denizde kedim vardı.',
      recordedAt: DateTime(2026, 7, 1),
      understanding: DreamUnderstanding(
        symbols: understanding.symbols,
        emotions: const [],
        locations: const [],
        relationships: const [],
        recurringElements: const [],
        summary: '',
      ),
    );
    final match = const DreamPatternService().findConnection(
      current: current,
      previousDreams: [prior],
    );
    expect(match, isNotNull);
    final withPattern = DreamReadingPresentation.interpretation(
      current.copyWith(
        insights: DreamAnalysisComposer.compose(
          dream: current,
          understanding: understanding,
          pattern: match,
        ),
      ),
    );
    final without = _read('Kedimle denizin kenarında yürüdüm.');
    expect(withPattern, contains(DreamCopy.lifeReflectionTitle));
    expect(withPattern, isNot(contains(prior.narrative)));
    expect(without, isNot(contains(DreamCopy.lifeReflectionTitle)));
  });

  test('rejected AI dictionary and invented symbols stay local', () {
    const told = 'Kapı açık duruyordu.';
    final understanding = DreamUnderstandingService().build(narrative: told);
    final dream = Dream(
      id: 'ai',
      narrative: told,
      recordedAt: DateTime(2026, 8, 18),
      understanding: understanding,
    );
    final reading = DreamReadingPresentation.interpretation(
      dream.copyWith(
        insights: DreamAnalysisComposer.compose(
          dream: dream,
          understanding: understanding,
          ai: const DreamAiAnalysis(
            summary: 'Yılan = dönüşüm.',
            symbols: ['yılan'],
            emotionalTheme: 'Kesin olacak bir hastalık belirtisi.',
            interpretation: 'Yılan dönüşümü temsil eder. Anlam: şifa.',
            dailyLifeReflection: 'Hayatına biri girecek.',
            conclusion: 'Bu rüya ne anlama geliyor? Bir de kuş neydi?',
          ),
        ),
      ),
    );
    expect(reading.toLowerCase(), contains('kapı'));
    expect(reading.toLowerCase(), isNot(contains('yılan')));
    expect(reading.toLowerCase(), isNot(contains('anlam:')));
    expect(reading.split('?').length - 1, 1);
    _quality(reading);
  });

  test('prompt forbids dictionary, diagnosis, and certainty', () {
    expect(DreamPromptStyle.system, contains('sözlüğ'));
    expect(DreamPromptStyle.system, contains('teşhis'));
    expect(DreamPromptStyle.userLead, contains('tek açık soru'));
    expect(DreamPromptStyle.userLead, contains('X = Y yok'));
  });
}

String _read(
  String narrative, {
  List<DreamEmotion> emotions = const [],
}) {
  final understanding = DreamUnderstandingService().build(
    narrative: narrative,
    selectedEmotions: emotions,
  );
  final dream = Dream(
    id: 't',
    narrative: narrative,
    recordedAt: DateTime(2026, 8, 18),
    selectedEmotions: emotions,
    understanding: understanding,
  );
  return DreamReadingPresentation.interpretation(
    dream.copyWith(
      insights: DreamAnalysisComposer.compose(
        dream: dream,
        understanding: understanding,
      ),
    ),
  );
}

void _quality(String reading) {
  expect(reading.trim(), isNotEmpty);
  expect(DreamAnalysisGuard.looksDictionary(reading), isFalse, reason: reading);
  expect(HumanReader.looksGeneric(reading), isFalse, reason: reading);
  expect(FortuneVoice.claimsMedical(reading), isFalse, reason: reading);
  expect(FortuneVoice.claimsCertainty(reading), isFalse, reason: reading);
}
