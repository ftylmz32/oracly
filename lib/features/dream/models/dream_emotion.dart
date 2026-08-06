/// SPRINT-001 — Dream emotion taxonomy.
library;

enum DreamEmotionId {
  peaceful('Huzurlu'),
  anxious('Kaygılı'),
  curious('Meraklı'),
  fearful('Korkulu'),
  joyful('Neşeli'),
  melancholic('Hüzünlü'),
  surreal('Garip'),
  vivid('Canlı');

  const DreamEmotionId(this.labelTr);
  final String labelTr;
}

class DreamEmotion {
  const DreamEmotion({
    required this.id,
    this.intensity = 0.7,
  });

  final DreamEmotionId id;
  final double intensity;

  String get label => id.labelTr;

  Map<String, dynamic> toJson() => {
        'id': id.name,
        'intensity': intensity,
      };

  factory DreamEmotion.fromJson(Map<String, dynamic> json) {
    return DreamEmotion(
      id: DreamEmotionId.values.byName(json['id'] as String),
      intensity: (json['intensity'] as num?)?.toDouble() ?? 0.7,
    );
  }
}
