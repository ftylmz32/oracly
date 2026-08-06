/// OR-1130 — AI conversation record for API/sync.
library;

class ConversationRecord {
  const ConversationRecord({
    required this.id,
    required this.title,
    required this.kind,
    required this.messagesJson,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String kind;
  final List<Map<String, dynamic>> messagesJson;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'kind': kind,
        'messages': messagesJson,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory ConversationRecord.fromJson(Map<String, dynamic> json) {
    return ConversationRecord(
      id: json['id'] as String,
      title: json['title'] as String,
      kind: json['kind'] as String,
      messagesJson: (json['messages'] as List<dynamic>)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
