/// Compact rolling companion turns — skip generic welcome.
library;

import '../../ai/domain/models/ai_message.dart';
import '../../ai/production/models/conversation_turn.dart';

abstract final class CompanionTurnWindow {
  CompanionTurnWindow._();

  /// Scan at most this many trailing messages before windowing.
  static const scanCap = ConversationTurn.maxWindow * 4;

  static List<ConversationTurn> history(List<AIMessage> messages) {
    final start =
        messages.length > scanCap ? messages.length - scanCap : 0;
    return [
      for (var i = start; i < messages.length; i++)
        if (messages[i].content.trim().isNotEmpty &&
            !messages[i].id.startsWith('welcome_'))
          ConversationTurn(
            role: messages[i].isUser
                ? ConversationTurn.userRole
                : ConversationTurn.assistantRole,
            text: messages[i].content.trim(),
          ),
    ];
  }

  static List<ConversationTurn> fromMessages(List<AIMessage> messages) {
    return ConversationTurn.takeRecent(history(messages));
  }

  static List<String> userTexts(List<ConversationTurn> turns) => [
        for (final turn in turns)
          if (turn.isUser) turn.text,
      ];
}
