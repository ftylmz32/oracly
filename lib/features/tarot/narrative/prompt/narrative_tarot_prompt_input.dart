import 'package:oracly_new/features/tarot/narrative/prompt/narrative_tarot_prompt_evidence_parts.dart';
import 'package:oracly_new/features/tarot/narrative/prompt/narrative_tarot_prompt_parts.dart';

/// Internal model-facing Narrative Tarot prompt DTO (not backend JSON).
class NarrativeTarotPromptInput {
  /// Explicit serializer contract version. Changing model-visible fields
  /// requires a serializer-version review — do not silently mutate.
  static const int kSerializerVersion = 1;

  final int narrativeTarotVersion;
  final int serializerVersion;
  final String languageCode;
  final NarrativePromptQuestion question;
  final NarrativePromptSpread spread;
  final List<NarrativePromptCard> cards;
  final List<NarrativePromptRelationship> relationships;
  final List<NarrativePromptRecurringCard> recurringCards;
  final List<NarrativePromptRecurringTheme> recurringThemes;
  final NarrativePromptMemory memory;
  final NarrativePromptPolicy policy;

  NarrativeTarotPromptInput({
    required this.narrativeTarotVersion,
    this.serializerVersion = kSerializerVersion,
    required this.languageCode,
    required this.question,
    required this.spread,
    required List<NarrativePromptCard> cards,
    required List<NarrativePromptRelationship> relationships,
    required List<NarrativePromptRecurringCard> recurringCards,
    required List<NarrativePromptRecurringTheme> recurringThemes,
    required this.memory,
    required this.policy,
  })  : cards = List<NarrativePromptCard>.unmodifiable(cards),
        relationships =
            List<NarrativePromptRelationship>.unmodifiable(relationships),
        recurringCards =
            List<NarrativePromptRecurringCard>.unmodifiable(recurringCards),
        recurringThemes =
            List<NarrativePromptRecurringTheme>.unmodifiable(recurringThemes);
}
