/// Robotic language heuristic — score thresholds and bounded rewrite.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/reading/ai_output_quality_checks.dart';
import 'package:oracly_new/core/reading/ai_output_quality_gate.dart';
import 'package:oracly_new/core/reading/ai_output_quality_kind.dart';
import 'package:oracly_new/core/reading/robotic_language_detector.dart';
import 'package:oracly_new/core/reading/robotic_language_rewrite.dart';

void main() {
  test('single legitimate words do not fail', () {
    const once = 'Bu kartın enerjisi sakin; tema net bir yansıma bırakıyor.';
    expect(RoboticLanguageDetector.isHeavilyRepetitive(once), isFalse);
    expect(
      AiOutputQualityChecks.firstFailure(
        once,
        kind: AiOutputQualityKind.tarot,
      ),
      isNull,
    );
  });

  test('detects excessive filler and repeated openers', () {
    const robotic =
        'Bu kart ön plana çıkıyor. Bu kart dikkat çekiyor. Bu kart enerji taşır. '
        'Bu kart tema verir. Bu kart yansıma sunar. Tema enerji yansıma.';
    final report = RoboticLanguageDetector.analyze(robotic);
    expect(report.isHeavilyRepetitive, isTrue);
    expect(report.signals.any((s) => s.startsWith('repeated_opener×')), isTrue);
  });

  test('flags generic section headings', () {
    const withLabels = 'ANA HİS: korku.\nSEMBOLİK YORUM: su.\nDİKKAT ÇEKEN: kuş.';
    expect(RoboticLanguageDetector.analyze(withLabels).signals,
        contains('section_label'));
  });

  test('bounded rewrite varies openers and scrubs stock phrases', () {
    const input =
        'Bu kart ön plana çıkabilir. Bu kart dikkat çekiyor. '
        'Bu kart iletişim ön plana çıkabilir.';
    final out = RoboticLanguageRewrite.bounded(input);
    expect(out.toLowerCase(), isNot(contains('bu kart dikkat')));
    expect(out.toLowerCase(), isNot(contains('ön plana çıkabilir')));
    expect(RoboticLanguageDetector.isHeavilyRepetitive(out), isFalse);
  });

  test('rewrite dedupes parallel sentence starts', () {
    const input =
        'Bu rüya suda duruyor. Bu rüya suda duruyor. Bu rüya suda duruyor. '
        'Sonra ev kapısı açılıyor.';
    final out = RoboticLanguageRewrite.bounded(input);
    expect(out.split('Bu rüya suda duruyor').length - 1, lessThan(3));
  });

  test('quality gate polish applies bounded rewrite', () {
    const input =
        'Bu kart ön plana çıkabilir. Bu kart gündeme gelebilir. '
        'Bu kart fırsatlar doğabilir.';
    final polished = AiOutputQualityGate.polish(
      input,
      kind: AiOutputQualityKind.tarot,
    );
    expect(polished.toLowerCase(), isNot(contains('ön plana çıkabilir')));
    expect(
      AiOutputQualityGate.validate(
        polished,
        kind: AiOutputQualityKind.tarot,
      ).isAcceptable,
      isTrue,
    );
  });

  test('empty positivity adds score without banning unrelated words', () {
    const positive =
        'Her şey yoluna girecek; pozitif enerji seni bekliyor.';
    expect(
      RoboticLanguageDetector.analyze(positive).signals,
      contains('empty_positivity'),
    );
    const neutral = 'Kapı aralandı; içeride su sesi var.';
    expect(RoboticLanguageDetector.analyze(neutral).score, lessThan(4));
  });
}
