/// OR-1110 — Core AI repository interface.
library;

import '../models/ai_conversation.dart';
import '../models/oracle_response.dart';

abstract class AIRepository {
  Future<List<AIConversation>> getConversations();
  Future<AIConversation?> getConversation(String id);
  Future<AIConversation> createConversation({
    required String title,
    required AIConversationKind kind,
    Map<String, String>? metadata,
  });
  Future<AIConversation> saveConversation(AIConversation conversation);
  Future<void> deleteConversation(String id);

  Future<OracleResponse> sendMessage({
    required String conversationId,
    required String userMessage,
  });

  Stream<String> streamMessage({
    required String conversationId,
    required String userMessage,
  });

  Future<OracleResponse> regenerateMessage({
    required String conversationId,
    required String messageId,
  });

  Future<OracleResponse> retryMessage({
    required String conversationId,
    required String messageId,
  });
}
