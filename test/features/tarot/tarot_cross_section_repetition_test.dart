import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/reading/ai_output_quality_category.dart';
import 'package:oracly_new/core/reading/ai_output_quality_tarot.dart';
import 'package:oracly_new/features/tarot/interpretation/models/interpretation_result.dart';

InterpretationResult _result({
  required String summary,
  required String career,
  String advice = 'Bugün iki seçeneği tek bir somut ölçüt üzerinden karşılaştır.',
}) =>
    InterpretationResult(
      requestId: 'r1',
      sessionId: 's1',
      summary: summary,
      love: '',
      career: career,
      money: '',
      health: '',
      spiritualGuidance: '',
      advice: advice,
      warnings: 'Kararı sadece hızlı rahatlama isteğiyle vermediğinden emin ol.',
      luckyEnergy: 'Açılımın bütünü netlikten sonra hareketi öne çıkarıyor.',
      dailyFocus: 'Bugün tek bir karar kriteri belirle.',
      closingMessage: 'İstersen iki seçeneği birlikte yan yana koyabiliriz.',
      generatedAt: DateTime(2026, 9, 8),
      source: InterpretationSource.ai,
    );

void main() {
  test('rejects near-duplicate substantial sections', () {
    final result = _result(
      summary:
          'Two of Swords burada iki seçenek arasında kalmanın baskısını gösteriyor; aceleden önce ölçütlerini netleştirmen daha sağlıklı bir yön veriyor.',
      career:
          'Two of Swords burada iki seçenek arasında kalmanın baskısını gösteriyor; aceleden önce ölçütlerini netleştirmen daha sağlıklı bir yön veriyor ve iş tarafında bunu somutlaştırıyor.',
    );

    expect(
      AiOutputQualityTarot.firstFailure(result),
      AiOutputQualityCategory.repetitiveFiller,
    );
  });

  test('allows sections that share topic but add genuinely different value', () {
    final result = _result(
      summary:
          'Two of Swords kararı ertelemekten çok, iki seçeneğin bedelini ayrı ayrı görme ihtiyacını öne çıkarıyor.',
      career:
          'İş tarafında Eight of Pentacles, kararın ardından disiplinli ve ölçülebilir bir çalışma planının daha belirleyici olacağını anlatıyor.',
    );

    expect(AiOutputQualityTarot.firstFailure(result), isNull);
  });
}
