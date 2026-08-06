/// OR-1190 — Oracle conversation repository with reading context.
library;

import '../../domain/models/ai_conversation.dart';
import '../../domain/models/ai_message.dart';
import '../../domain/models/oracle_response.dart';
import '../../services/conversation_memory.dart';
import '../models/oracle_reading_context.dart';
import '../services/oracle_conversation_responder.dart'
    show OracleConversationResponder, OracleConversationSuggestions;

abstract interface class OracleConversationRepository {
  Future<AIConversation> startConversation(OracleReadingContext context);
  Future<AIConversation?> getConversation(String id);
  Future<OracleResponse> sendMessage({
    required String conversationId,
    required String userMessage,
    required OracleReadingContext context,
  });
  Stream<String> streamMessage({
    required String conversationId,
    required String userMessage,
    required OracleReadingContext context,
  });
  Future<OracleResponse> regenerateMessage({
    required String conversationId,
    required String messageId,
    required OracleReadingContext context,
  });
}

class MockOracleConversationRepository implements OracleConversationRepository {
  MockOracleConversationRepository({
    ConversationMemory? memory,
    OracleConversationResponder? responder,
  })  : _memory = memory ?? ConversationMemory(),
        _responder = responder ?? const OracleConversationResponder();

  final ConversationMemory _memory;
  final OracleConversationResponder _responder;

  OracleReadingContext? _activeContext;

  @override
  Future<AIConversation> startConversation(OracleReadingContext context) async {
    _activeContext = context;
    final now = DateTime.now();
    final conversation = AIConversation(
      id: 'oracle_${context.sessionId}_${now.millisecondsSinceEpoch}',
      title: context.readingTitle,
      kind: AIConversationKind.tarot,
      messages: const [],
      createdAt: now,
      updatedAt: now,
      metadata: context.toMetadata(),
    );
    return _memory.upsert(conversation);
  }

  @override
  Future<AIConversation?> getConversation(String id) async =>
      _memory.get(id);

  @override
  Future<OracleResponse> sendMessage({
    required String conversationId,
    required String userMessage,
    required OracleReadingContext context,
  }) async {
    _activeContext = context;
    final userMsg = AIMessage(
      id: 'msg_u_${DateTime.now().millisecondsSinceEpoch}',
      role: AIMessageRole.user,
      content: userMessage.trim(),
      createdAt: DateTime.now(),
    );
    _memory.appendMessage(conversationId, userMsg);

    final text = await _responder.respond(
      context: context,
      userMessage: userMessage,
    );

    final assistant = AIMessage(
      id: 'msg_a_${DateTime.now().millisecondsSinceEpoch}',
      role: AIMessageRole.assistant,
      content: text,
      createdAt: DateTime.now(),
      status: AIMessageStatus.completed,
      tokenCount: text.length ~/ 4,
    );
    _memory.appendMessage(conversationId, assistant);

    return OracleResponse(
      message: assistant,
      format: OracleResponseFormat.markdown,
      suggestedFollowUps: OracleConversationSuggestions.chips,
      tokenUsage: assistant.tokenCount ?? 0,
      modelId: 'or-local',
      latencyMs: 520,
    );
  }

  @override
  Stream<String> streamMessage({
    required String conversationId,
    required String userMessage,
    required OracleReadingContext context,
  }) {
    _activeContext = context;
    final userMsg = AIMessage(
      id: 'msg_u_${DateTime.now().millisecondsSinceEpoch}',
      role: AIMessageRole.user,
      content: userMessage.trim(),
      createdAt: DateTime.now(),
    );
    _memory.appendMessage(conversationId, userMsg);

    return _responder.respondStream(
      context: context,
      userMessage: userMessage,
    );
  }

  @override
  Future<OracleResponse> regenerateMessage({
    required String conversationId,
    required String messageId,
    required OracleReadingContext context,
  }) async {
    final conv = _memory.get(conversationId);
    if (conv == null) throw StateError('Conversation not found');

    final idx = conv.messages.indexWhere((m) => m.id == messageId);
    if (idx <= 0) throw StateError('Cannot regenerate');

    final userMsg = conv.messages[idx - 1];
    final text = await _responder.respond(
      context: context,
      userMessage: userMsg.content,
    );

    final regenerated = AIMessage(
      id: 'msg_a_${DateTime.now().millisecondsSinceEpoch}',
      role: AIMessageRole.assistant,
      content: text,
      createdAt: DateTime.now(),
      status: AIMessageStatus.regenerated,
      parentMessageId: messageId,
      tokenCount: text.length ~/ 4,
    );
    _memory.replaceMessage(conversationId, messageId, regenerated);

    return OracleResponse(
      message: regenerated,
      format: OracleResponseFormat.markdown,
      suggestedFollowUps: OracleConversationSuggestions.chips,
      tokenUsage: regenerated.tokenCount ?? 0,
      modelId: 'or-local',
      latencyMs: 520,
    );
  }

  OracleReadingContext? get activeContext => _activeContext;
}
