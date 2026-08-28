/// OR reading follow-up prompts — shared OR persona + structured context.
library;

import '../../../../core/personality/or_personality.dart';
import '../../../../core/personality/or_response_depth.dart';
import '../../../ai/services/prompt_sanitizer.dart';
import '../contexts/reading_ai_context.dart';
import '../models/conversation_turn.dart';
import 'chat_prompt_builder.dart';
import 'oracle_prompt_locale.dart';

abstract final class OraclePromptBuilder {
  OraclePromptBuilder._();

  static List<Map<String, dynamic>> messages({
    required ReadingAiContext context,
    required String userMessage,
    List<String> priorUser = const [],
    List<ConversationTurn> turns = const [],
    String? styleHint,
    String? personality,
    OrResponseDepth depth = OrResponseDepth.fallback,
    bool spoken = false,
  }) {
    final hint = (styleHint ?? '').trim();
    final voice = OrPersonality.conversationStyle(personality);
    final systemText = [
      ChatPromptBuilder.system,
      OraclePromptLocale.readingGrounding,
      if (voice.isNotEmpty) voice,
      depth.promptRule(spoken: spoken),
      if (hint.isNotEmpty) hint,
    ].join(' ');
    return [
      {'role': 'system', 'content': systemText},
      {'role': 'user', 'content': _contextBlock(context)},
      ..._history(turns, priorUser),
      {
        'role': 'user',
        'content': PromptSanitizer.sanitize(userMessage),
      },
    ];
  }

  static List<Map<String, String>> _history(
    List<ConversationTurn> turns,
    List<String> priorUser,
  ) {
    final window = ConversationTurn.takeRecent(turns);
    if (window.isNotEmpty) {
      return [
        for (final turn in window)
          {
            'role': turn.isUser ? 'user' : 'assistant',
            'content': PromptSanitizer.sanitize(turn.text),
          },
      ];
    }
    final prior = priorUser.reversed
        .take(8)
        .toList()
        .reversed
        .map(PromptSanitizer.sanitize)
        .where((e) => e.isNotEmpty);
    return [
      for (final line in prior) {'role': 'user', 'content': line},
    ];
  }

  static String _contextBlock(ReadingAiContext context) {
    final lines = <String>['${OraclePromptLocale.kind}: ${context.kindId}'];
    switch (context) {
      case TarotAiContext():
        lines.addAll([
          '${OraclePromptLocale.spread}: ${context.spreadLabel}',
          '${OraclePromptLocale.cards}:\n${context.cardsSummary}',
          '${OraclePromptLocale.summary}: ${context.interpretationSummary}',
          if ((context.userQuestion ?? '').trim().isNotEmpty)
            '${OraclePromptLocale.intention}: ${context.userQuestion}',
        ]);
      case DreamAiContext():
        lines.addAll([
          'Rüya: ${context.narrative}',
          if (context.symbols.isNotEmpty)
            'Semboller: ${context.symbols.join(', ')}',
          if ((context.analysis ?? '').trim().isNotEmpty)
            'Yorum: ${context.analysis}',
          if ((context.fullInterpretation ?? '').trim().isNotEmpty)
            context.fullInterpretation!,
        ]);
      case AstrologyAiContext():
        lines.addAll([
          'Burç: ${context.signLabel}',
          'Tür: ${context.readingType}',
          'Günlük: ${context.daily}',
          if ((context.fullInterpretation ?? '').trim().isNotEmpty)
            context.fullInterpretation!,
        ]);
      case BirthChartAiContext():
        lines.addAll([
          'Güneş: ${context.sunLabel}',
          'Yorum: ${context.interpretation}',
          if ((context.fullInterpretation ?? '').trim().isNotEmpty)
            context.fullInterpretation!,
        ]);
      case CoffeeAiContext():
        lines.addAll([
          if ((context.visualObservation ?? '').trim().isNotEmpty)
            'Görülen izler: ${context.visualObservation}',
          'Genel: ${context.overall}',
          if (context.symbolNames.isNotEmpty)
            'Semboller: ${context.symbolNames.join(', ')}',
          if ((context.fullInterpretation ?? '').trim().isNotEmpty)
            context.fullInterpretation!,
        ]);
      case PalmAiContext():
        lines.addAll([
          if ((context.handLabel ?? '').trim().isNotEmpty)
            'El: ${context.handLabel}',
          'Genel: ${context.overall}',
          if ((context.heartLine ?? '').trim().isNotEmpty)
            'Kalp çizgisi (sembolik): ${context.heartLine}',
          if ((context.headLine ?? '').trim().isNotEmpty)
            'Zihin çizgisi (sembolik): ${context.headLine}',
          if ((context.lifeLine ?? '').trim().isNotEmpty)
            'Yaşam çizgisi (sembolik): ${context.lifeLine}',
          if ((context.fateLine ?? '').trim().isNotEmpty)
            'Yön çizgisi (sembolik): ${context.fateLine}',
          if (context.symbols.isNotEmpty)
            'İzler: ${context.symbols.join(', ')}',
          if (context.themes.isNotEmpty)
            'Temalar: ${context.themes.join(', ')}',
          if ((context.takeaway ?? '').trim().isNotEmpty)
            'Öne çıkan işaret: ${context.takeaway}',
          if ((context.fullInterpretation ?? '').trim().isNotEmpty)
            context.fullInterpretation!,
          'Not: Sembolik yansıma — tıbbi veya tanısal yorum değildir.',
        ]);
    }
    return PromptSanitizer.sanitize(lines.join('\n\n'));
  }
}
