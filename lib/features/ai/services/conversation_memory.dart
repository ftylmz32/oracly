/// OR-1110 — In-memory conversation history (API-ready persistence layer).
library;

import '../domain/models/ai_conversation.dart';
import '../domain/models/ai_message.dart';

class ConversationMemory {
  ConversationMemory();

  final Map<String, AIConversation> _store = {};

  List<AIConversation> get all =>
      _store.values.toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  AIConversation? get(String id) => _store[id];

  AIConversation upsert(AIConversation conversation) {
    _store[conversation.id] = conversation;
    return conversation;
  }

  AIConversation appendMessage(String conversationId, AIMessage message) {
    final existing = _store[conversationId];
    if (existing == null) {
      throw StateError('Conversation $conversationId not found');
    }
    final updated = existing.copyWith(
      messages: [...existing.messages, message],
      updatedAt: DateTime.now(),
    );
    _store[conversationId] = updated;
    return updated;
  }

  AIConversation replaceMessage(
    String conversationId,
    String messageId,
    AIMessage replacement,
  ) {
    final existing = _store[conversationId];
    if (existing == null) {
      throw StateError('Conversation $conversationId not found');
    }
    final messages = existing.messages
        .map((m) => m.id == messageId ? replacement : m)
        .toList();
    final updated = existing.copyWith(
      messages: messages,
      updatedAt: DateTime.now(),
    );
    _store[conversationId] = updated;
    return updated;
  }

  void delete(String id) => _store.remove(id);

  void clear() => _store.clear();

  /// OpenAI-compatible message history for API calls.
  List<Map<String, String>> toApiHistory(AIConversation conversation) {
    return conversation.messages
        .where((m) => m.role != AIMessageRole.system)
        .map((m) => {
              'role': m.role.name,
              'content': m.content,
            })
        .toList();
  }
}
