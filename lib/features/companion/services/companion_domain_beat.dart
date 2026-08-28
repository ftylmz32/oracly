/// Domain reading beats for OR local handoff - never keyword FAQ catalogs.
library;

import '../../../core/personality/or_response_depth.dart';
import '../data/companion_answer_copy.dart';
import '../data/companion_conversation_copy.dart';
import '../data/companion_intent.dart';
import '../models/insight_request.dart';

abstract final class CompanionDomainBeat {
  CompanionDomainBeat._();

  static String handoffOrListen(
    InsightRequest request,
    String? personality, {
    OrResponseDepth depth = OrResponseDepth.fallback,
  }) {
    final beat = resolve(request);
    if (beat == null) {
      return CompanionConversationCopy.listening(personality);
    }
    final shaped = depth == OrResponseDepth.short ||
            depth == OrResponseDepth.veryShort
        ? beat.split('\n\n').first
        : beat;
    return CompanionConversationCopy.colorDomain(
      shaped,
      personality,
      depth: depth,
    );
  }

  static String? resolve(InsightRequest request) {
    final lower = request.text.toLowerCase();
    if (lower.contains('kahve') ||
        lower.contains('fincan') ||
        lower.contains('coffee')) {
      return CompanionAnswerCopy.coffee;
    }
    if (lower.contains('tarot') ||
        lower.contains('kart') ||
        lower.contains('açılım')) {
      return CompanionAnswerCopy.tarot;
    }
    if (lower.contains('rüya') || lower.contains('dream')) {
      return CompanionAnswerCopy.dream;
    }
    if (lower.contains('aşk') ||
        lower.contains('ilişki') ||
        lower.contains('sevg')) {
      return CompanionAnswerCopy.love;
    }
    if (lower.contains('enerji') || lower.contains('energy')) {
      return CompanionAnswerCopy.energy;
    }
    return switch (request.kind) {
      InsightRequestKind.dream => CompanionAnswerCopy.dream,
      InsightRequestKind.tarot => CompanionAnswerCopy.tarot,
      InsightRequestKind.birthChart => CompanionAnswerCopy.astrology,
      InsightRequestKind.emotionalPattern => CompanionAnswerCopy.energy,
      _ => null,
    };
  }

  static String heldWithoutRepeat({
    required String topic,
    required String text,
    required String? personality,
    required String? lastAssistant,
  }) {
    if (CompanionIntent.isAdvice(text)) {
      return CompanionConversationCopy.continued(
        topic,
        text,
        personality,
        allowQuestion: true,
      );
    }
    final held = CompanionConversationCopy.heldTopic(topic, personality);
    final last = lastAssistant?.trim().toLowerCase() ?? '';
    if (last.isNotEmpty && held.trim().toLowerCase() == last) {
      return CompanionConversationCopy.continued(
        topic,
        text,
        personality,
        allowQuestion: true,
      );
    }
    return held;
  }
}
