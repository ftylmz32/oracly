/// One theme recently shown on a personalization surface.
library;

class SurfacedThemeRecord {
  const SurfacedThemeRecord({
    required this.theme,
    required this.surface,
    required this.at,
    this.conceptKey,
  });

  final String theme;
  final String surface;
  final DateTime at;
  final String? conceptKey;

  Map<String, dynamic> toJson() => {
        'theme': theme,
        'surface': surface,
        'at': at.toIso8601String(),
        if (conceptKey != null) 'conceptKey': conceptKey,
      };

  factory SurfacedThemeRecord.fromJson(Map<String, dynamic> json) {
    return SurfacedThemeRecord(
      theme: '${json['theme'] ?? ''}',
      surface: '${json['surface'] ?? ''}',
      at: DateTime.tryParse('${json['at'] ?? ''}') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      conceptKey: json['conceptKey'] as String?,
    );
  }
}
