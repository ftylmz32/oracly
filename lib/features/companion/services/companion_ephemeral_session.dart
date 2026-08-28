/// Ephemeral OR session when persistence bootstrap fails.
library;

import '../../ai/domain/models/ai_message.dart';
import '../copy/companion_copy.dart';
import '../models/conversation.dart';

abstract final class CompanionEphemeralSession {
  CompanionEphemeralSession._();

  static Conversation welcome() {
    final now = DateTime.now();
    return Conversation(
      id: 'companion_ephemeral',
      title: 'OR Companion',
      topic: ConversationTopic.general,
      messages: [
        AIMessage(
          id: 'welcome_ephemeral_${now.millisecondsSinceEpoch}',
          role: AIMessageRole.assistant,
          content: CompanionCopy.welcomeLine(),
          createdAt: now,
        ),
      ],
      createdAt: now,
      updatedAt: now,
    );
  }
}
