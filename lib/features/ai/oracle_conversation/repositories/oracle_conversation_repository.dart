/// OR-1190 — Oracle conversation repository with reading context.
library;

import '../../../../core/copy/ai_source_copy.dart';
import '../../domain/models/ai_conversation.dart';
import '../../domain/models/ai_message.dart';
import '../../domain/models/oracle_response.dart';
import '../../services/conversation_memory.dart';
import '../models/oracle_reading_context.dart';
import '../services/oracle_ai_message_source.dart';
import '../services/oracle_conversation_responder.dart'
    show OracleConversationResponder, OracleConversationSuggestions;

abstract interface class OracleConversationRepository {
  Future<AIConversation> startConversation(OracleReadingContext context);
  Future<AIConversation?> getConversation(String id);
  Future<OracleResponse> sendMessage({
    required String conversationId,
    required String userMessage,
    required OracleReadingContext context,
    List<String> priorUser = const [],
  });
  Stream<String> streamMessage({
    required String conversationId,
    required String userMessage,
    required OracleReadingContext context,
    List<String> priorUser = const [],
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
    OracleAiMessageSource? source,
  })  : _memory = memory ?? ConversationMemory(),
        _source = source ??
            OracleAiMessageSource(
              local: responder ?? const OracleConversationResponder(),
            );

  final ConversationMemory _memory;
  final OracleAiMessageSource _source;

  OracleReadingContext? _activeContext;

  @override
  Future<AIConversation> startConversation(OracleReadingContext context) async {
    _activeContext = context;
    final now = DateTime.now();
    final conversation = AIConversation(
      id: 'oracle_${context.sessionId}_${now.millisecondsSinceEpoch}',
      title: context.readingTitle,
      kind: _kindFor(context),
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
    List<String> priorUser = const [],
  }) async {
    _activeContext = context;
    final userMsg = AIMessage(
      id: 'msg_u_${DateTime.now().millisecondsSinceEpoch}',
      role: AIMessageRole.user,
      content: userMessage.trim(),
      createdAt: DateTime.now(),
    );
    _memory.appendMessage(conversationId, userMsg);

    final text = await _source.reply(
      context: context,
      userMessage: userMessage,
      priorUser: priorUser,
    );

    final assistant = AIMessage(
      id: 'msg_a_${DateTime.now().millisecondsSinceEpoch}',
      role: AIMessageRole.assistant,
      content: text,
      createdAt: DateTime.now(),
      status: AIMessageStatus.completed,
      tokenCount: text.length ~/ 4,
      metadata: AiSourceCopy.tag(fromAi: _source.fromAi),
    );
    _memory.appendMessage(conversationId, assistant);

    return OracleResponse(
      message: assistant,
      format: OracleResponseFormat.markdown,
      suggestedFollowUps: OracleConversationSuggestions.chips,
      tokenUsage: assistant.tokenCount ?? 0,
      modelId: _source.fromAi ? 'or-live' : 'or-local',
      latencyMs: 520,
    );
  }

  @override
  Stream<String> streamMessage({
    required String conversationId,
    required String userMessage,
    required OracleReadingContext context,
    List<String> priorUser = const [],
  }) {
    _activeContext = context;
    final userMsg = AIMessage(
      id: 'msg_u_${DateTime.now().millisecondsSinceEpoch}',
      role: AIMessageRole.user,
      content: userMessage.trim(),
      createdAt: DateTime.now(),
    );
    _memory.appendMessage(conversationId, userMsg);

    return _source.stream(
      context: context,
      userMessage: userMessage,
      priorUser: priorUser,
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
    final priorUser = conv.messages
        .where((m) => m.isUser && m.id != userMsg.id)
        .map((m) => m.content)
        .toList();
    final text = await _source.reply(
      context: context,
      userMessage: userMsg.content,
      priorUser: priorUser,
    );

    final regenerated = AIMessage(
      id: 'msg_a_${DateTime.now().millisecondsSinceEpoch}',
      role: AIMessageRole.assistant,
      content: text,
      createdAt: DateTime.now(),
      status: AIMessageStatus.regenerated,
      parentMessageId: messageId,
      tokenCount: text.length ~/ 4,
      metadata: AiSourceCopy.tag(fromAi: _source.fromAi),
    );
    _memory.replaceMessage(conversationId, messageId, regenerated);

    return OracleResponse(
      message: regenerated,
      format: OracleResponseFormat.markdown,
      suggestedFollowUps: OracleConversationSuggestions.chips,
      tokenUsage: regenerated.tokenCount ?? 0,
      modelId: _source.fromAi ? 'or-live' : 'or-local',
      latencyMs: 520,
    );
  }

  OracleReadingContext? get activeContext => _activeContext;

  static AIConversationKind _kindFor(OracleReadingContext context) {
    return switch (context.kind) {
      OracleReadingKind.tarot => AIConversationKind.tarot,
      OracleReadingKind.dream => AIConversationKind.dream,
      OracleReadingKind.astrology ||
      OracleReadingKind.birthChart ||
      OracleReadingKind.starMap ||
      OracleReadingKind.dailyMessage ||
      OracleReadingKind.discoveryJournal ||
      OracleReadingKind.soulMate =>
        AIConversationKind.astrology,
      OracleReadingKind.coffee ||
      OracleReadingKind.palm =>
        AIConversationKind.coffee,
    };
  }
}
