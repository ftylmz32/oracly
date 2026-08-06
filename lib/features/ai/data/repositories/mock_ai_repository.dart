/// OR-1110 — Mock core AI repository.
library;

import '../../domain/models/ai_conversation.dart';
import '../../domain/models/ai_message.dart';
import '../../domain/models/oracle_response.dart';
import '../../domain/repositories/ai_repository.dart';
import '../../services/conversation_memory.dart';
import '../../services/openai_service.dart';
import '../../services/prompt_builder.dart';
import '../../services/prompt_sanitizer.dart';
import '../mock/mock_ai_responses.dart';

class MockAIRepository implements AIRepository {
  MockAIRepository({
    ConversationMemory? memory,
    OpenAIService? openAI,
  })  : _memory = memory ?? ConversationMemory(),
        _openAI = openAI ?? MockOpenAIService();

  final ConversationMemory _memory;
  final OpenAIService _openAI;

  @override
  Future<List<AIConversation>> getConversations() async => _memory.all;

  @override
  Future<AIConversation?> getConversation(String id) async => _memory.get(id);

  @override
  Future<AIConversation> createConversation({
    required String title,
    required AIConversationKind kind,
    Map<String, String>? metadata,
  }) async {
    final now = DateTime.now();
    final conversation = AIConversation(
      id: 'conv_${now.millisecondsSinceEpoch}',
      title: title,
      kind: kind,
      messages: const [],
      createdAt: now,
      updatedAt: now,
      metadata: metadata ?? {},
    );
    return _memory.upsert(conversation);
  }

  @override
  Future<AIConversation> saveConversation(AIConversation conversation) async {
    return _memory.upsert(conversation);
  }

  @override
  Future<void> deleteConversation(String id) async => _memory.delete(id);

  @override
  Future<OracleResponse> sendMessage({
    required String conversationId,
    required String userMessage,
  }) async {
    if (!PromptSanitizer.isValid(userMessage)) {
      throw ArgumentError('Invalid message');
    }

    final userMsg = AIMessage(
      id: 'msg_u_${DateTime.now().millisecondsSinceEpoch}',
      role: AIMessageRole.user,
      content: PromptSanitizer.sanitize(userMessage),
      createdAt: DateTime.now(),
    );
    _memory.appendMessage(conversationId, userMsg);

    final prompt = PromptBuilder.general(userMessage: userMessage);
    final response = await _openAI.complete(prompt);
    _memory.appendMessage(conversationId, response.message);

    return response.copyWithFollowUps(MockAIResponses.suggestedFollowUps);
  }

  @override
  Stream<String> streamMessage({
    required String conversationId,
    required String userMessage,
  }) async* {
    final prompt = PromptBuilder.general(userMessage: userMessage);
    yield* _openAI.stream(prompt);
  }

  @override
  Future<OracleResponse> regenerateMessage({
    required String conversationId,
    required String messageId,
  }) async {
    final conv = _memory.get(conversationId);
    if (conv == null) throw StateError('Conversation not found');

    final idx = conv.messages.indexWhere((m) => m.id == messageId);
    if (idx <= 0) throw StateError('Cannot regenerate');

    final userMsg = conv.messages[idx - 1];
    final prompt = PromptBuilder.general(userMessage: userMsg.content);
    final response = await _openAI.complete(prompt);

    final regenerated = response.message.copyWith(
      status: AIMessageStatus.regenerated,
      parentMessageId: messageId,
    );
    _memory.replaceMessage(conversationId, messageId, regenerated);

    return response.copyWith(message: regenerated);
  }

  @override
  Future<OracleResponse> retryMessage({
    required String conversationId,
    required String messageId,
  }) async {
    return regenerateMessage(
      conversationId: conversationId,
      messageId: messageId,
    );
  }
}

extension on OracleResponse {
  OracleResponse copyWithFollowUps(List<String> followUps) {
    return OracleResponse(
      message: message,
      format: format,
      suggestedFollowUps: followUps,
      tokenUsage: tokenUsage,
      modelId: modelId,
      latencyMs: latencyMs,
    );
  }

  OracleResponse copyWith({AIMessage? message}) {
    return OracleResponse(
      message: message ?? this.message,
      format: format,
      suggestedFollowUps: suggestedFollowUps,
      tokenUsage: tokenUsage,
      modelId: modelId,
      latencyMs: latencyMs,
    );
  }
}
