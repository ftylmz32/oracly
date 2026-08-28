/// Routes one turn - safety, continuity, directness; never topic FAQs.
library;

import '../../../core/l10n/l10n.dart';
import '../../../core/personality/or_explanation_mode.dart';
import '../../../core/personality/or_response_depth.dart';
import '../../../core/safety/sensitive_topic_gate.dart';
import '../data/companion_answer_copy.dart';
import '../data/companion_conversation_copy.dart';
import '../data/companion_directness.dart';
import '../data/companion_intent.dart';
import '../data/companion_mood_copy.dart';
import '../models/insight_request.dart';
import '../models/reflection_context.dart';
import 'companion_domain_beat.dart';
import 'companion_thread_memory.dart';
import 'or_context_bucket_helpers.dart';
import 'contextual_followup_policy.dart';

abstract final class CompanionTurnRouter {
  CompanionTurnRouter._();

  static String answer({
    required String lower,
    required InsightRequest request,
    required ReflectionContext context,
    required CompanionThreadMemory thread,
    required String? personality,
    required bool hasHistory,
    OrResponseDepth depth = OrResponseDepth.fallback,
  }) {
    final safety = SensitiveTopicGate.maybeRespond(request.text);
    if (safety != null) return safety;
    if (CompanionIntent.isPrediction(request.text)) {
      return OraclyL10n.t('or.predict');
    }
    if (lower.contains('hatırl') ||
        lower.contains('hatirl') ||
        lower.contains('daha önce') ||
        lower.contains('daha once') ||
        lower.contains('remember')) {
      final note = OrContextBucketHelpers.relevantSaved(
        context.savedMemories,
        request.text,
      );
      if (note != null) return CompanionAnswerCopy.memory(note);
      return OraclyL10n.t('or.answer.memory_none');
    }
    if (OrExplanationMode.parseShape(request.text) != null && hasHistory) {
      final topic = thread.topic ?? 'konu';
      return CompanionConversationCopy.reflect(topic, personality);
    }
    if (CompanionConversationCopy.looksGreeting(request.text)) {
      if (hasHistory && thread.topic != null) {
        return CompanionConversationCopy.resumeAfterInterrupt(
          thread.topic!,
          personality,
        );
      }
      return hasHistory
          ? CompanionConversationCopy.greetingAgain(personality)
          : CompanionConversationCopy.greeting(personality);
    }
    if (thread.resuming && thread.topic != null) {
      return CompanionConversationCopy.reflect(thread.topic!, personality);
    }
    // Domain readings beat mood openers - bagla must not steal coffee.
    if (CompanionMoodCopy.looksLow(request.text) &&
        !thread.continuing &&
        CompanionDomainBeat.resolve(request) == null) {
      return CompanionMoodCopy.openUp(personality);
    }
    final direct = CompanionDirectness.detect(request.text);
    final directLine = CompanionDirectness.line(direct);
    if (directLine != null) return directLine;
    if (thread.answeringPrompt && thread.topic != null) {
      return CompanionDomainBeat.heldWithoutRepeat(
        topic: thread.topic!,
        text: request.text,
        personality: personality,
        lastAssistant: thread.lastAssistant,
      );
    }
    if (thread.switched && request.text.trim().length > 56) {
      return handoffOrListen(request, personality, depth: depth);
    }
    if (thread.switched) {
      return CompanionConversationCopy.switched(personality);
    }
    if (CompanionConversationCopy.looksUndecided(request.text) &&
        thread.topic != 'iş') {
      return CompanionConversationCopy.undecided(personality);
    }
    if (hasHistory && thread.continuing && thread.topic != null) {
      final followUp = ContextualFollowUpPolicy.evaluate(
        userMessage: request.text,
        thread: thread,
      );
      return switch (followUp.localKind) {
        FollowUpLocalKind.fearClarify =>
          CompanionConversationCopy.fearClarify(thread.topic!, personality),
        FollowUpLocalKind.reflectOnly =>
          CompanionConversationCopy.reflect(thread.topic!, personality),
        _ => CompanionConversationCopy.continued(
            thread.topic!,
            request.text,
            personality,
            allowQuestion: followUp.allowTrailingQuestion,
          ),
      };
    }
    // Short follow-up with held topic even when not yet "continuing".
    if (hasHistory &&
        CompanionIntent.isShortFollowUp(request.text) &&
        thread.topic != null) {
      return CompanionConversationCopy.reflect(thread.topic!, personality);
    }
    return handoffOrListen(request, personality, depth: depth);
  }

  /// Real reading handoff kinds only - never keyword FAQ catalogs.
  static String handoffOrListen(
    InsightRequest request,
    String? personality, {
    OrResponseDepth depth = OrResponseDepth.fallback,
  }) =>
      CompanionDomainBeat.handoffOrListen(
        request,
        personality,
        depth: depth,
      );
}
