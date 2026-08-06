/// SPRINT-001 — Relationship presence in a dream narrative.
library;

class DreamRelationship {
  const DreamRelationship({
    required this.label,
    this.role,
    this.emotionalTone,
  });

  final String label;
  final String? role;
  final String? emotionalTone;

  Map<String, dynamic> toJson() => {
        'label': label,
        if (role != null) 'role': role,
        if (emotionalTone != null) 'emotionalTone': emotionalTone,
      };

  factory DreamRelationship.fromJson(Map<String, dynamic> json) {
    return DreamRelationship(
      label: json['label'] as String,
      role: json['role'] as String?,
      emotionalTone: json['emotionalTone'] as String?,
    );
  }
}
