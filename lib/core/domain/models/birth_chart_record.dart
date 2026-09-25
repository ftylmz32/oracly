/// SPRINT-002 — Birth chart persistence record (+ Phase 3 ownerId).
library;

class BirthChartRecord {
  const BirthChartRecord({
    required this.id,
    required this.createdAt,
    required this.payload,
    this.updatedAt,
    this.ownerId,
  });

  final String id;
  final DateTime createdAt;
  final Map<String, dynamic> payload;
  final DateTime? updatedAt;

  /// Canonical local-data owner (`or_local_data_owner_uid` value).
  final String? ownerId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'payload': payload,
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
        if (ownerId != null) 'ownerId': ownerId,
      };

  factory BirthChartRecord.fromJson(Map<String, dynamic> json) {
    return BirthChartRecord(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      payload: Map<String, dynamic>.from(json['payload'] as Map),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      ownerId: json['ownerId'] as String?,
    );
  }

  BirthChartRecord copyWith({String? ownerId}) => BirthChartRecord(
        id: id,
        createdAt: createdAt,
        payload: payload,
        updatedAt: updatedAt,
        ownerId: ownerId ?? this.ownerId,
      );
}
