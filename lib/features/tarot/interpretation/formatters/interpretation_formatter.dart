/// OR-1180 — Formats interpretation results and maps to UI models.
library;

import '../../../insights/services/reflective_intelligence.dart';
import '../../copy/tarot_l10n.dart';
import '../../domain/models/reading_session.dart';
import '../../presentation/widgets/ai_reading/ai_reading_content.dart';
import '../../presentation/widgets/card_reveal/card_reveal_spread.dart';
import '../models/interpretation_result.dart';
import '../models/reading_context.dart';
import 'interpretation_section_parser.dart';

class InterpretationFormatter {
  const InterpretationFormatter();

  String toMarkdown(InterpretationResult result) {
    final buffer = StringBuffer();
    for (final section in result.sections) {
      if (section.content.trim().isEmpty) continue;
      buffer.writeln('## ${section.title}');
      buffer.writeln(section.content.trim());
      buffer.writeln();
    }
    return buffer.toString().trim();
  }

  InterpretationResult? parseRawResponse({
    required String rawText,
    required String requestId,
    required String sessionId,
    InterpretationSource source = InterpretationSource.local,
  }) {
    if (rawText.trim().isEmpty) return null;

    final sections = InterpretationSectionParser.parse(rawText);
    if (sections.isEmpty) return null;

    return ReflectiveIntelligence.guard(
      InterpretationResult(
        requestId: requestId,
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
        generatedAt: DateTime.now(),
        source: source,
        rawText: rawText,
      ),
    );
  }

  bool validate(InterpretationResult result) {
    if (result.summary.trim().isEmpty) return false;
    final filled = result.sections.where((s) => s.content.trim().isNotEmpty);
    return filled.length >= 3;
  }

  AiReadingContent toUiContent({
    required InterpretationResult result,
    required ReadingSession session,
  }) {
    return toUiContentFromContext(
      result: result,
      context: ReadingContext.fromSession(session),
      drawnCards: session.drawnCards,
      spreadLabel: TarotL10n.spread(session.spread),
    );
  }

  AiReadingContent toUiContentFromContext({
    required InterpretationResult result,
    required ReadingContext context,
    required List<TarotDrawnCard> drawnCards,
    required String spreadLabel,
  }) {
    final primary = drawnCards.first;
    final reveal = RevealCardData.fromDrawnCard(primary);
    return AiReadingContent(
      cardName: drawnCards.length == 1
          ? primary.localizedName
          : TarotL10n.spreadReadingTitle(context.spreadType),
      tagline: reveal.subtitle,
      generalMeaning: result.summary,
      love: result.love,
      career: result.career,
      money: result.money,
      spiritualGuidance: result.spiritualGuidance,
      luckyEnergy: result.luckyEnergy,
      dailyAdvice: result.dailyFocus.isNotEmpty
          ? result.dailyFocus
          : result.advice,
      closingMessage: result.closingMessage,
      imageAsset: reveal.imageAsset,
      rarityColor: reveal.rarityColor,
      fullInterpretation: result.rawText ?? toMarkdown(result),
      drawnCards: drawnCards,
      spreadLabel: spreadLabel,
      cardReadings: InterpretationSectionParser.fromResultHealthOrRaw(
        health: result.health,
        rawText: result.rawText,
      ),
      readingTheme: context.readingTheme,
      promptQuestion: result.warnings,
      userQuestion: context.userQuestion,
      interpretationSource: result.source,
    );
  }
}
