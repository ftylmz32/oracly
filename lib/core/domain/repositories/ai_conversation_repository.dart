/// OR-1130 — AI conversation repository interface.
library;

import '../models/conversation_record.dart';

abstract class AiConversationRepository {
  Future<List<ConversationRecord>> getAll();
  Future<ConversationRecord?> getById(String id);
  Future<void> save(ConversationRecord record);
  Future<void> delete(String id);
  Future<void> sync();
}
