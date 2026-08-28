/// EPIC-013 — Reflective reading synthesis and tone guard.
library;

import '../../tarot/interpretation/models/interpretation_result.dart';
import '../../tarot/interpretation/models/reading_context.dart';
import '../../../core/reading/human_reader.dart';
import '../../tarot/reading/tarot_reading_engine.dart';

/// Builds readings: observational, answer-first, no fortune-telling certainty.
abstract final class ReflectiveIntelligence {
  ReflectiveIntelligence._();

  static const _forbiddenPhrases = [
    'kesinlikle',
    'mutlaka',
    'evren seninle konuşuyor',
    'evren bugün',
    'ruhsal seviye',
    'kaçınılması gerek',
    'asla',
    'her zaman',
    'kader',
    'felaket',
    'tehlike',
    'hastalığ',
    'ömrün',
    'kesin olacak',
    'garanti gelecek',
    'kesinlikle başına gelecek',
    'mutlaka olacak',
    'it will definitely',
    'you will definitely',
    'must come back',
    'точно будет',
    'обязательно верн',
    'непременно случится',
  ];

  static InterpretationResult synthesize({
    required ReadingContext context,
    required String requestId,
  }) {
    return TarotReadingEngine.run(
      context: context,
      requestId: requestId,
    );
  }

  static InterpretationResult guard(InterpretationResult result) {
    return InterpretationResult(
      requestId: result.requestId,
      sessionId: result.sessionId,
      summary: soften(result.summary),
      love: soften(result.love),
      career: soften(result.career),
      money: soften(result.money),
      health: soften(result.health),
      spiritualGuidance: soften(result.spiritualGuidance),
      advice: soften(result.advice),
      warnings: soften(result.warnings),
      luckyEnergy: soften(result.luckyEnergy),
      dailyFocus: soften(result.dailyFocus),
      closingMessage: soften(result.closingMessage),
      generatedAt: result.generatedAt,
      source: result.source,
      rawText: result.rawText != null ? soften(result.rawText!) : null,
      fromCache: result.fromCache,
    );
  }

  static String soften(String text) {
    if (text.trim().isEmpty) return text;
    var out = text;
    const replacements = <String, String>{
      'Kesinlikle': 'Belki',
      'kesinlikle': 'belki',
      'Mutlaka': 'Olabilir',
      'mutlaka': 'olabilir',
      'Evren seninle konuşuyor': 'Burada bir davet duruyor olabilir',
      'evren seninle konuşuyor': 'burada bir davet duruyor olabilir',
      'Evren bugün': 'Bugün',
      'evren bugün': 'bugün',
      'Evren seninle fısıldaşıyor': 'Bugün cevap dışarıda bağırarak gelmeyebilir',
      'evren seninle fısıldaşıyor': 'bugün cevap dışarıda bağırarak gelmeyebilir',
      'İç sesine güven': 'Durduğun yere bak',
      'iç sesine güven': 'durduğun yere bak',
      'kozmik enerji': 'tempo',
      'Kozmik enerji': 'Tempo',
      'Ruhsal Seviye': 'Durduğun yer',
      'ruhsal seviye': 'durduğun yer',
      'iç yolculuk': 'içeride olan',
      'İç yolculuk': 'İçeride olan',
      'dönüşüm enerjisi': 'değişim tarafı',
      'Dönüşüm enerjisi': 'Değişim tarafı',
      'yolculuğun doğru yönde': 'adımın netleşebilir',
      'Yolculuğun doğru yönde': 'Adımın netleşebilir',
      'farkındalık açısından': 'açısından',
      'Farkındalık açısından': 'Açısından',
      'farkındalığı destekler': 'netleştirmeye yardım eder',
      'Farkındalığı destekler': 'Netleştirmeye yardım eder',
      'enerjisini açığa çıkarır': 'tonunu daha seçilir kılar',
      'Enerjisini açığa çıkarır': 'Tonunu daha seçilir kılar',
      'enerjisini bilinçle kullan': 'tonunu acele etmeden taşı',
      'senin için bir davet': 'bir davet gibi',
      'seçilir duruyor': 'daha net duruyor',
      'daha seçilir': 'daha net',
      'katalog cümlesinden': 'tek bir cümleden',
      'sana bıraktığı soru': 'bu faslın bıraktığı yer',
      'asla ': 'nadiren ',
      'Asla ': 'Nadiren ',
      'her zaman': 'sık sık',
      'Her zaman': 'Sık sık',
      'kader': 'yön',
      'Kader': 'Yön',
    };
    for (final entry in replacements.entries) {
      out = out.replaceAll(entry.key, entry.value);
    }
    return HumanReader.guard(out);
  }

  static bool containsForbiddenTone(String text) {
    final lower = text.toLowerCase();
    return _forbiddenPhrases.any(lower.contains);
  }
}
