/// OR-1110 — Single message in an AI conversation.
library;

enum AIMessageRole { user, assistant, system }

enum AIMessageStatus {
  sent,
  streaming,
  completed,
  error,
  regenerated,
}

/// Actions available on a completed assistant message.
enum AIMessageAction {
  copy,
  regenerate,
  retry,
  cite,
  share,
}

class AICitation {
  const AICitation({
    required this.label,
    required this.source,
    this.url,
  });

  final String label;
  final String source;
  final String? url;
}

class AIMessage {
  const AIMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.status = AIMessageStatus.completed,
    this.citations = const [],
    this.tokenCount,
    this.errorMessage,
    this.parentMessageId,
    this.metadata = const {},
  });

  final String id;
  final AIMessageRole role;
  final String content;
  final DateTime createdAt;
  final AIMessageStatus status;
  final List<AICitation> citations;
  final int? tokenCount;
  final String? errorMessage;
  final String? parentMessageId;
  final Map<String, String> metadata;

  bool get isUser => role == AIMessageRole.user;
  bool get isAssistant => role == AIMessageRole.assistant;
  bool get isStreaming => status == AIMessageStatus.streaming;
  bool get hasError => status == AIMessageStatus.error;

  AIMessage copyWith({
    String? content,
    AIMessageStatus? status,
    List<AICitation>? citations,
    int? tokenCount,
    String? errorMessage,
    String? parentMessageId,
    Map<String, String>? metadata,
  }) {
    return AIMessage(
      id: id,
      role: role,
      content: content ?? this.content,
      createdAt: createdAt,
      status: status ?? this.status,
      citations: citations ?? this.citations,
      tokenCount: tokenCount ?? this.tokenCount,
      errorMessage: errorMessage ?? this.errorMessage,
      parentMessageId: parentMessageId ?? this.parentMessageId,
      metadata: metadata ?? this.metadata,
    );
  }
}
