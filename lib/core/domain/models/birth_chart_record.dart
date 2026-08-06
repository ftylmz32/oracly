/// SPRINT-002 — Birth chart persistence record.
library;

class BirthChartRecord {
  const BirthChartRecord({
    required this.id,
    required this.createdAt,
    required this.payload,
    this.updatedAt,
  });

  final String id;
  final DateTime createdAt;
  final Map<String, dynamic> payload;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'payload': payload,
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      };

  factory BirthChartRecord.fromJson(Map<String, dynamic> json) {
    return BirthChartRecord(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      payload: json['payload'] as Map<String, dynamic>,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }
}
