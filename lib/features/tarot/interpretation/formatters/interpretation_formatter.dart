/// OR-1180 — Formats interpretation results and maps to UI models.
library;

import '../../../insights/services/reflective_intelligence.dart';
import '../../domain/models/reading_session.dart';
import '../../presentation/widgets/ai_reading/ai_reading_content.dart';
import '../../presentation/widgets/card_reveal/card_reveal_spread.dart';
import '../models/interpretation_result.dart';
import '../models/reading_context.dart';

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
  }) {
    if (rawText.trim().isEmpty) return null;

    final sections = _parseSections(rawText);
    if (sections.isEmpty) return null;

    return ReflectiveIntelligence.guard(
      InterpretationResult(
        requestId: requestId,
        sessionId: sessionId,
        summary: _pick(sections, ['özet', 'summary', 'öne çıkan']) ??
            rawText.split('\n').first,
        love: _pick(sections, ['aşk', 'love', 'ilişki', 'temsil']) ?? '',
        career: _pick(sections, ['kariyer', 'career']) ?? '',
        money: _pick(sections, ['para', 'money', 'maddi']) ?? '',
        health: _pick(sections, ['sağlık', 'health']) ?? '',
        spiritualGuidance: _pick(
              sections,
              ['ruhsal', 'spiritual', 'sorular', 'düşünmeye'],
            ) ??
            '',
        advice: _pick(sections, ['tavsiye', 'advice', 'öneri', 'pratik']) ??
            '',
        warnings: _pick(sections, ['uyarı', 'warning', 'uyarılar']) ?? '',
        luckyEnergy: _pick(sections, ['şans', 'lucky', 'enerji', 'tema']) ?? '',
        dailyFocus: _pick(sections, ['odak', 'günlük', 'daily']) ?? '',
        closingMessage:
            _pick(sections, ['kapanış', 'closing', 'mesaj']) ?? '',
        generatedAt: DateTime.now(),
        source: InterpretationSource.ai,
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
    final primary = session.drawnCards.first;
    final reveal = RevealCardData.fromDrawnCard(primary);

    return AiReadingContent(
      cardName: session.drawnCards.length == 1
          ? primary.card.name
          : '${session.spread.label} Açılımı',
      tagline: reveal.subtitle,
      generalMeaning: result.summary,
      love: result.love,
      career: result.career,
      money: result.money,
      spiritualGuidance: result.spiritualGuidance,
      luckyEnergy: result.luckyEnergy,
      dailyAdvice: result.advice,
      closingMessage: result.closingMessage,
      imageAsset: reveal.imageAsset,
      rarityColor: reveal.rarityColor,
      fullInterpretation: result.rawText ?? toMarkdown(result),
      drawnCards: session.drawnCards,
      spreadLabel: session.spread.label,
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
          ? primary.card.name
          : '$spreadLabel Açılımı',
      tagline: reveal.subtitle,
      generalMeaning: result.summary,
      love: result.love,
      career: result.career,
      money: result.money,
      spiritualGuidance: result.spiritualGuidance,
      luckyEnergy: result.luckyEnergy,
      dailyAdvice: result.advice,
      closingMessage: result.closingMessage,
      imageAsset: reveal.imageAsset,
      rarityColor: reveal.rarityColor,
      fullInterpretation: result.rawText ?? toMarkdown(result),
      drawnCards: drawnCards,
      spreadLabel: spreadLabel,
    );
  }

  Map<String, String> _parseSections(String text) {
    final result = <String, String>{};
    final pattern = RegExp(r'^##?\s+(.+)$', multiLine: true);
    final matches = pattern.allMatches(text).toList();
    if (matches.isEmpty) return result;

    for (var i = 0; i < matches.length; i++) {
      final title = matches[i].group(1)!.trim().toLowerCase();
      final start = matches[i].end;
      final end = i + 1 < matches.length ? matches[i + 1].start : text.length;
      result[title] = text.substring(start, end).trim();
    }
    return result;
  }

  String? _pick(Map<String, String> sections, List<String> keys) {
    for (final key in keys) {
      for (final entry in sections.entries) {
        if (entry.key.contains(key)) return entry.value;
      }
    }
    return null;
  }
}
