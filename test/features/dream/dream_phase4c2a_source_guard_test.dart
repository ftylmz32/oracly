// Dream Phase 4C.2a — the source-aware Dream guard: provider AI is never
// hard-rejected for on-device template style alone, and every safety,
// certainty, quality, invented-image and grounding layer still applies.
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/fortune_voice.dart';
import 'package:oracly_new/core/reading/human_reader.dart';
import 'package:oracly_new/features/dream/services/dream_analysis_facts.dart';
import 'package:oracly_new/features/dream/services/dream_analysis_guard.dart';
import 'package:oracly_new/features/dream/services/dream_invented_image.dart';
import 'package:oracly_new/features/dream/services/dream_understanding_service.dart';

import 'dream_phase4c_replay.dart';

const _shore = 'Rüyamda denizin kıyısındaydım, dalgalar sessizce ayaklarıma '
    'değiyordu. Uzakta küçük bir tekne vardı ve ona bakarken içim huzurla '
    'doldu.';
const _harbour = 'I walked along a quiet harbour at dusk. When the boat '
    'finally arrived I felt relieved and happy, and a little heavy inside.';

/// The live gpt-6-astra tr-history interpretation (Phase 4C.2 attempt).
const _astra = 'Dalgaların sessizce ayaklarına değmesi, uzaktaki tekneyi '
    'izleyişine yakından hissedilen bir temas katıyor. Böylece teknenin '
    'uzaklığı, bulunduğun kıyıyla bağını kesmeden huzurla bakabildiğin bir '
    'mesafe olarak okunabilir; sahnede ona ulaşmaktan çok, olduğu yerden '
    'bakmanın kendisi öne çıkıyor.';

DreamAnalysisFacts _facts(String narrative, String language) =>
    DreamAnalysisFacts.from(
      narrative: narrative,
      understanding: DreamUnderstandingService().build(
          narrative: narrative, selectedEmotions: const [], language: language),
      tags: const [],
      statedFeelings: const [],
      language: language,
    );

String? _provider(String text, DreamAnalysisFacts facts) =>
    DreamAnalysisGuard.polish(text, facts,
        source: DreamGuardSource.providerAi);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final tr = _facts(_shore, 'tr');
  final en = _facts(_harbour, 'en');

  test('grounded provider prose is not refused for template style alone', () {
    final guarded = HumanReader.guard(FortuneVoice.scrub(_astra));
    expect(HumanReader.looksGeneric(guarded), isTrue,
        reason: 'the live false positive this phase closes');
    expect(_provider(_astra, tr), isNotNull);
  });

  test('local text keeps the generic-style guard', () {
    expect(DreamAnalysisGuard.polish(_astra, tr), isNull);
    expect(
        DreamAnalysisGuard.polish(_astra, tr, source: DreamGuardSource.local),
        isNull);
  });

  test('provider AI still fails every independent layer', () {
    const snake =
        'The quiet harbour at dusk and a snake near the boat feel uneasy.';
    final refused = <String, (String, DreamAnalysisFacts)>{
      'DreamAnalysisGuard.inventedImageOrUngrounded': (
        'A new chapter of courage and self-trust is opening in your life now.',
        en
      ),
      'FortuneVoice.claimsMedical': (
        'Dalgaların ayaklarına değmesi bir hastalığın işareti olabilir; '
            'tekneye bakarken bunu düşün.',
        tr
      ),
      'DreamAnalysisGuard.dictionary': (
        'Deniz: rüyada deniz görmek huzur demektir, tekne de yolculuk olur.',
        tr
      ),
      'FortuneVoice.claimsCertainty': (
        'The boat at the quiet harbour means you will definitely find it.',
        en
      ),
      'AiOutputQualityGate.deterministicFuture': (
        'The boat in the quiet harbour returns to you 3 weeks from now.',
        en
      ),
    };
    for (final MapEntry(key: layer, value: (text, facts)) in refused.entries) {
      expect(_provider(text, facts), isNull, reason: layer);
      expect(rejectionLayer(text, facts), layer);
    }
    expect(DreamInventedImage.invents(snake, en), isTrue);
    expect(_provider(snake, en), isNull);
  });

  test('the closing question keeps its one-question contract', () {
    expect(
        DreamAnalysisGuard.conclusion(
            'What does the boat mean? Why the harbour?', en,
            source: DreamGuardSource.providerAi),
        isNull);
    expect(
        DreamAnalysisGuard.conclusion(
            'What stands out to you about the boat arriving at the harbour?',
            en,
            source: DreamGuardSource.providerAi),
        isNotNull);
  });
}
