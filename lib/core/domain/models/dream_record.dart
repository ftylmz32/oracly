/// OR-1130 — Dream journal record for API/sync.
library;

class DreamRecord {
  const DreamRecord({
    required this.id,
    required this.text,
    required this.analysis,
    required this.createdAt,
    this.updatedAt,
    this.emotions = const [],
    this.tags = const [],
    this.payload,
  });

  final String id;
  final String text;
  final String analysis;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> emotions;
  final List<String> tags;
  final Map<String, dynamic>? payload;

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'analysis': analysis,
        'createdAt': createdAt.toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
        'emotions': emotions,
        'tags': tags,
        if (payload != null) 'payload': payload,
      };

  factory DreamRecord.fromJson(Map<String, dynamic> json) {
    return DreamRecord(
      id: json['id'] as String,
      text: json['text'] as String,
      analysis: json['analysis'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      emotions: (json['emotions'] as List<dynamic>?)?.cast<String>() ?? const [],
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
      payload: json['payload'] as Map<String, dynamic>?,
    );
  }
}
