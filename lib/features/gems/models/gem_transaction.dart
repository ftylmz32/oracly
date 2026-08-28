/// One earned or spent gem movement.
library;

enum GemTransactionType { earned, spent }

class GemTransaction {
  const GemTransaction({
    required this.id,
    required this.createdAt,
    required this.amount,
    required this.reason,
    required this.type,
  });

  final String id;
  final DateTime createdAt;
  final int amount;
  final String reason;
  final GemTransactionType type;

  String get displayLine {
    final sign = amount > 0 ? '+' : '';
    return '$sign$amount — $reason';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'amount': amount,
        'reason': reason,
        'type': type.name,
      };

  factory GemTransaction.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String? ?? 'earned';
    final rawAmount = json['amount'];
    final amount = rawAmount is int
        ? rawAmount
        : rawAmount is num
            ? rawAmount.round()
            : int.tryParse('$rawAmount') ?? 0;
    return GemTransaction(
      id: json['id'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      amount: amount,
      reason: json['reason'] as String? ?? '',
      type: typeName == 'spent'
          ? GemTransactionType.spent
          : GemTransactionType.earned,
    );
  }
}
