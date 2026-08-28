/// OR-1110 — AI conversation thread model.
library;

import 'ai_message.dart';

enum AIConversationKind {
  general,
  tarot,
  dream,
  astrology,
  dailyEnergy,
  coffee,
}

/// A full conversation thread between user and OR Oracle.
class AIConversation {
  const AIConversation({
    required this.id,
    required this.title,
    required this.kind,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
  });

  final String id;
  final String title;
  final AIConversationKind kind;
  final List<AIMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, String> metadata;

  AIConversation copyWith({
    String? title,
    List<AIMessage>? messages,
    DateTime? updatedAt,
    Map<String, String>? metadata,
  }) {
    return AIConversation(
      id: id,
      title: title ?? this.title,
      kind: kind,
      messages: messages ?? this.messages,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  AIMessage? get lastMessage =>
      messages.isEmpty ? null : messages.last;

  int get messageCount => messages.length;
}
