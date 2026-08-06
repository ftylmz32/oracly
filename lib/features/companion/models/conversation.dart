/// SPRINT-003 — Companion conversation thread.
library;

import '../../../features/ai/domain/models/ai_message.dart';

enum ConversationTopic {
  general,
  tarot,
  dream,
  birthChart,
  journal,
  goals,
  reflection,
  ritual,
}

class Conversation {
  const Conversation({
    required this.id,
    required this.title,
    required this.topic,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
  });

  final String id;
  final String title;
  final ConversationTopic topic;
  final List<AIMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, String> metadata;

  Conversation copyWith({
    List<AIMessage>? messages,
    DateTime? updatedAt,
    Map<String, String>? metadata,
  }) {
    return Conversation(
      id: id,
      title: title,
      topic: topic,
      messages: messages ?? this.messages,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  AIMessage? get lastMessage => messages.isEmpty ? null : messages.last;
}
