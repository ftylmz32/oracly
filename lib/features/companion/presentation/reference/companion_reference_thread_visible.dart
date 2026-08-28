/// Visible OR thread messages — filter + cheap signature for rebuild cache.
library;

import '../../../ai/domain/models/ai_message.dart';

String companionVisibleSignature(List<AIMessage> messages) {
  if (messages.isEmpty) return '0';
  return '${messages.length}:${messages.last.id}:'
      '${messages.first.id}:${messages.last.content.length}';
}

List<AIMessage> companionVisibleMessages(List<AIMessage> messages) => [
      for (final message in messages)
        if (message.content.trim().isNotEmpty &&
            !message.id.startsWith('welcome_'))
          message,
    ];
