/// SPRINT-003 — Maps between companion and persistence models.
library;

import '../../../core/domain/models/conversation_record.dart';
import '../../../features/ai/domain/models/ai_conversation.dart';
import '../../../features/ai/domain/models/ai_message.dart';
import '../debug/or_runtime_log.dart';
import '../models/conversation.dart';

abstract final class CompanionRecordMapper {
  CompanionRecordMapper._();

  static ConversationRecord toRecord(Conversation conversation) {
    return ConversationRecord(
      id: conversation.id,
      title: conversation.title,
      kind: conversation.topic.name,
      messagesJson: conversation.messages.map(_messageToJson).toList(),
      createdAt: conversation.createdAt,
      updatedAt: conversation.updatedAt,
    );
  }

  static Conversation fromRecord(ConversationRecord record) {
    ConversationTopic topic;
    try {
      topic = ConversationTopic.values.byName(record.kind);
    } catch (_) {
      topic = ConversationTopic.general;
    }
    final messages = <AIMessage>[];
    for (final raw in record.messagesJson) {
      final message = _tryMessageFromJson(raw);
      if (message != null) {
        messages.add(message);
      } else {
        logOrCorruptRow(reason: 'message_parse');
      }
    }
    return Conversation(
      id: record.id,
      title: record.title,
      topic: topic,
      messages: messages,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
    );
  }

  static AIConversation toAiConversation(Conversation conversation) {
    return AIConversation(
      id: conversation.id,
      title: conversation.title,
      kind: AIConversationKind.general,
      messages: conversation.messages,
      createdAt: conversation.createdAt,
      updatedAt: conversation.updatedAt,
      metadata: conversation.metadata,
    );
  }

  static Map<String, dynamic> _messageToJson(AIMessage message) {
    return {
      'id': message.id,
      'role': message.role.name,
      'content': message.content,
      'createdAt': message.createdAt.toIso8601String(),
      'status': message.status.name,
      if (message.metadata.isNotEmpty) 'metadata': message.metadata,
    };
  }

  static AIMessage _messageFromJson(Map<String, dynamic> json) {
    return AIMessage(
      id: json['id'] as String,
      role: AIMessageRole.values.byName(json['role'] as String),
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: AIMessageStatus.values.byName(
        json['status'] as String? ?? AIMessageStatus.completed.name,
      ),
      metadata: _metadata(json['metadata']),
    );
  }

  static AIMessage? _tryMessageFromJson(Map<String, dynamic> json) {
    try {
      return _messageFromJson(json);
    } catch (_) {
      return null;
    }
  }

  static Map<String, String> _metadata(Object? raw) {
    if (raw is! Map) return const {};
    return {
      for (final entry in raw.entries)
        entry.key.toString(): entry.value.toString(),
    };
  }
}
