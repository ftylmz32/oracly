/// SPRINT-003 — User memory the companion may reference.
library;

import 'memory_permission.dart';

class Memory {
  const Memory({
    required this.id,
    required this.content,
    required this.category,
    required this.permission,
    required this.createdAt,
    this.updatedAt,
    this.source = MemorySource.user,
  });

  final String id;
  final String content;
  final String category;
  final MemoryPermission permission;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final MemorySource source;

  bool get isSaved => permission == MemoryPermission.saved;

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'category': category,
        'permission': permission.name,
        'createdAt': createdAt.toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
        'source': source.name,
      };

  factory Memory.fromJson(Map<String, dynamic> json) {
    return Memory(
      id: json['id'] as String,
      content: json['content'] as String,
      category: json['category'] as String? ?? 'general',
      permission: MemoryPermission.values.byName(
        json['permission'] as String? ?? MemoryPermission.saved.name,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      source: MemorySource.values.byName(
        json['source'] as String? ?? MemorySource.user.name,
      ),
    );
  }

  Memory copyWith({
    String? content,
    String? category,
    MemoryPermission? permission,
    DateTime? updatedAt,
  }) {
    return Memory(
      id: id,
      content: content ?? this.content,
      category: category ?? this.category,
      permission: permission ?? this.permission,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      source: source,
    );
  }
}

enum MemorySource {
  user,
  journal,
  reading,
  dream,
  birthChart,
}
