/// Context Selection Engine — pick relevant buckets only.
library;

import '../../../core/personality/or_emotional_intelligence.dart';
import '../../../core/personality/or_natural_humor.dart';
import '../../ai/production/models/conversation_turn.dart';
import '../models/reflection_context.dart';
import 'companion_thread_digest.dart';
import 'companion_thread_memory.dart';
import 'or_adaptive_conversation.dart';
import 'or_context_bucket_helpers.dart';
import 'or_context_selection_sources.dart';
import 'or_selected_context.dart';

/// Assembles [OrSelectedContext] from sources without dumping archives.
abstract final class OrContextSelectionEngine {
  OrContextSelectionEngine._();

  static OrSelectedContext select({
    required String currentMessage,
    required List<ConversationTurn> recentMessages,
    List<ConversationTurn>? fullHistory,
    ReflectionContext? reflection,
    String? discoveryHint,
    String? featureHandoff,
  }) {
    final current = currentMessage.trim();
    final recent = ConversationTurn.takeRecent(recentMessages);
    final digest = CompanionThreadDigest.fromOlder(
      fullHistory ?? recentMessages,
    );
    final discovery =
        OrContextSelectionSources.discovery(discoveryHint, current, recent);
    final featureRaw =
        featureHandoff ?? reflection?.proactiveAcknowledgment;
    final feature = OrContextSelectionSources.feature(featureRaw);
    final memory = OrContextSelectionSources.memory(
      reflection: reflection,
      current: current,
      discoveryTaken: discovery != null,
      featureTaken: feature != null,
    );
    final facts = OrContextBucketHelpers.stableNameFact(
      reflection?.userName,
      current,
    );
    final preference =
        OrContextBucketHelpers.preferenceWhenAsked(current);
    final omitRecap = recent.any((t) => t.isUser);
    final thread = CompanionThreadMemory.read(recent, current).instructionFor(
      current,
      omitRecap: omitRecap,
    );
    final threadWithDigest = [
      ?digest,
      thread,
    ].join(' ').trim();
    return OrSelectedContext(
      currentMessage: current,
      recentMessages: recent,
      stableUserFacts: facts,
      recentDiscovery: discovery,
      relevantMemory: memory,
      featureSpecific: feature,
      preferenceHint: preference,
      emotionalGuidance: OrEmotionalIntelligence.styleHintFor(current),
      humorGuidance: OrNaturalHumor.styleHintFor(current),
      adaptiveGuidance: OrAdaptiveConversation.styleHintFor(
        current,
        turns: recent,
      ),
      threadGuidance: threadWithDigest,
    );
  }

  static String styleHint({
    required String currentMessage,
    required List<ConversationTurn> recentMessages,
    List<ConversationTurn>? fullHistory,
    ReflectionContext? reflection,
    String? discoveryHint,
    String? featureHandoff,
  }) =>
      select(
        currentMessage: currentMessage,
        recentMessages: recentMessages,
        fullHistory: fullHistory,
        reflection: reflection,
        discoveryHint: discoveryHint,
        featureHandoff: featureHandoff,
      ).toStyleHint();
}
