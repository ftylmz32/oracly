/// OR-1100 — Tarot deck model.
library;

class DeckModel {
  const DeckModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageAsset,
    required this.isPremium,
    this.cardCount = 78,
  });

  final String id;
  final String name;
  final String description;
  final String imageAsset;
  final bool isPremium;
  final int cardCount;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'imageAsset': imageAsset,
        'isPremium': isPremium,
        'cardCount': cardCount,
      };

  factory DeckModel.fromJson(Map<String, dynamic> json) => DeckModel(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        imageAsset: json['imageAsset'] as String? ?? '',
        isPremium: json['isPremium'] as bool? ?? false,
        cardCount: json['cardCount'] as int? ?? 78,
      );
}
