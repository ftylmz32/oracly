/// OR-1180 — PromptEngine adapter for tarot interpretation.
library;

import '../../../insights/models/journey_personalization_hints.dart';
import '../../../prompt_engine/builders/prompt_inputs.dart';
import '../../../prompt_engine/core/prompt_engine.dart';
import '../../../prompt_engine/models/prompt_context.dart';
import '../../../prompt_engine/models/prompt_request.dart';
import '../../../../core/personality/or_personality.dart';
import '../../../../features/premium/models/personalization_models.dart';
import '../../copy/tarot_l10n.dart';
import '../../copy/tarot_polish_copy.dart';
import '../../reading/reading_ask.dart';
import '../models/interpretation_request.dart';
import '../models/reading_context.dart';

class InterpretationPromptAdapter {
  InterpretationPromptAdapter({PromptEngine? promptEngine})
      : _promptEngine = promptEngine ?? PromptEngine();

  final PromptEngine _promptEngine;

  PromptRequest buildPrompt(
    ReadingContext context, {
    AiPersonality personality = AiPersonality.mystical,
  }) {
    final cardsSummary = _buildCardsSummary(context);
    final reversed = context.cards.where((c) => c.isReversed).toList();

    final input = TarotPromptInput(
      spreadType: context.spreadLabel,
      intention: context.userQuestion ?? TarotL10n.genericGuidance,
      cardsSummary: cardsSummary,
      reversedSummary: reversed.isEmpty
          ? null
          : reversed
              .map(
                (c) =>
                    '${c.positionLabel}: ${c.cardName} (${TarotPolishCopy.reversed})',
              )
              .join('\n'),
      cardIds: context.cards.map((c) => c.cardId).toList(),
    );

    final promptContext = PromptContext(
      locale: context.language,
      personality: OrPersonality.promptPersonality(personality),
      sessionId: context.sessionId,
      facts: {
        'readingDate': _formatDate(context.readingDate),
        'deckId': context.deckId,
        'readingPipeline':
            'question,positions,identities,orientation,meanings,cardRelations,'
            'positionRelations,userContext,story,guidance',
        'questionKind': ReadingAsk.kind(context.userQuestion).name,
        'cardCount': '${context.cards.length}',
        if (context.readingTheme != null) 'readingTheme': context.readingTheme,
        ..._journeyFacts(context.journeyHints),
      },
    );

    return _promptEngine.assembly.buildTarot(
      input: input,
      context: promptContext,
    );
  }

  InterpretationRequest attachPrompt(
    InterpretationRequest request, {
    AiPersonality personality = AiPersonality.mystical,
  }) {
    return request.copyWith(
      promptRequest: buildPrompt(request.context, personality: personality),
    );
  }

  String _buildCardsSummary(ReadingContext context) {
    final buffer = StringBuffer();
    for (final card in context.cards) {
      buffer.writeln(
        '${card.positionLabel}: ${card.cardName} (${card.orientationLabel})',
      );
      buffer.writeln('- ${card.effectiveMeaning}');
      if (card.keywords.isNotEmpty) {
        buffer.writeln('- ${TarotPolishCopy.keysPrefix} ${card.keywords.join(", ")}');
      }
      buffer.writeln();
    }
    return buffer.toString().trim();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, "0")}.'
        '${date.month.toString().padLeft(2, "0")}.'
        '${date.year}';
  }

  Map<String, String> _journeyFacts(JourneyPersonalizationHints? hints) {
    if (hints == null || hints.isEmpty) return const {};
    final preface = hints.observationalPreface();
    return {
      'journeyObservation': ?preface,
      if (hints.recurringThemeLabels.isNotEmpty)
        'recurringThemes': hints.recurringThemeLabels.join(', '),
      if (hints.priorReadingCount > 0)
        'priorReadingCount': '${hints.priorReadingCount}',
      if (hints.priorOpenings.isNotEmpty)
        'avoidRepeatedWording': hints.priorOpenings.join(' || '),
      if (hints.revisitPriorExcerpt != null &&
          hints.revisitPriorExcerpt!.trim().isNotEmpty)
        'priorReadingExcerpt': hints.revisitPriorExcerpt!.trim(),
      if (hints.revisitInstruction != null &&
          hints.revisitInstruction!.trim().isNotEmpty)
        'revisitInstruction': hints.revisitInstruction!.trim(),
    };
  }
}
