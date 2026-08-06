/// SPRINT-003 — Structured companion input (text or voice).
library;

import 'conversation.dart';

enum InsightRequestKind {
  openReflection,
  tarot,
  dream,
  birthChart,
  journal,
  goals,
  emotionalPattern,
  ritual,
}

class InsightRequest {
  const InsightRequest({
    required this.text,
    this.kind = InsightRequestKind.openReflection,
    this.conversationTopic = ConversationTopic.general,
    this.voiceTranscript = false,
  });

  final String text;
  final InsightRequestKind kind;
  final ConversationTopic conversationTopic;
  final bool voiceTranscript;

  Map<String, dynamic> toPayload() => {
        'text': text,
        'kind': kind.name,
        'topic': conversationTopic.name,
        'voiceTranscript': voiceTranscript,
      };
}
