/// Outcome of one OR turn — generation and persistence are separate.
library;

import '../../ai/domain/models/ai_message.dart';
import 'companion_response.dart';
import 'conversation.dart';

class CompanionSendResult {
  const CompanionSendResult({
    required this.conversation,
    required this.response,
    required this.fromAi,
    this.persisted = true,
  });

  final Conversation conversation;
  final CompanionResponse response;
  final bool fromAi;

  /// False when a valid reply exists but local save failed.
  final bool persisted;

  AIMessage? get assistantMessage {
    final last = conversation.lastMessage;
    return last != null && last.isAssistant ? last : null;
  }
}
