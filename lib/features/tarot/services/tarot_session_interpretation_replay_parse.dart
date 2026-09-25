/// Unguarded section parse for durable purchased-body replay (Phase 8.1).
library;

import '../interpretation/formatters/interpretation_section_parser.dart';
import '../interpretation/models/interpretation_result.dart';

abstract final class TarotSessionInterpretationReplayParse {
  TarotSessionInterpretationReplayParse._();

  /// Section parse only — never ReflectiveIntelligence.guard.
  static InterpretationResult? parse({
    required String rawText,
    required String sessionId,
    required InterpretationSource source,
  }) {
    final sections = InterpretationSectionParser.parse(rawText);
    if (sections.isEmpty) return null;
    return InterpretationResult(
      requestId: 'replay_$sessionId',
      sessionId: sessionId,
      summary: InterpretationSectionParser.pick(
            sections,
            [
              'açılımın teması',
              'özet mesaj',
              'genel yorum',
              'özet',
              'summary',
              'theme of the spread',
              'main theme',
              'тема расклада',
              'öne çıkan',
            ],
          ) ??
          rawText.split('\n').first,
      love: InterpretationSectionParser.pick(
            sections,
            ['aşk', 'love', 'ilişki', 'любов'],
          ) ??
          '',
      career: InterpretationSectionParser.pick(
            sections,
            ['kariyer', 'career', 'карьер'],
          ) ??
          '',
      money: InterpretationSectionParser.pick(
            sections,
            [
              'genel bakış',
              'yaşam teması',
              'maddi',
              'para',
              'money',
              'wider view',
              'общий взгляд',
            ],
          ) ??
          '',
      health: InterpretationSectionParser.cardReadings(sections),
      spiritualGuidance: InterpretationSectionParser.pick(
            sections,
            [
              'günlük fal',
              'ruhsal',
              'spiritual',
              'daily reading',
              'дневное',
              'düşünmeye',
            ],
          ) ??
          '',
      advice: InterpretationSectionParser.pick(
            sections,
            ['tavsiye', 'advice', 'öneri', 'совет'],
          ) ??
          '',
      warnings: InterpretationSectionParser.pick(
            sections,
            [
              'kendine sor',
              'uyarı',
              'warning',
              'uyarılar',
              'ask yourself',
              'спроси себя',
            ],
          ) ??
          '',
      luckyEnergy: InterpretationSectionParser.pick(
            sections,
            [
              'açılımın genel yorumu',
              'genel enerji',
              'şans',
              'lucky',
              'spread as a whole',
              'общее толкование',
            ],
          ) ??
          '',
      dailyFocus: InterpretationSectionParser.pick(
            sections,
            [
              'bugün için mesaj',
              'günün mesajı',
              'pratik mesaj',
              'message for today',
              'послание на сегодня',
            ],
          ) ??
          '',
      closingMessage: InterpretationSectionParser.pick(
            sections,
            ['sonuç', 'kapanış', 'closing', 'итог'],
          ) ??
          '',
      generatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      source: source,
      rawText: rawText,
    );
  }
}
