/// OR smart revisit — resolves from real history when topics align.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../features/ai/domain/models/ai_message.dart';
import '../../../features/companion/providers/companion_providers.dart';
import '../../../features/companion/services/companion_thread_topics.dart';
import '../../../features/tarot/revisit/tarot_revisit_context.dart';
import '../../../features/tarot/revisit/tarot_revisit_service.dart';

final discoveryRevisitDismissedIdProvider = StateProvider<String?>(
  (ref) => null,
);

final discoveryRevisitOfferProvider = Provider<TarotRevisitContext?>((ref) {
  final dismissed = ref.watch(discoveryRevisitDismissedIdProvider);
  final readings = ref.watch(readingHistoryProvider).valueOrNull ?? const [];
  final messages =
      ref.watch(companionControllerProvider).state.conversation?.messages ??
          const [];
  final topic = _conversationTopic(messages);
  final offer = TarotRevisitService.forConversation(
    conversationTopic: topic,
    readings: readings,
  );
  if (offer == null) return null;
  if (dismissed == offer.reading.id) return null;
  return offer;
});

String? _conversationTopic(List<AIMessage> messages) {
  String? held;
  for (var i = messages.length - 1; i >= 0; i--) {
    final message = messages[i];
    if (!message.isUser) continue;
    final topic = CompanionThreadTopics.of(message.content);
    if (topic != null && !CompanionThreadTopics.isVague(topic)) {
      held = topic;
    }
    if (topic == 'iş' || topic == 'ilişki') return topic;
  }
  return held;
}
