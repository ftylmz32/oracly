/// Loads or starts the primary companion session — persist via repository.
library;

import '../../../core/domain/repositories/ai_conversation_repository.dart';
import '../../../features/ai/domain/models/ai_message.dart';
import '../data/companion_record_mapper.dart';
import '../models/conversation.dart';
import '../models/reflection_context.dart';
import 'companion_context_builder.dart';

abstract final class CompanionSessionBootstrap {
  CompanionSessionBootstrap._();

  static const sessionId = 'companion_primary';

  static Future<({Conversation conversation, ReflectionContext context})>
      loadOrCreate({
    required AiConversationRepository conversations,
    required CompanionContextBuilder contextBuilder,
  }) {
    return _open(
      conversations: conversations,
      contextBuilder: contextBuilder,
    ).timeout(const Duration(seconds: 12));
  }

  static Future<({Conversation conversation, ReflectionContext context})>
      _open({
    required AiConversationRepository conversations,
    required CompanionContextBuilder contextBuilder,
  }) async {
    final context = await contextBuilder.build();
    final existing = await conversations.getById(sessionId);

    if (existing != null) {
      final conversation = CompanionRecordMapper.fromRecord(existing);
      if (conversation.messages.any((m) => m.isUser)) {
        return (conversation: conversation, context: context);
      }
    }

    final welcome = contextBuilder.welcomeMessage(context);
    final now = DateTime.now();
    final conversation = Conversation(
      id: sessionId,
      title: 'OR Companion',
      topic: ConversationTopic.general,
      messages: [
        AIMessage(
          id: 'welcome_${now.millisecondsSinceEpoch}',
          role: AIMessageRole.assistant,
          content: welcome,
          createdAt: now,
        ),
      ],
      createdAt: now,
      updatedAt: now,
    );
    await conversations.save(CompanionRecordMapper.toRecord(conversation));
    return (conversation: conversation, context: context);
  }
}
