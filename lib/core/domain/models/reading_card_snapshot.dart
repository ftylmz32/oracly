/// Persisted card face within a saved tarot reading.
library;

class ReadingCardSnapshot {
  const ReadingCardSnapshot({
    required this.cardId,
    required this.cardName,
    required this.cardImageAsset,
    required this.positionIndex,
    this.positionLabel,
    this.positionKey,
    this.isReversed = false,
  });

  final int cardId;
  final String cardName;
  final String cardImageAsset;
  final int positionIndex;
  final String? positionLabel;
  final String? positionKey;
  final bool isReversed;

  Map<String, dynamic> toJson() => {
        'cardId': cardId,
        'cardName': cardName,
        'cardImageAsset': cardImageAsset,
        'positionIndex': positionIndex,
        'positionLabel': positionLabel,
        if (positionKey != null) 'positionKey': positionKey,
        'isReversed': isReversed,
      };

  factory ReadingCardSnapshot.fromJson(Map<String, dynamic> json) {
    return ReadingCardSnapshot(
      cardId: json['cardId'] as int? ?? 0,
      cardName: json['cardName'] as String? ?? '',
      cardImageAsset: json['cardImageAsset'] as String? ?? '',
      positionIndex: json['positionIndex'] as int? ?? 0,
      positionLabel: json['positionLabel'] as String?,
      positionKey: json['positionKey'] as String?,
      isReversed: json['isReversed'] as bool? ?? false,
    );
  }
}
