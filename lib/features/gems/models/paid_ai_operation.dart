/// One paid AI attempt — stable id across retry, resume, and settle.
library;

enum PaidAiFeature { tarot, coffee, palm, dream, soulmate }

enum PaidAiOperationStatus {
  /// Confirmed by user; provider not yet successful.
  pending,

  /// Provider succeeded; gems not yet settled (or settle interrupted).
  providerOk,

  /// Gems deducted once for this operation.
  settled,

  /// Abandoned without charge (cancel / provider failure).
  abandoned,
}

class PaidAiOperation {
  const PaidAiOperation({
    required this.id,
    required this.feature,
    required this.ledgerKey,
    required this.reason,
    required this.cost,
    required this.status,
    required this.createdAtMs,
  });

  final String id;
  final PaidAiFeature feature;
  final String ledgerKey;
  final String reason;
  final int cost;
  final PaidAiOperationStatus status;
  final int createdAtMs;

  bool get isBillable => cost > 0;

  String get idempotencyKey => id;

  PaidAiOperation copyWith({PaidAiOperationStatus? status}) {
    return PaidAiOperation(
      id: id,
      feature: feature,
      ledgerKey: ledgerKey,
      reason: reason,
      cost: cost,
      status: status ?? this.status,
      createdAtMs: createdAtMs,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'feature': feature.name,
        'ledgerKey': ledgerKey,
        'reason': reason,
        'cost': cost,
        'status': status.name,
        'createdAtMs': createdAtMs,
      };

  factory PaidAiOperation.fromJson(Map<String, dynamic> json) {
    return PaidAiOperation(
      id: json['id'] as String? ?? '',
      feature: PaidAiFeature.values.firstWhere(
        (f) => f.name == json['feature'],
        orElse: () => PaidAiFeature.coffee,
      ),
      ledgerKey: json['ledgerKey'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      cost: json['cost'] as int? ?? 0,
      status: PaidAiOperationStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => PaidAiOperationStatus.abandoned,
      ),
      createdAtMs: json['createdAtMs'] as int? ?? 0,
    );
  }
}
